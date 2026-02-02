import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmbededLandingScreen extends StatelessWidget {
  const EmbededLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _FakeChatBackground(),
        _EmbedLoginOverlay(
          currentUri: GoRouterState.of(context).uri.toString(),
        ),
      ],
    );
  }
}

// =============================================================================
// FAKE CHAT BACKGROUND - Realistic chat interface
// =============================================================================
class _FakeChatBackground extends StatefulWidget {
  const _FakeChatBackground();

  @override
  State<_FakeChatBackground> createState() => _FakeChatBackgroundState();
}

class _FakeChatBackgroundState extends State<_FakeChatBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // App Bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Messages
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _FakeMessageBubble(
                  isMe: false,
                  text: 'Hey! How can I help you today?',
                ),
                SizedBox(height: 12),
                _FakeMessageBubble(isMe: true, text: 'Hi! I have a question'),
                SizedBox(height: 12),
                _FakeMessageBubble(
                  isMe: false,
                  text: 'Sure, feel free to ask anything!',
                ),
                SizedBox(height: 12),
                _FakeMessageBubble(
                  isMe: true,
                  text: 'Thanks! I really appreciate it',
                ),
                SizedBox(height: 12),
                _TypingIndicator(),
              ],
            ),
          ),
        ),

        // Input Bar
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Type a message...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.send_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// FAKE MESSAGE BUBBLE - Realistic chat bubble
// =============================================================================
class _FakeMessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;

  const _FakeMessageBubble({required this.isMe, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primaryContainer.withValues(alpha: 0.7)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TYPING INDICATOR - Animated dots
// =============================================================================
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = (_controller.value - delay) % 1.0;
                final scale = value < 0.5
                    ? 1.0 + (value * 0.6)
                    : 1.3 - ((value - 0.5) * 0.6);

                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// =============================================================================
// EMBED LOGIN OVERLAY - Modern login section with gradient
// =============================================================================
class _EmbedLoginOverlay extends StatelessWidget {
  final String currentUri;

  const _EmbedLoginOverlay({required this.currentUri});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in desktop or mobile layout
        final isDesktop = constraints.maxWidth > 600;

        return Stack(
          children: [
            // Blur overlay
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            // Login section with gradient
            if (isDesktop)
              _DesktopLoginSection(currentUri: currentUri)
            else
              _MobileLoginSection(currentUri: currentUri),
          ],
        );
      },
    );
  }
}

// =============================================================================
// DESKTOP LOGIN SECTION - Horizontal gradient from left (full height)
// =============================================================================
class _DesktopLoginSection extends StatefulWidget {
  final String currentUri;

  const _DesktopLoginSection({required this.currentUri});

  @override
  State<_DesktopLoginSection> createState() => _DesktopLoginSectionState();
}

class _DesktopLoginSectionState extends State<_DesktopLoginSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.0),
                colorScheme.surface.withValues(alpha: 0.5),
                colorScheme.surface.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.2, 0.6],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _LoginContent(currentUri: widget.currentUri),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MOBILE LOGIN SECTION - Vertical gradient from top (full width)
// =============================================================================
class _MobileLoginSection extends StatefulWidget {
  final String currentUri;

  const _MobileLoginSection({required this.currentUri});

  @override
  State<_MobileLoginSection> createState() => _MobileLoginSectionState();
}

class _MobileLoginSectionState extends State<_MobileLoginSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withValues(alpha: 0.0),
                colorScheme.surface.withValues(alpha: 0.5),
                colorScheme.surface.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.2, 0.6],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _LoginContent(currentUri: widget.currentUri),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LOGIN CONTENT - Main login content (no card wrapper)
// =============================================================================
class _LoginContent extends StatelessWidget {
  final String currentUri;

  const _LoginContent({required this.currentUri});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          'Welcome to Talkest',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Subtitle
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Sign in with Google to start chatting and connect with others.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        // Sign in button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              final redirectUrl = Uri.encodeComponent(currentUri);
              context.goNamed(
                'login',
                queryParameters: {'redirect': redirectUrl},
              );
            },
            icon: const Icon(Icons.login_rounded, size: 22),
            label: const Text('Sign in with Google'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
