import 'package:flutter/material.dart';
import 'package:mira_hackaton_2025/services/mcp_client.dart';
import 'TTSService.dart';
import 'services/mira_ws_client.dart';
//import 'myVideoCard.dart';



import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


/*
void main() {
  runApp(const MiraApp());
}

 */

class Mira extends StatelessWidget {
  const Mira({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mira AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const MiraScreen(),
    );
  }
}

class MiraScreen extends StatefulWidget {
  const MiraScreen({super.key});

  @override
  State<MiraScreen> createState() => _MiraScreenState();
}

class _MiraScreenState extends State<MiraScreen> with TickerProviderStateMixin {
  final MCPClient mcp = MCPClient(baseUrl: "http://104.155.99.100:5055");
  String _resultText = "Kérés folyamatban...";

  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late MiraWebSocketClient _wsClient;

  //final SpeechToText sttService = SpeechToText();

  final tts = TTSService();
  String botMessage = '  Üdvözlöm nálunk.';
  //final VideoCardController _controller = VideoCardController();

  bool isSpeaking = false;

  late stt.SpeechToText _speech;
  String _recognizedText = "";


  List<String> ember_szovegek = [
    'We’d like to find a budget-friendly family ski trip for this weekend.',
    'Two adults and two children.'
    'Heiligenblut.',
    'Heiligenblut.',
    'Heiligenblut.',
    'Heiligenblut.',
    'Heiligenblut.',
    'Heiligenblut.',
  ];
  List<String> ai_szovegek = [
    'Great — thanks for the info! Just a couple of quick questions so I can find the best family ski‑weekend for you: how many people (adults & children)?',
    'Thanks for the additional details — that’s really helpful! So we’re looking at 2 adults + 2 children for a family ski weekend. What town or region are you interested?',
    'Great — choosing Heiligenblut is a lovely idea!. Here are some great options for you:',
    'Great — choosing Heiligenblut is a lovely idea!. Here are some great options for you:',
    'Great — choosing Heiligenblut is a lovely idea!. Here are some great options for you:',
    'Great — choosing Heiligenblut is a lovely idea!. Here are some great options for you:',
    'Great — choosing Heiligenblut is a lovely idea!. Here are some great options for you:',
  ];


  int inmost = 0;

  List<String> _chatMessages = [];
  List<int> MessagesIdentity = [
  ];


  void _addAssistantMessage(String text) {
    setState(() {
      _chatMessages.add(text);
      MessagesIdentity.add(0);
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _chatMessages.add(text);
      MessagesIdentity.add(1);
    });
  }

  void _addChatMessage(String message) {
    setState(() {
      _chatMessages.add(message);
    });
  }



