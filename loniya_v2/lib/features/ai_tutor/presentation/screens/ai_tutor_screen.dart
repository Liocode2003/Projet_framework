import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../../../../core/services/tts/tts_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
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
  final _ctrl     = TextEditingController();
  final _focus    = FocusNode();
  final _scroll   = ScrollController();
  final _picker   = ImagePicker();
  final _recorder = AudioRecorder();

  File?   _pendingImage;
  bool    _isRecording   = false;
  int     _prevTextLength = 0;
  bool    _pasteDetected  = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_detectPaste);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_detectPaste);
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Copy-paste detection ───────────────────────────────────────────────────

  void _detectPaste() {
    final current = _ctrl.text.length;
    final delta   = current - _prevTextLength;

    if (delta < -5 && _pasteDetected) {
      // User edited the pasted text substantially — give benefit of the doubt
      setState(() => _pasteDetected = false);
    } else if (delta > 20 && !_pasteDetected) {
      // Large single insertion → check clipboard to confirm it's a paste
      Clipboard.getData(Clipboard.kTextPlain).then((clip) {
        if (!mounted) return;
        final clipText = clip?.text?.trim() ?? '';
        if (clipText.length > 10 && _ctrl.text.contains(clipText)) {
          setState(() => _pasteDetected = true);
        }
      });
    }
    _prevTextLength = current;
  }

  // ─── Send text ──────────────────────────────────────────────────────────────

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    _focus.unfocus();

    if (_pendingImage != null) {
      final imgPath = _pendingImage!.path;
      final caption = text;
      setState(() => _pendingImage = null);
      _ctrl.clear();
      ref.read(aiTutorNotifierProvider.notifier)
          .sendImageMessage(imgPath, caption: caption);
    } else {
      final wasPasted = _pasteDetected;
      _ctrl.clear();
      setState(() { _pasteDetected = false; _prevTextLength = 0; });
      if (wasPasted) {
        ref.read(aiTutorNotifierProvider.notifier).handleCopiedMessage(text);
      } else {
        ref.read(aiTutorNotifierProvider.notifier).sendMessage(text);
      }
    }
    _scrollToBottom();
  }

  // ─── Pick image ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source:       source,
        imageQuality: 60,
        maxWidth:     800,
      );
      if (xFile == null) return;
      setState(() => _pendingImage = File(xFile.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'accéder à la galerie/caméra.')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context:       context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.aiTutor),
                title: const Text('Galerie',
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.aiTutor),
                title: const Text('Prendre une photo',
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Audio recording ────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permission micro refusée. Autorise le micro dans les paramètres.')),
      );
      return;
    }

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/sage_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement échoué — réessaie.')),
      );
      return;
    }
    ref.read(aiTutorNotifierProvider.notifier).sendAudioMessage(path);
    _scrollToBottom();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey =
        await ref.read(secureKeyServiceProvider).getApiKey() ?? '';
    if (!mounted) return;

    final ctrl = TextEditingController(text: currentKey);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.aiTutor, AppColors.levelPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Clé API Groq',
              style: TextStyle(
                  fontFamily:   'Nunito',
                  fontWeight:   FontWeight.w900,
                  fontSize:     17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:    const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:         AppColors.aiTutor.withOpacity(0.08),
                borderRadius:  BorderRadius.circular(12),
              ),
              child: const Text(
                '🔑 Clé gratuite sur console.groq.com\n'
                '⚡ Texte : llama-3.3-70b-versatile\n'
                '🖼️ Image : llama-4-scout (vision)\n'
                '🎤 Audio : whisper-large-v3-turbo\n'
                '📱 Sans clé : mode hors-ligne activé',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize:   12,
                    color:      AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller:  ctrl,
              obscureText: true,
              decoration:  InputDecoration(
                labelText: 'Clé Groq (gsk_...)',
                prefixIcon: const Icon(Icons.key_rounded),
                filled:    true,
                fillColor: AppColors.surfaceVariant,
                border:    OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
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
            child: const Text('Effacer',
                style: TextStyle(color: AppColors.error)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.aiTutor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
    final userRole   = ref.watch(currentUserRoleProvider);
    final userGrade  = ref.watch(currentUserProvider)?.gradeLevel ?? '';
    final canPredict = userRole == 'student' &&
        (userGrade.contains('3') || userGrade.toLowerCase().contains('terminale'));

    // Auto-scroll + TTS on new messages
    ref.listen<AiTutorState>(aiTutorNotifierProvider, (prev, next) {
      _scrollToBottom();
      // Fire TTS when readyTutorId changes — works for both streamed and
      // non-streamed replies without double-firing on every token.
      if (ttsEnabled &&
          next.readyTutorId != null &&
          next.readyTutorId != prev?.readyTutorId) {
        final msg = next.messages.lastWhere(
          (m) => m.id == next.readyTutorId,
          orElse: () => next.messages.last,
        );
        if (!msg.isUser && msg.content.isNotEmpty) {
          ref.read(ttsServiceProvider).speak(msg.content);
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
            canPredict:  canPredict,
            userGrade:   userGrade,
            onClear:     () =>
                ref.read(aiTutorNotifierProvider.notifier).clearChat(),
            onToggleTts: () {
              final v = !ttsEnabled;
              ref.read(ttsEnabledProvider.notifier).state = v;
              ref.read(ttsServiceProvider).setEnabled(v);
              if (!v) ref.read(ttsServiceProvider).stop();
            },
            onSetupKey: _showApiKeyDialog,
            onPredict:  () {
              final exam = userGrade.toLowerCase().contains('terminale')
                  ? 'BAC' : 'BEPC';
              ref.read(aiTutorNotifierProvider.notifier).predictExamResult(exam);
              _scrollToBottom();
            },
          ),

          if (!hasKey) _SetupBanner(onTap: _showApiKeyDialog),

          if (aiContext != null)
            _ContextBanner(context: aiContext, ref: ref),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding:    const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount:  chatState.messages.length +
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

          // Pending image preview
          if (_pendingImage != null)
            _AttachmentPreview(
              file:    _pendingImage!,
              onClear: () => setState(() => _pendingImage = null),
            ),

          if (_pasteDetected)
            _PasteWarningBanner(
              onDismiss: () => setState(() => _pasteDetected = false),
            ),

          _InputBar(
            ctrl:        _ctrl,
            focus:       _focus,
            isTyping:    chatState.isTyping,
            isRecording: _isRecording,
            hasImage:    _pendingImage != null,
            onSend:      _send,
            onPickImage: _showImageSourceSheet,
            onRecord:    _toggleRecording,
          ),
        ],
      ),
    );
  }
}

// ─── Attachment preview ───────────────────────────────────────────────────────

class _AttachmentPreview extends StatelessWidget {
  final File file;
  final VoidCallback onClear;
  const _AttachmentPreview({required this.file, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file,
                width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Image prête à envoyer',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          IconButton(
            icon:  const Icon(Icons.close_rounded,
                size: 20, color: AppColors.grey500),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ─── Paste warning ────────────────────────────────────────────────────────────

class _PasteWarningBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PasteWarningBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
      color:   const Color(0xFFFFF3E0),
      child:   Row(children: [
        const Icon(Icons.content_paste_rounded,
            size: 15, color: Color(0xFFE65100)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '📋 Texte collé détecté — Le Sage préfère tes propres mots',
            style: AppTextStyles.labelSmall
                .copyWith(color: const Color(0xFFE65100)),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding:     EdgeInsets.zero,
          icon: const Icon(Icons.close_rounded,
              size: 15, color: Color(0xFFE65100)),
          onPressed: onDismiss,
        ),
      ]),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool isTyping;
  final bool isRecording;
  final bool hasImage;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onRecord;

  const _InputBar({
    required this.ctrl,
    required this.focus,
    required this.isTyping,
    required this.isRecording,
    required this.hasImage,
    required this.onSend,
    required this.onPickImage,
    required this.onRecord,
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
    final canSend = (_hasText || widget.hasImage) && !widget.isTyping;

    return Material(
      color:     AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image picker
              _MediaButton(
                icon:      Icons.image_rounded,
                color:     widget.isRecording
                    ? AppColors.grey300
                    : AppColors.aiTutor,
                onPressed: widget.isTyping || widget.isRecording
                    ? null
                    : widget.onPickImage,
              ),

              // Mic / stop-recording
              _RecordButton(
                isRecording: widget.isRecording,
                disabled:    widget.isTyping,
                onTap:       widget.onRecord,
              ),

              const SizedBox(width: 4),

              // Text field
              Expanded(
                child: TextField(
                  controller:      widget.ctrl,
                  focusNode:       widget.focus,
                  enabled:         !widget.isTyping && !widget.isRecording,
                  onSubmitted:     (_) => widget.onSend(),
                  maxLines:        4,
                  minLines:        1,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: widget.isRecording
                        ? '🔴 Enregistrement…'
                        : widget.isTyping
                            ? 'Le Sage réfléchit…'
                            : widget.hasImage
                                ? 'Ajoute un commentaire… (optionnel)'
                                : 'Pose ta question…',
                    filled:    true,
                    fillColor: AppColors.surfaceVariant,
                    border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:   BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Send button
              FloatingActionButton.small(
                heroTag:         'ai_send',
                onPressed:       canSend ? widget.onSend : null,
                backgroundColor: canSend
                    ? AppColors.aiTutor
                    : AppColors.grey300,
                elevation: 0,
                child: Icon(
                  widget.isTyping
                      ? Icons.hourglass_bottom_rounded
                      : Icons.send_rounded,
                  size:  18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  const _MediaButton({
    required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon:      Icon(icon, size: 22),
      color:     color,
      onPressed: onPressed,
      padding:   const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool disabled;
  final VoidCallback onTap;
  const _RecordButton({
    required this.isRecording, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration:     const Duration(milliseconds: 200),
        width:        36, height: 36,
        margin:       const EdgeInsets.symmetric(horizontal: 2),
        decoration:   BoxDecoration(
          color:        isRecording
              ? AppColors.error.withOpacity(0.12)
              : Colors.transparent,
          shape:        BoxShape.circle,
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          size:  22,
          color: disabled
              ? AppColors.grey300
              : isRecording
                  ? AppColors.error
                  : AppColors.aiTutor,
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _AiHeader extends StatelessWidget {
  final bool isOnline, hasKey, ttsEnabled, canPredict;
  final String userGrade;
  final VoidCallback onClear, onToggleTts, onSetupKey, onPredict;

  const _AiHeader({
    required this.isOnline,
    required this.hasKey,
    required this.ttsEnabled,
    required this.canPredict,
    required this.userGrade,
    required this.onClear,
    required this.onToggleTts,
    required this.onSetupKey,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    final llmActive  = isOnline && hasKey;
    final statusColor = llmActive  ? AppColors.success
        : isOnline ? AppColors.warning
        : AppColors.grey400;
    final statusLabel = llmActive  ? 'En ligne · Groq LLM'
        : isOnline ? 'En ligne · clé manquante'
        : 'Hors-ligne · Mode local';

    return Material(
      color:     AppColors.surface,
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
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
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
                      width:  7, height: 7,
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
            IconButton(
              tooltip:   'Configurer la clé API',
              icon: Icon(Icons.vpn_key_rounded,
                  color: hasKey ? AppColors.aiTutor : AppColors.grey400,
                  size: 20),
              onPressed: onSetupKey,
            ),
            IconButton(
              tooltip: ttsEnabled ? 'Désactiver la voix' : 'Activer la voix',
              icon: Icon(
                ttsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: ttsEnabled ? AppColors.aiTutor : AppColors.grey500,
              ),
              onPressed: onToggleTts,
            ),
            if (canPredict)
              Tooltip(
                message: userGrade.toLowerCase().contains('terminale')
                    ? 'Prédiction BAC'
                    : 'Prédiction BEPC',
                child: IconButton(
                  icon: const Icon(Icons.emoji_events_rounded),
                  color: AppColors.warning,
                  onPressed: onPredict,
                ),
              ),
            IconButton(
              tooltip:   'Nouvelle conversation',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onClear,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Banners ──────────────────────────────────────────────────────────────────

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color:   AppColors.aiTutor.withOpacity(0.1),
        child:   Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 16, color: AppColors.aiTutor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Configure ta clé Groq gratuite pour l\'IA, la vision et la voix →',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.aiTutor),
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
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color:   AppColors.aiTutor.withOpacity(0.08),
      child:   Row(children: [
        const Icon(Icons.link_rounded, size: 16, color: AppColors.aiTutor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Contexte : ${context.subject} — ${context.stepTitle}',
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.aiTutor),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding:     EdgeInsets.zero,
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
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color:   AppColors.errorLight,
      child:   Row(children: [
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
