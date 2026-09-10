import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

const _blue = Color(0xFF4F8BFF);
const _textHi = Color(0xFFF5F6FA);
const _textMid = Color(0x9EFFFFFF);
const _textLo = Color(0x6BFFFFFF);
const _glassFill = Color(0x12FFFFFF);
const _glassFillStrong = Color(0x1FFFFFFF);
const _glassBorder = Color(0x24FFFFFF);

class NewMessageScreen extends ConsumerWidget {
  const NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myShortIdAsync = ref.watch(currentChatUserShortIdProvider);

    final currentFocusId = myShortIdAsync.value ?? '';

    return _NewMessageView(
      focusId: currentFocusId,
      onStartConversation: (recipientId) async {
        final currentFbUid = await ref.read(firebaseChatUidProvider.future);
        if (currentFbUid == null) {
          throw Exception('Chat authentication not ready. Please wait.');
        }

        final targetInfo = await ChatService.lookupUserByChatId(recipientId);
        if (targetInfo == null || targetInfo['uid'] == null) {
          throw Exception('No user found with Focus ID #$recipientId.');
        }

        final targetUid = targetInfo['uid'] as String;
        if (targetUid == currentFbUid) {
          throw Exception('You cannot start a conversation with yourself.');
        }

        final convId = await ChatService.getOrCreateConversation(
          currentFbUid,
          targetUid,
        );

        if (context.mounted) {
          context.pushReplacement('/messages/chat/$convId', extra: {
            'otherChatId': recipientId,
            'otherDisplayName': targetInfo['displayName'] as String? ?? '',
          });
        }
      },
    );
  }
}

class _NewMessageView extends StatefulWidget {
  final String focusId;

  /// Call this with the validated Focus ID when the user
  /// presses "Start Conversation".
  final Future<void> Function(String recipientFocusId)?
      onStartConversation;

  const _NewMessageView({
    required this.focusId,
    this.onStartConversation,
  });

  @override
  State<_NewMessageView> createState() => _NewMessageViewState();
}

class _NewMessageViewState extends State<_NewMessageView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;

  bool _copied = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _copyId() async {
    // Copy the raw 5-character ID without the # prefix
    await Clipboard.setData(
      ClipboardData(text: widget.focusId.toUpperCase()),
    );

    if (!mounted) return;

    setState(() => _copied = true);

    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    setState(() => _copied = false);
  }

  Future<void> _startConversation() async {
    final id = _controller.text.trim().toUpperCase().replaceAll('#', '');

    if (id.length != 5) {
      _showError('Enter a valid 5-character Focus ID.');
      return;
    }

    if (widget.focusId.isNotEmpty && id == widget.focusId.toUpperCase()) {
      _showError('You cannot start a conversation with yourself.');
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);

    try {
      if (widget.onStartConversation != null) {
        await widget.onStartConversation!(id);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        _showError(errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF24242A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final horizontalPadding = size.width < 380 ? 14.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF08090D),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: _Background(),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                      maxWidth: 520,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Navigation Bar with Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(LucideIcons.arrowLeft, color: _textHi),
                              onPressed: () => context.pop(),
                              splashRadius: 20,
                            ),
                          ),

                          const SizedBox(height: 8),

                          _AnimatedEntry(
                            controller: _animationController,
                            interval: const Interval(
                              0.0,
                              0.65,
                              curve: Curves.easeOutCubic,
                            ),
                            child: _RecipientPanel(
                              controller: _controller,
                              focusNode: _focusNode,
                              loading: _loading,
                              onSubmit: _startConversation,
                            ),
                          ),

                          const SizedBox(height: 18),

                          _AnimatedEntry(
                            controller: _animationController,
                            interval: const Interval(
                              0.15,
                              0.85,
                              curve: Curves.easeOutCubic,
                            ),
                            child: _OwnFocusIdPanel(
                              focusId: widget.focusId,
                              copied: _copied,
                              onCopy: _copyId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B0D16),
                Color(0xFF05060B),
                Color(0xFF0A0710),
              ],
            ),
          ),
        ),

        const _Orb(
          top: -110,
          left: -100,
          size: 340,
          color: Color(0xFF6AA8FF),
        ),

        const _Orb(
          bottom: -90,
          right: -80,
          size: 300,
          color: Color(0xFF9A70FF),
        ),

        const _Orb(
          bottom: 130,
          left: 10,
          size: 230,
          color: Color(0x8857E0FF),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const _Orb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.45),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipientPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;

  const _RecipientPanel({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            text: 'Recipient Focus ID',
            large: true,
          ),

          const SizedBox(height: 16),

          _InsetField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onSubmit(),
          ),

          const SizedBox(height: 13),

          const Center(
            child: Text(
              'Enter the 5-character ID shared with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMid,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _PrimaryButton(
            loading: loading,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _OwnFocusIdPanel extends StatelessWidget {
  final String focusId;
  final bool copied;
  final VoidCallback onCopy;

  const _OwnFocusIdPanel({
    required this.focusId,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final displayId = focusId.isNotEmpty ? focusId.toUpperCase() : '···';

    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  text: 'YOUR FOCUS ID',
                  large: false,
                ),

                const SizedBox(height: 10),

                Text(
                  '#$displayId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textHi,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          _CopyButton(
            copied: copied,
            onTap: onCopy,
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      26,
      27,
      26,
      27,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: _glassFill,
            border: Border.all(
              color: _glassBorder,
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.095),
                Colors.white.withValues(alpha: 0.015),
              ],
              stops: const [
                0,
                0.45,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool large;

  const _SectionHeader({
    required this.text,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '#',
          style: TextStyle(
            color: large ? _blue : _textMid,
            fontSize: large ? 18 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          text,
          style: TextStyle(
            color: large ? _textHi : _textMid,
            fontSize: large ? 16 : 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: large ? -0.1 : 1.2,
          ),
        ),
      ],
    );
  }
}

class _InsetField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onSubmitted;

  const _InsetField({
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6,
          sigmaY: 6,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.11),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            maxLength: 5,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmitted,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9]'),
              ),
              UpperCaseTextFormatter(),
            ],
            style: const TextStyle(
              color: _textHi,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: 'e.g. 6TXPK',
              hintStyle: TextStyle(
                color: _textLo,
                letterSpacing: 0.8,
              ),
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.loading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.loading ? null : widget.onTap,
          onTapDown: (_) {
            if (!widget.loading) {
              setState(() => _pressed = true);
            }
          },
          onTapCancel: () {
            if (mounted) {
              setState(() => _pressed = false);
            }
          },
          onTapUp: (_) {
            if (mounted) {
              setState(() => _pressed = false);
            }
          },
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5D98FF),
                  Color(0xFF3E82F5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: widget.loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Conversation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final bool copied;
  final VoidCallback onTap;

  const _CopyButton({
    required this.copied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 9,
          sigmaY: 9,
        ),
        child: Material(
          color: copied
              ? const Color(0x405AE08C)
              : _glassFillStrong,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: copied
                      ? const Color(0xFF78F0A0)
                          .withValues(alpha: 0.4)
                      : _glassBorder,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey(copied),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      copied
                          ? Icons.check_rounded
                          : Icons.copy_rounded,
                      size: 16,
                      color: _textHi,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      copied ? 'Copied' : 'Copy',
                      style: const TextStyle(
                        color: _textHi,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - value),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