  Future<void> _loadDemoData() async {
    try {
      final attractions = await mcp.getTopAttractions("Vienna", limit: 3);

      if (attractions.isEmpty) {
        setState(() {
          _resultText = "Nincs találat Bécsre.";
        });
      } else {
        final names = attractions.map((a) => a['name']).join("\n• ");
        setState(() {
          _resultText = "🎯 Top látnivalók Bécsben:\n• $names";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "⚠️ Hiba történt: $e";
      });
    }
  }


  @override
  void initState() {
    _loadDemoData();


    /*
    // MCP-teszt: induláskor lefut, és kiírja az eredményt vagy hibát
    Future.delayed(const Duration(seconds: 1), () async {
      print("🔍 MCP teszt indul...");

      try {
        final result = await mcp.getTopAttractions("Vienna", limit: 3);
        print("✅ MCP válasz: $result");

        if (result.isEmpty) {
          setState(() {
            _resultText = "⚠️ Nincs találat Bécsre (MCP válasz üres).";
          });
        } else {
          setState(() {
            final names = result.map((a) => a['name']).join("\n• ");
            _resultText = "🎯 MCP működik!\nTop látnivalók Bécsben:\n• $names";
            _addAssistantMessage(_resultText);
          });
        }
      } catch (e) {
        print("❌ MCP hiba: $e");
        setState(() {
          _resultText = "❌ MCP hiba: $e";
          _addAssistantMessage(_resultText);
        });
      }
    });

     */




    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    super.initState();

    tts.connect(
          (partialText) {
        setState(() {
          botMessage += partialText;
        });
        // Ha meg szeretnéd jeleníteni a chatben:
        setState(() {
          //_addAssistantMessage(partialText);
        });

      },
          () {
        //_controller.changeVideo(0);
      },
    );

    // Küldjünk egy teszt üzenetet, hogy lássuk, működik-e
    Future.delayed(const Duration(seconds: 1), () {
      tts.speak("Hi there! I’m Mira, your local travel assistant. What kind of experience are you looking for? Cultural, active, or mainstream events?", mode: "tts"
          ,onStart: () {
        setState(() {
          isSpeaking = true;
          print(true);
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          //_controller.changeVideo(0);
        });
      },
        onComplete: () {
        setState(() {
          isSpeaking = false;
          print("false");
          //_controller.changeVideo(1);
          //_startListening();
        });
      },);
      _chatMessages.add('Hi there! I’m Mira, your local travel assistant. What kind of experience are you looking for? Cultural, active, or mainstream events?',);
      MessagesIdentity.add(0);
    });

  }


  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          _speech.stop();
          // ha szeretnéd, itt lehet automatikusan válaszoltatni
          _handleRecognizedText();
        }
      },
      onError: (errorNotification) {
        debugPrint('Speech error: $errorNotification');
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = "";
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US', // vagy 'hu_HU' ha magyarul beszél
      );
    } else {
      debugPrint("Speech recognition not available");
    }
  }


  void _handleRecognizedText() {
    if (_recognizedText.isNotEmpty) {
      _addUserMessage(_recognizedText);

      /*
      // itt küldheted tovább a recognized textet a Mira logikába:
      tts.speak("You said: $_recognizedText", mode: "tts",
          onStart: () => setState(() => isSpeaking = true),
          onComplete: () => setState(() => isSpeaking = false));

       */

    }
  }



  @override
  void dispose() {
    _wsClient.disconnect();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {

    /*
    if (_isListening) {
      _speech.stop();
      //setState(() => _isListening = false);
    } else {
      _startListening();
    }

     */

    setState(() {
      _isListening = !_isListening;

      if(!_isListening){
        Future.delayed(const Duration(seconds: 1), () {
          //_addUserMessage(_recognizedText);

          tts.speak(ai_szovegek[inmost], mode: "tts"
            //tts.speak(_recognizedText, mode: "speak"
            ,onStart: () {
              _addUserMessage(ember_szovegek[inmost]);
              _addAssistantMessage(ai_szovegek[inmost]);
              setState(() {
                isSpeaking = true;
              });
              /*
              Future.delayed(const Duration(milliseconds: 800), () {
                //_controller.changeVideo(0);
              });

               */
            },
            onComplete: () {
              setState(() {
                isSpeaking = false;
                  //_controller.changeVideo(1);
                //_startListening();

                setState(() {
                  inmost=inmost+1;
                });
                print(inmost);

              });
            },);



        });


      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildHeader(),
            Expanded(
              child: _buildChatList(),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isListening ? const Color(0xFF10B981) : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: _isListening
                  ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isListening ? 'Mira is listening...' : 'Mira is ready',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                      )
                    ],
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF3F4F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  /*child: Center(
                    child: ClipOval(  // vagy CircleAvatar, ha szeretnéd
                      child: Image.asset(
                        'assets/images/im.jpeg',  // cseréld le a saját asset útvonaladra
                        width: 106,
                        height: 106,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                   */

                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child:  isSpeaking? _VideoAvatar() : _VideoAvatar2(),
                    ),
                  ),




                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, I\'m Mira!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your AI travel experience guide',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAssistantMessage(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 80, top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }

  Widget _buildUserMessage(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 80, right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }


  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        if (MessagesIdentity[index] == 0) {
          return _buildAssistantMessage(message);
        } else {
          return _buildUserMessage(message);
        }
      },
    );
  }

  /*
  Widget _buildChatList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [


        _buildAssistantMessage(
          'Hello! I\'m here to help you discover amazing experiences. What kind of adventure are you looking for today?',
        ),
        const SizedBox(height: 16),
        _buildUserMessage(
          'I\'d like to book a wine tasting in Carinthia next weekend.',
        ),


        const SizedBox(height: 16),
        _buildAssistantMessageWithCard(),
        const SizedBox(height: 16),
        if (_isProcessing) _buildTypingIndicator(),
      ],
    );
  }
*/

/*
  Widget _buildAssistantMessage(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(isAssistant: true),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2937),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildAvatar(isAssistant: false),
      ],
    );
  }

 */

  Widget _buildAssistantMessageWithCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(isAssistant: true),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect! I found three amazing wine tasting experiences available near Lake Wörthersee:',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExperienceCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🍷 Vineyard Sunset Experience',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '€45 per person • 3 hours • Includes 6 wine tastings',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Available: Saturday 2 PM & Sunday 4 PM',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(isAssistant: true, isAnimated: true),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 8),
              _buildDot(1),
              const SizedBox(width: 8),
              _buildDot(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF9CA3AF),
              const Color(0xFF6366F1),
              (value + index * 0.3) % 1.0,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildAvatar({required bool isAssistant, bool isAnimated = false}) {
    if (isAssistant) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isAnimated
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(
            Icons.psychology_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.person_rounded,
            color: Color(0xFF6B7280),
            size: 22,
          ),
        ),
      );
    }
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(
            icon: Icons.keyboard_rounded,
            onTap: () {
              // Handle keyboard input
            },
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      offset: const Offset(0, 8),
                    )
                  ],
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    if (_isListening)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildControlButton(
            icon: Icons.volume_up_rounded,
            onTap: () {
              // Handle audio playback
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 24,
          ),
        ),
      ),
    );
  }
}









class _VideoAvatar extends StatefulWidget {
  @override
  State<_VideoAvatar> createState() => _VideoAvatarState();
}

class _VideoAvatarState extends State<_VideoAvatar> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/assistant.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play(); // automatikusan elindítja
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}




class _VideoAvatar2 extends StatefulWidget {
  @override
  State<_VideoAvatar2> createState() => _VideoAvatarState2();
}

class _VideoAvatarState2 extends State<_VideoAvatar2> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/hallgat.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play(); // automatikusan elindítja
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}















