import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/storage/secure_key_service.dart';
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

  Future<void> _showApiKeyDialog() async {
    final currentKey = await ref.read(secureKeyServiceProvider).getApiKey() ?? '';
    if (!mounted) return;

    final ctrl = TextEditingController(text: currentKey);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.aiTutor, AppColors.levelPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Clé API Groq', style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.aiTutor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🔑 Obtiens une clé gratuite sur console.groq.com\n'
                '⚡ Modèle : llama-3.3-70b-versatile\n'
                '📱 Sans clé : mode hors-ligne activé',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Clé Groq (gsk_...)',
                prefixIcon: const Icon(Icons.key_rounded),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(secureKeyServiceProvider).deleteApiKey();
              ref.invalidate(hasApiKeyProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Effacer', style: TextStyle(color: AppColors.error)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.aiTutor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isNotEmpty) {
                await ref.read(secureKeyServiceProvider).saveApiKey(key);
                ref.invalidate(hasApiKeyProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState  = ref.watch(aiTutorNotifierProvider);
    final aiContext  = ref.watch(aiTutorContextProvider);
    final ttsEnabled = ref.watch(ttsEnabledProvider);
    final isOnline   = ref.watch(isOnlineProvider).valueOrNull
        ?? ref.read(connectivityServiceProvider).isConnected;
    final hasKey     = ref.watch(hasApiKeyProvider).valueOrNull ?? false;

    // Auto-scroll + TTS
    ref.listen<AiTutorState>(aiTutorNotifierProvider, (prev, next) {
      _scrollToBottom();
      if (ttsEnabled && next.messages.length > (prev?.messages.length ?? 0)) {
        final last = next.messages.last;
        if (!last.isUser) {
          ref.read(ttsServiceProvider).speak(last.content);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AiHeader(
            isOnline:    isOnline,
            hasKey:      hasKey,
            ttsEnabled:  ttsEnabled,
            onClear:     () => ref.read(aiTutorNotifierProvider.notifier).clearChat(),
            onToggleTts: () {
              final v = !ttsEnabled;
              ref.read(ttsEnabledProvider.notifier).state = v;
              ref.read(ttsServiceProvider).setEnabled(v);
              if (!v) ref.read(ttsServiceProvider).stop();
            },
            onSetupKey: _showApiKeyDialog,
          ),

          // Setup banner — shown when offline and no key configured
          if (!hasKey)
            _SetupBanner(onTap: _showApiKeyDialog),

          if (aiContext != null)
            _ContextBanner(context: aiContext, ref: ref),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == chatState.messages.length) return const TypingIndicator();
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
  final bool isOnline, hasKey, ttsEnabled;
  final VoidCallback onClear, onToggleTts, onSetupKey;

  const _AiHeader({
    required this.isOnline,
    required this.hasKey,
    required this.ttsEnabled,
    required this.onClear,
    required this.onToggleTts,
    required this.onSetupKey,
  });

  @override
  Widget build(BuildContext context) {
    final llmActive = isOnline && hasKey;
    final statusColor = llmActive ? AppColors.success
        : isOnline ? AppColors.warning
        : AppColors.grey400;
    final statusLabel = llmActive  ? 'En ligne · Groq LLM'
        : isOnline ? 'En ligne · clé manquante'
        : 'Hors-ligne · Mode local';

    return Material(
      color: AppColors.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.aiTutor, AppColors.levelPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  llmActive ? '🤖' : '📱',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Le Sage', style: AppTextStyles.titleSmall),
                  Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(statusLabel,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ]),
                ],
              ),
            ),
            // API key setup
            IconButton(
              tooltip: 'Configurer la clé API',
              icon: Icon(
                Icons.vpn_key_rounded,
                color: hasKey ? AppColors.aiTutor : AppColors.grey400,
                size: 20,
              ),
              onPressed: onSetupKey,
            ),
            // TTS toggle
            IconButton(
              tooltip: ttsEnabled ? 'Désactiver la voix' : 'Activer la voix',
              icon: Icon(
                ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
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

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: AppColors.aiTutor.withOpacity(0.1),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.aiTutor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Configure ta clé Groq gratuite pour activer l\'IA en ligne →',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.aiTutor),
            ),
          ),
        ]),
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
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.aiTutor),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.aiTutor),
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
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
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
    widget.ctrl.addListener(_onChanged);
  }

  void _onChanged() {
    final has = widget.ctrl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onChanged);
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
                controller:      widget.ctrl,
                focusNode:       widget.focus,
                enabled:         !widget.isTyping,
                onSubmitted:     (_) => widget.onSend(),
                maxLines:        4,
                minLines:        1,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: widget.isTyping
                      ? 'Le Sage réfléchit…'
                      : 'Pose ta question…',
                  filled:    true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag:         'ai_send',
              onPressed:       canSend ? widget.onSend : null,
              backgroundColor: canSend ? AppColors.aiTutor : AppColors.grey300,
              elevation:       0,
              child: Icon(
                widget.isTyping
                    ? Icons.hourglass_bottom_rounded
                    : Icons.send_rounded,
                size:  18,
                color: Colors.white,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
