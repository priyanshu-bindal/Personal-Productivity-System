import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessageComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool isSending;

  const MessageComposer({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() => _canSend = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;

    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            bottomInset > 0 ? 10 : (bottomPadding > 0 ? bottomPadding + 6 : 12),
          ),
          decoration: const BoxDecoration(
            color: Color(0xF21D1D21), // rgba(29, 29, 33, 0.95)
            border: Border(
              top: BorderSide(color: Color(0xFF282830), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF282830),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Color(0xFFF1F1F3),
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Write a message…',
                      hintStyle: TextStyle(
                        color: Color(0xFF70707A),
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedScale(
                scale: _canSend ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _canSend && !widget.isSending ? _handleSend : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5B8C),
                      disabledBackgroundColor: const Color(0x2B3B5B8C),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: widget.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.send,
                            size: 17,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
