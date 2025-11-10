import 'dart:collection'; // Queue használatához
import 'dart:convert';
//import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

enum TtsState { playing, stopped, paused, continued }

class TTSService {
  final AudioPlayer _player = AudioPlayer();
  TtsState ttsState = TtsState.stopped;

  late WebSocketChannel _channel;
  bool _isConnected = false;

  // Queue a beérkező üzenetekhez
  final Queue<Uint8List> _audioQueue = Queue<Uint8List>();
  bool _isPlaying = false;


  void connect(
      Function(String)? onPartialText,
      Function()? onAudioStart, // <-- EZ AZ ÚJ PARAMÉTER
      ) {
    if (_isConnected) {
      debugPrint("WebSocket already connected.");
      return;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse('wss://hotel-receptionist-voicebot-443897688015.us-central1.run.app'),
    );
    _isConnected = true;

    _channel.stream.listen(
          (message) async {
        try {
          if (message is String) {
            final data = jsonDecode(message);

            if (data['type'] == 'chunk' || data['type'] == 'speak') {
              final partialText = data['text'];
              final audioBase64 = data['audio'];

              print(partialText);

              // szöveg streamelve
              onPartialText?.call(partialText);

              // audió dekódolása
              final audioBytes = base64Decode(audioBase64);
              _audioQueue.add(audioBytes);

              // Itt hívjuk meg az új függvényt
              onAudioStart?.call(); // <-- HÍVÁS ITT

              if (!_isPlaying) {
                _playNext();
              }
            } else if (data['status'] == 'error') {
              debugPrint("Szerver hiba: ${data['message']}");
            }
          } else if (message is List<int>) {
            final audioData = Uint8List.fromList(message);

            // Beletesszük a sorba
            _audioQueue.add(audioData);

            // Itt is meghívjuk az új függvényt
            onAudioStart?.call(); // <-- ÉS HÍVÁS ITT IS

            // Ha nem játszik épp, akkor elindítjuk a feldolgozást
            if (!_isPlaying) {
              _playNext();
            }
          }
        } catch (e) {
          debugPrint("Hiba a WebSocket üzenet feldolgozásakor: $e");
        }
      },
      onError: (error) {
        debugPrint("WebSocket hiba: $error");
        _isConnected = false;
      },
      onDone: () {
        debugPrint("WebSocket kapcsolat lezárva");
        _isConnected = false;
      },
    );
  }

  Future<void> _playNext() async {
    if (_audioQueue.isEmpty) {
      _isPlaying = false;
      ttsState = TtsState.stopped;
      return;
    }

    _isPlaying = true;
    ttsState = TtsState.playing;

    final audioData = _audioQueue.removeFirst();
    final url = "data:audio/mpeg;base64,${base64Encode(audioData)}";

    await _player.play(UrlSource(url));
    await _player.onPlayerComplete.first;

    // Ha befejezte, próbáljuk a következőt
    _playNext();
  }



  Future<void> speak(
      String text, {
        String mode = "speak",
        Function()? onStart,
        Function()? onComplete,
      }) async {
    if (!_isConnected) {
      debugPrint("WebSocket not connected. Please call connect() first.");
      return;
    }

    final action = mode == "tts" ? "speak" : "start_chat";
    _channel.sink.add(jsonEncode({
      "action": action,
      "payload": {"text": text},
    }));

    if (onStart != null) onStart();

    // A onComplete-et meghívjuk, ha az egész queue kiürült
    _player.onPlayerComplete.listen((_) {
      if (_audioQueue.isEmpty) {
        if (onComplete != null) onComplete();
      }
    });
  }
/*
  Future<void> speak(
      String text, {
        String mode = "speak",
        Function()? onStart,
        Function()? onComplete,
      }) async {
    if (!_isConnected) {
      debugPrint("WebSocket not connected. Please call connect() first.");
      return;
    }

    // előző lejátszás leállítása
    await stop();

    final action = mode == "tts" ? "speak" : "start_chat";
    _channel.sink.add(jsonEncode({
      "action": action,
      "payload": {"text": text},
    }));

    print("audio mehet");
    if (onStart != null) onStart();

    // várd meg amíg teljesen kiürül a queue
    unawaited(() async {
      while (_isPlaying || _audioQueue.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (onComplete != null) onComplete(); // <-- csak itt hívjuk
      print("KESZAZAUDIO");
    }());
  }

 */




  Future<void> stop() async {
    await _player.stop();
    ttsState = TtsState.stopped;
    _audioQueue.clear();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _player.pause();
    ttsState = TtsState.paused;
  }

  void dispose() {
    _player.dispose();
    _channel.sink.close();
    _isConnected = false;
    _audioQueue.clear();
    _isPlaying = false;
  }
}




