import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/language_provider.dart';
import '../../../models/consultation_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/consultation_repository.dart';
import '../../../shared/widgets/language_selector_sheet.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/ai_status_indicator.dart';
import '../widgets/voice_input_sheet.dart';
import '../widgets/consultation_summary_sheet.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  final bool isGuest;

  const ConsultationScreen({super.key, this.isGuest = false});

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      final isGuestMode = widget.isGuest || user == null;
      
      // If language preference hasn't been chosen yet in app / guest mode, show language selection sheet first
      if (!ref.read(languageProvider).hasChosenPreference) {
        if (mounted) {
          await LanguageSelectorSheet.show(context, isMandatory: true);
        }
      }

      if (!mounted) return;
      final prefLang = ref.read(languageProvider).currentLanguage.code;
      ref.read(consultationProvider.notifier).initSession(
            patientId: isGuestMode ? null : user.id,
            isGuest: isGuestMode,
            language: prefLang,
          );
    });
  }

  @override
  void dispose() {
    try {
      ref.read(ttsServiceProvider).stop();
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
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

  void _openVoiceSheet() {
    final activeLang = ref.read(consultationProvider).currentLanguage;
    ref.read(consultationProvider.notifier).setListening(true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceInputSheet(
        initialLanguageCode: activeLang,
        onSend: (transcribedText, lang) {
          ref
              .read(consultationProvider.notifier)
              .sendPatientMessage(transcribedText, language: lang);
          _scrollToBottom();
        },
      ),
    ).then((_) {
      ref.read(consultationProvider.notifier).setListening(false);
    });
  }

  void _showSummarySheet([ConsultationSummaryModel? customSummary]) {
    final summary = customSummary ?? ref.read(consultationProvider).summary;
    if (summary == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConsultationSummarySheet(
        summary: summary,
        onBookDoctor: (confirmedSummary) {
          final sId = ref.read(consultationProvider).sessionId ?? '';
          context.push(
            '${AppRoutes.bookDoctor}?consultationId=$sId&initialComplaint=${Uri.encodeComponent(confirmedSummary.chiefComplaint)}',
          );
        },
      ),
    );
  }

  Future<void> _endConversationAndShowSummary() async {
    final summary =
        await ref.read(consultationProvider.notifier).endConsultation();
    if (mounted && summary != null) {
      _showSummarySheet(summary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationState = ref.watch(consultationProvider);
    final messages = consultationState.messages;
    final tts = ref.watch(ttsServiceProvider);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isCompact = screenWidth < 400;
    final maxChatWidth = screenWidth > 860 ? 820.0 : screenWidth;

    ref.listen(consultationProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (previous?.intake.intakeComplete != true &&
          next.intake.intakeComplete == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && next.summary != null) {
            _showSummarySheet(next.summary);
          }
        });
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        ref.read(ttsServiceProvider).stop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () {
              ref.read(ttsServiceProvider).stop();
              context.pop();
            },
          ),
          titleSpacing: 0,
          title: RepaintBoundary(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Health Assistant',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.isGuest ? 'Guest Consultation' : 'Patient Intake',
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                // Language Switcher Badge
                InkWell(
                  onTap: () {
                    LanguageSelectorSheet.show(
                      context,
                      onSelected: (selected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Language switched to ${selected.name} (${selected.englishName}). Next messages will be in ${selected.name}.',
                            ),
                            backgroundColor: AppColors.surface,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.translate_rounded,
                          color: AppColors.primaryLight,
                          size: 12,
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          consultationState.currentLanguage.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  tooltip: tts.autoSpeakEnabled ? 'Voice Output: ON' : 'Voice Output: OFF',
                  icon: Icon(
                    tts.autoSpeakEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: tts.autoSpeakEnabled
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 19,
                  ),
                  onPressed: () {
                    ref.read(ttsServiceProvider).toggleAutoSpeak();
                  },
                ),
                const SizedBox(width: 2),
                AIStatusIndicator(
                  state: consultationState.uiState,
                  isCompact: isCompact,
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _endConversationAndShowSummary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'End',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.border, height: 1),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxChatWidth),
              child: Column(
                children: [
                  // Top Emergency Alert Strip if detected
                  if (consultationState.intake.shouldFlagEmergency)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.error.withValues(alpha: 0.2),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency_rounded,
                              color: AppColors.errorLight, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Possible medical emergency flagged. Please seek urgent care.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.errorLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Chat Messages View with RepaintBoundary for fast scrolling & keyboard smoothness
                  Expanded(
                    child: RepaintBoundary(
                      child: messages.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                                strokeWidth: 2,
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return ChatBubble(message: messages[index]);
                              },
                            ),
                    ),
                  ),

                  // Beautiful Intake Complete Action Bar
                  if (consultationState.intake.intakeComplete)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C1425),
                        border: Border(
                          top: BorderSide(color: Color(0xFF1E293B)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                                color: AppColors.primary.withValues(alpha: 0.08),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showSummarySheet(),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 11,
                                      horizontal: isCompact ? 4 : 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.description_outlined,
                                          color: AppColors.primary,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isCompact ? 'Summary' : 'View Summary',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, Color(0xFF06B6D4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final complaint = consultationState.intake.chiefComplaint ?? 'Medical Intake Consultation';
                                    final sId = consultationState.sessionId ?? '';
                                    context.push(
                                      '${AppRoutes.bookDoctor}?consultationId=$sId&initialComplaint=${Uri.encodeComponent(complaint)}',
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 11,
                                      horizontal: isCompact ? 4 : 8,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Book Doctor',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white70,
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Isolated High-Performance Chat Input Bar
                  _ChatInputBar(
                    onSend: (text) {
                      ref.read(consultationProvider.notifier).sendPatientMessage(text);
                      _scrollToBottom();
                    },
                    onOpenVoice: _openVoiceSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Isolated Chat Input Bar widget with its own local state.
/// This prevents keystroke & focus setState from rebuilding the entire conversation message tree,
/// ensuring instant 60-120fps keyboard popup and typing responsiveness.
class _ChatInputBar extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback onOpenVoice;

  const _ChatInputBar({
    required this.onSend,
    required this.onOpenVoice,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _textController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment / Help Icon
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Image and medical report upload coming soon.',
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight.withValues(alpha: 0.6),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Expandable Pill Container
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10192C),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasText
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type or speak your symptoms...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (hasText)
                    GestureDetector(
                      onTap: () {
                        _textController.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  // Dedicated voice mic inside pill
                  GestureDetector(
                    onTap: widget.onOpenVoice,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: hasText ? _submit : widget.onOpenVoice,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: hasText
                        ? [AppColors.primary, const Color(0xFF06B6D4)]
                        : [AppColors.surfaceLight, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: hasText
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.border,
                  ),
                  boxShadow: hasText
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  hasText
                      ? Icons.arrow_upward_rounded
                      : Icons.mic_none_rounded,
                  color: hasText ? Colors.white : AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
