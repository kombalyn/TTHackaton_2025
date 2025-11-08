import 'package:flutter/material.dart';
import 'services/mira_ws_client.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late MiraWebSocketClient _wsClient;

  @override
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _wsClient = MiraWebSocketClient(uri: "wss://104.155.99.100:5055");
    _wsClient.connect(onMessage: (msg) {
      print("💬 Szerver válasz: $msg");
      // Itt lehet majd frissíteni a chat UI-t
    });

    // Automatikusan küldjön egy üzenetet, mikor az app elindul
    _wsClient.sendStartMessage("Hello from the Flutter app!");
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
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
                  child: Center(
                    child: Icon(
                      Icons.psychology_rounded,
                      color: const Color(0xFF6366F1),
                      size: 36,
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