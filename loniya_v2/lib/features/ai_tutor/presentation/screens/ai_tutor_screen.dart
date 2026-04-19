import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/tts/tts_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../providers/ai_tutor_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _focus.unfocus();
    ref.read(aiTutorNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiTutorNotifierProvider);
    final aiContext = ref.watch(aiTutorContextProvider);
    final ttsEnabled = ref.watch(ttsEnabledProvider);

    // Auto-scroll whenever messages change
    ref.listen<AiTutorState>(aiTutorNotifierProvider, (prev, next) {
      _scrollToBottom();
      // Speak new AI messages when TTS is enabled
      if (ttsEnabled && next.messages.length > (prev?.messages.length ?? 0)) {
        final last = next.messages.last;
        if (!last.isFromUser) {
          ref.read(ttsServiceProvider).speak(last.content);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AiHeader(
            ttsEnabled: ttsEnabled,
            onClear: () =>
                ref.read(aiTutorNotifierProvider.notifier).clearChat(),
            onToggleTts: () {
              final newValue = !ttsEnabled;
              ref.read(ttsEnabledProvider.notifier).state = newValue;
              ref.read(ttsServiceProvider).setEnabled(newValue);
              if (!newValue) ref.read(ttsServiceProvider).stop();
            },
          ),

          if (aiContext != null)
            _ContextBanner(context: aiContext, ref: ref),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: chatState.messages.length +
                  (chatState.isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == chatState.messages.length) {
                  return const TypingIndicator();
                }
                return ChatBubble(message: chatState.messages[i]);
              },
            ),
          ),

          if (chatState.errorMessage != null)
            _ErrorBanner(message: chatState.errorMessage!),

          _InputBar(
            ctrl:     _ctrl,
            focus:    _focus,
            isTyping: chatState.isTyping,
            onSend:   _send,
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _AiHeader extends StatelessWidget {
  final bool ttsEnabled;
  final VoidCallback onClear;
  final VoidCallback onToggleTts;
  const _AiHeader({
    required this.ttsEnabled,
    required this.onClear,
    required this.onToggleTts,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.aiTutor, AppColors.levelPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LONIYA IA Tuteur', style: AppTextStyles.titleSmall),
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Actif · Mode hors-ligne',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ]),
                ],
              ),
            ),
            // TTS toggle
            IconButton(
              tooltip: ttsEnabled
                  ? 'Désactiver la voix'
                  : 'Activer la lecture vocale',
              icon: Icon(
                ttsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: ttsEnabled ? AppColors.aiTutor : AppColors.grey500,
              ),
              onPressed: onToggleTts,
            ),
            IconButton(
              tooltip: 'Nouvelle conversation',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onClear,
            ),
          ]),
        ),
      ),
    );
  }
}

class _ContextBanner extends StatelessWidget {
  final AiContext context;
  final WidgetRef ref;
  const _ContextBanner({required this.context, required this.ref});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.aiTutor.withOpacity(0.08),
      child: Row(children: [
        const Icon(Icons.link_rounded, size: 16, color: AppColors.aiTutor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Contexte : ${context.subject} — ${context.stepTitle}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.aiTutor),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.close_rounded,
              size: 16, color: AppColors.aiTutor),
          onPressed: () =>
              ref.read(aiTutorContextProvider.notifier).state = null,
        ),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.errorLight,
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.error)),
        ),
      ]),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool isTyping;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.focus,
    required this.isTyping,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.ctrl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.isTyping;
    return Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: widget.ctrl,
                focusNode:  widget.focus,
                enabled:    !widget.isTyping,
                onSubmitted: (_) => widget.onSend(),
                maxLines:    4,
                minLines:    1,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: widget.isTyping
                      ? 'LONIYA réfléchit…'
                      : 'Pose ta question…',
                  filled:    true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'ai_send',
              onPressed: canSend ? widget.onSend : null,
              backgroundColor:
                  canSend ? AppColors.aiTutor : AppColors.grey300,
              elevation: 0,
              child: Icon(
                widget.isTyping
                    ? Icons.hourglass_bottom_rounded
                    : Icons.send_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
