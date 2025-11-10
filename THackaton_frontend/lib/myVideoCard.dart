// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCardController {
  VideoCardState? state;

  void changeVideo(int index) {
    state?.changeVideo(index);
  }
}

class VideoCard extends StatefulWidget {
  final List<String> videoSources;
  final VideoCardController? controller;

  const VideoCard({
    Key? key,
    required this.videoSources,
    this.controller,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  late VideoPlayerController controller;
  int currentVideoIndex = 1;
  bool isChangingVideo = false;
  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.state = this; // A vezérlő összekapcsolása
    }
    initializeVideoPlayer();
  }

  Future<void> initializeVideoPlayer() async {
    try {
      controller = VideoPlayerController.asset(widget.videoSources[currentVideoIndex]);

      // Hibakezelés
      controller.addListener(() {
        final error = controller.value.errorDescription;
        if (error != null && error.isNotEmpty && !hasError) {
          setState(() {
            hasError = true;
            errorMessage = error;
          });
          print("Video player error: $error");
        }
      });

      await controller.initialize();
      if (mounted) {
        setState(() {});
        controller.play();
        controller.setLooping(true);
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
      print("Error initializing video player: $e");
    }
  }

  Future<void> changeVideo(int index) async {
    print("change video to index: $index");
    print(index);
    print(widget.videoSources.length);
    print( (index == currentVideoIndex).toString() +" "+ (index >= widget.videoSources.length).toString() );
    if (index == currentVideoIndex || index >= widget.videoSources.length) return;

    setState(() {
      isChangingVideo = true;
      hasError = false;
    });

    try {
      final oldController = controller;
      currentVideoIndex = index;

      controller = VideoPlayerController.asset(widget.videoSources[currentVideoIndex]);
      print(widget.videoSources[currentVideoIndex]);
      // Hibakezelés
      controller.addListener(() {
        final error = controller.value.errorDescription;
        if (error != null && error.isNotEmpty && !hasError) {
          setState(() {
            hasError = true;
            errorMessage = error;
          });
          print("Video player error: $error");
        }
      });

      await controller.initialize();
      await oldController.dispose();

      if (mounted) {
        setState(() {
          isChangingVideo = false;
        });
        controller.play();
        controller.setLooping(true);
      }
    } catch (e) {
      setState(() {
        isChangingVideo = false;
        hasError = true;
        errorMessage = e.toString();
      });
      print("Error changing video: $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.controller != null) {
      widget.controller!.state = null; // Tisztítás
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 280,
        child: hasError
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              Text("Video Error:"),
              Text(errorMessage, textAlign: TextAlign.center),
            ],
          ),
        )
            : (controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        )
            : const Center(child: CircularProgressIndicator())),
      ),
    );
  }
}