import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasKey = false;
  bool _isGenerating = false;

  final List<Content> _history = [];
  final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiService.instance.hasKey();
    setState(() {
      _hasKey = hasKey;
      _isLoading = false;
      if (_messages.isEmpty) {
        _messages.add(_Msg(
          text: "Hi! I'm FamFunds AI, your personal finance assistant. Ask me anything about budgeting, saving money, expense tracking, financial planning, investments, insurance, taxes, banking, or financial literacy.",
          isUser: false,
        ));
      }
    });
  }

  void _send([String? customText]) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      final responseText = await GeminiService.instance.sendMessage(text, _history);
      
      setState(() {
        _messages.add(_Msg(text: responseText, isUser: false));
        if (_hasKey) {
          _history.add(Content('user', [TextPart(text)]));
          _history.add(Content('model', [TextPart(responseText)]));
        }
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Msg(
          text: "Sorry, I ran into an error: ${e.toString()}.\n\nPlease check your API key and connection.",
          isUser: false,
          isError: true,
        ));
        _isGenerating = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FamFunds AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_isGenerating ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _TypingBubble();
                }
                return _Bubble(msg: _messages[i]);
              },
            ),
          ),
          if (_messages.length == 1 && !_isGenerating) ...[
            _SuggestionRow(onSelect: (text) => _send(text)),
            const SizedBox(height: AppSpacing.sm),
          ],
          _Composer(
            controller: _controller,
            onSend: () => _send(),
            isGenerating: _isGenerating,
          ),
        ],
      ),
    );
  }
}

// API Connection Banner removed to conform to FamFunds AI requirements

class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  _Msg({required this.text, required this.isUser, this.isError = false});
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final align = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = msg.isUser
        ? AppColors.primary
        : (msg.isError ? AppColors.accentRed.withOpacity(0.08) : AppColors.surface);
    final borderColor = msg.isUser
        ? Colors.transparent
        : (msg.isError ? AppColors.accentRed : AppColors.border);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              Container(
                margin: const EdgeInsets.only(right: 10, top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: msg.isError ? AppColors.accentRed.withOpacity(0.1) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  msg.isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                  size: 16,
                  color: msg.isError ? AppColors.accentRed : AppColors.primary,
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                  ),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    if (!msg.isUser)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: _buildRichText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(BuildContext context) {
    final textColor = msg.isUser
        ? Colors.white
        : (msg.isError ? AppColors.accentRed : AppColors.textPrimary);
    final style = TextStyle(color: textColor, height: 1.45, fontSize: 14);

    final parts = msg.text.split('**');
    if (parts.length <= 1) {
      return SelectableText(msg.text, style: style);
    }

    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: style,
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: const _TypingIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

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
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final animValue = ((_controller.value - delay) % 1.0);
            final opacity = (animValue < 0.5)
                ? (animValue * 2)
                : (1.0 - (animValue - 0.5) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(opacity.clamp(0.15, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final Function(String) onSelect;
  const _SuggestionRow({required this.onSelect});

  static const _suggestions = [
    'How is our savings rate?',
    'Should we increase our SIP?',
    'What is our total balance?',
    'Compare our loan options',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final text = _suggestions[i];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ActionChip(
              label: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.primaryLight,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () => onSelect(text),
            ),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!isGenerating) onSend();
                },
                decoration: const InputDecoration(
                  hintText: 'Ask about savings, loans, investing…',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: isGenerating ? null : onSend,
              icon: isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
