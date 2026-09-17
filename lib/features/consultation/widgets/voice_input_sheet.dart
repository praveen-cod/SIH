import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Modal bottom sheet for speech-to-text recording with animated waveform and multilingual support
class VoiceInputSheet extends StatefulWidget {
  final Function(String transcribedText, String? detectedLang) onSend;
  final String? initialLanguageCode;

  const VoiceInputSheet({
    super.key,
    required this.onSend,
    this.initialLanguageCode,
  });

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textEditingCtrl = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  bool _isListening = false;
  bool _speechAvailable = false;
  String _statusMessage = '';

  final Map<String, String> _locales = {
    'ta_IN': 'தமிழ்',
    'en_US': 'English',
    'hi_IN': 'हिन्दी',
    'kn_IN': 'ಕನ್ನಡ',
    'te_IN': 'తెలుగు',
    'ml_IN': 'മലയാളം',
    'bn_IN': 'বাংলা',
    'mr_IN': 'मराठी',
  };
  late String _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    final appLang = AppLanguage.fromCode(widget.initialLanguageCode);
    _selectedLocaleId = appLang.localeId;
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus && _isListening) {
        _stopListening();
      }
      if (mounted) setState(() {});
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          debugPrint('Speech recognizer status error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
              if (val.errorMsg.toLowerCase().contains('audio') ||
                  val.errorMsg.toLowerCase().contains('busy') ||
                  val.errorMsg.toLowerCase().contains('client')) {
                _statusMessage =
                    'Microphone in use by another app. Tap mic to retry or choose a symptom preset below.';
              } else {
                _statusMessage = val.errorMsg;
              }
            });
          }
        },
      );

      if (_speechAvailable) {
        // Try checking available locales from device
        try {
          final systemLocales = await _speech.locales();
          for (var l in systemLocales) {
            if (l.localeId.startsWith('ta')) _locales[l.localeId] = 'தமிழ்';
            if (l.localeId.startsWith('hi')) _locales[l.localeId] = 'हिन्दी';
            if (l.localeId.startsWith('te')) _locales[l.localeId] = 'తెలుగు';
            if (l.localeId.startsWith('kn')) _locales[l.localeId] = 'ಕನ್ನಡ';
          }
        } catch (_) {}
        if (mounted) {
          setState(() {
            _statusMessage = 'Tap the microphone to start speaking';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Microphone busy or not available. Tap preset below or retry.';
          });
        }
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Microphone is currently unavailable. Please retry.';
        });
      }
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        setState(() {
          _statusMessage =
              'Microphone is currently in use. Please retry or choose a symptom preset below.';
        });
        return;
      }
    }

    setState(() {
      _isListening = true;
      _statusMessage = 'Listening in ${_locales[_selectedLocaleId] ?? 'Selected Language'}...';
    });

    try {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _textEditingCtrl.text = val.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          localeId: _selectedLocaleId,
        ),
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      setState(() {
        _isListening = false;
        _statusMessage = 'Mic access blocked by call/meeting: $e';
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _statusMessage = 'Voice captured. You can review or edit below.';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speech.stop();
    _textEditingCtrl.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _textEditingCtrl.text.trim();
    if (text.isNotEmpty) {
      _speech.stop();
      Navigator.pop(context);
      final langCode = _selectedLocaleId.split('_').first;
      widget.onSend(text, langCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final maxSheetWidth = screenWidth > 640 ? 580.0 : screenWidth;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isEditing = keyboardHeight > 0 || _textFocusNode.hasFocus;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxSheetWidth),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, max(16.0, keyboardHeight + 12)),
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1.5),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (isEditing) ...[
                    // COMPACT EDITING MODE: Keyboard is open, instant response, Send Button always visible above keypad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Symptoms Message',
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _textFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.keyboard_hide_rounded, size: 16, color: AppColors.textMuted),
                          label: Text(
                            'Hide Keypad',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                      ),
                      child: TextField(
                        controller: _textEditingCtrl,
                        focusNode: _textFocusNode,
                        maxLines: 3,
                        minLines: 2,
                        autofocus: false,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Edit your transcribed symptoms...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: () {
                              _speech.stop();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _submitText,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Send to AI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // NORMAL VOICE RECORDING MODE: Full UI with mic, wave & chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.error : AppColors.online,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? '🎙 Listening...' : 'Speech to Text',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: _isListening ? Colors.white : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Language selector chips
                    Text(
                      'Select Speaking Language:',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: _locales.entries.map((e) {
                        final isSelected = _selectedLocaleId == e.key;
                        return ChoiceChip(
                          label: Text(e.value),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedLocaleId = e.key;
                              });
                              if (_isListening) {
                                _stopListening();
                                _startListening();
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Central Pulsing Mic
                    GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isListening) ...[
                                Container(
                                  width: 110 + (_pulseController.value * 24),
                                  height: 110 + (_pulseController.value * 24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15 * (1 - _pulseController.value),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 90 + (_pulseController.value * 16),
                                  height: 90 + (_pulseController.value * 16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25 * (1 - _pulseController.value),
                                    ),
                                  ),
                                ),
                              ],
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isListening
                                        ? [AppColors.error, const Color(0xFFC026D3)]
                                        : AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening
                                              ? AppColors.error
                                              : AppColors.primary)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening
                                      ? Icons.mic_rounded
                                      : Icons.mic_none_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Audio Waveform animation
                    if (_isListening)
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(18, (index) {
                                final wave = sin((_waveController.value * 2 * pi) +
                                        (index * 0.4))
                                    .abs();
                                final height = 8 + (wave * 22);
                                return Container(
                                  width: 3.5,
                                  height: height,
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5 + (wave * 0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _statusMessage.isNotEmpty
                              ? _statusMessage
                              : 'Tap mic and speak your symptoms',
                          style: AppTextStyles.caption.copyWith(
                            color: _statusMessage.contains('error') ||
                                    _statusMessage.contains('not available')
                                ? AppColors.warning
                                : AppColors.textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Editable transcribed text preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isListening
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: _textEditingCtrl,
                        focusNode: _textFocusNode,
                        maxLines: 3,
                        minLines: 2,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening... words will appear here'
                              : 'Speak or tap quick phrase below...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Multilingual quick sample test chips (for instant demoing)
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Quick Clinical Demo Presets:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _getPresetsForLocale(_selectedLocaleId).map((preset) {
                          return _sampleChip(preset['text']!, preset['title']!);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Actions: Cancel & Send
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _speech.stop();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _submitText,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Send Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getPresetsForLocale(String localeId) {
    if (localeId.startsWith('ta')) {
      return [
        {'title': '🌡️ காய்ச்சல்', 'text': 'கடந்த 3 நாட்களாக எனக்கு கடுமையான காய்ச்சல் மற்றும் இருமல் உள்ளது'},
        {'title': '🚨 நெஞ்சு வலி', 'text': 'திடீரென நெஞ்சு வலி, மூச்சுத் திணறல் மற்றும் இடது கை வலி அதிகமாக உள்ளது'},
        {'title': '🤢 வயிற்று வலி', 'text': 'நேற்று இரவு முதல் தீவிர வயிற்று வலி மற்றும் வாந்தி மயக்கம் உள்ளது'},
      ];
    } else if (localeId.startsWith('hi')) {
      return [
        {'title': '🌡️ बुखार व खांसी', 'text': 'मुझे पिछले 3 दिनों से तेज बुखार, सूखी खांसी और सिरदर्द है'},
        {'title': '🚨 सीने में दर्द', 'text': 'सीने में अचानक तेज दर्द और सांस लेने में बहुत तकलीफ हो रही है'},
        {'title': '🤢 पेट दर्द', 'text': 'कल रात से पेट में तेज दर्द और उल्टी जैसा महसूस हो रहा है'},
      ];
    } else if (localeId.startsWith('kn')) {
      return [
        {'title': '🌡️ ಜ್ವರ', 'text': 'ನನಗೆ 3 ದಿನಗಳಿಂದ ತೀವ್ರ ಜ್ವರ ಮತ್ತು ಕೆಮ್ಮು ಇದೆ'},
        {'title': '🚨 ಎದೆ ನೋವು', 'text': 'ಎದೆಯಲ್ಲಿ ತೀವ್ರ ನೋವು ಮತ್ತು ಉಸಿರಾಟದ ತೊಂದರೆ ಇದೆ'},
      ];
    } else if (localeId.startsWith('te')) {
      return [
        {'title': '🌡️ జ్వరం', 'text': 'నాకు 3 రోజులుగా తీవ్రమైన జ్వరం మరియు దగ్గు ఉంది'},
        {'title': '🚨 ఛాతీ నొప్పి', 'text': 'ఛాతీలో తీవ్రమైన నొప్పి మరియు శ్వಾಸ తీసుకోవడంలో ఇబ్బంది ఉంది'},
      ];
    } else if (localeId.startsWith('ml')) {
      return [
        {'title': '🌡️ പനി', 'text': 'കഴിഞ്ഞ 3 ദിവസമായി കഠിനമായ പനിയും ചുമയും ഉണ്ട്'},
        {'title': '🚨 നെഞ്ചുവേദന', 'text': 'നെഞ്ചിൽ കഠിനമായ വേദനയും ശ്വാസംമുട്ടലും ഉണ്ട്'},
      ];
    } else if (localeId.startsWith('bn')) {
      return [
        {'title': '🌡️ জ্বর', 'text': 'আমার ৩ দিন ধরে খুব জ্বর ও কাশি হচ্ছে'},
        {'title': '🚨 বুকে ব্যথা', 'text': 'বুকে তীব্র ব্যথা এবং শ্বাস নিতে কষ্ট হচ্ছে'},
      ];
    } else if (localeId.startsWith('mr')) {
      return [
        {'title': '🌡️ ताप', 'text': 'मला ३ दिवसांपासून तीव्र ताप आणि खोकला आहे'},
        {'title': '🚨 छातीत वेदना', 'text': 'छातीत तीव्र वेदना आणि श्वास घेण्यास त्रास होत आहे'},
      ];
    } else {
      return [
        {'title': '🌡️ Fever & Cough', 'text': 'I have had a high fever, dry cough and sore throat for 3 days'},
        {'title': '🚨 Chest Pain (Triage)', 'text': 'Sudden sharp chest tightness, shortness of breath and sweating'},
        {'title': '🤢 Stomach Pain', 'text': 'Severe lower abdominal pain with nausea since yesterday'},
      ];
    }
  }

  Widget _sampleChip(String sample, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
        avatar: const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
        label: Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () {
          setState(() {
            _textEditingCtrl.text = sample;
            _isListening = false;
          });
        },
      ),
    );
  }
}
