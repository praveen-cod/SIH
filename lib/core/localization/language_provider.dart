import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported Languages across HealthCall AI
class AppLanguage {
  final String code;
  final String name;
  final String englishName;
  final String localeId;
  final String ttsLocale;
  final String nativeGreeting;
  final String samplePhrase;
  final String badge;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.englishName,
    required this.localeId,
    required this.ttsLocale,
    required this.nativeGreeting,
    required this.samplePhrase,
    required this.badge,
  });

  static const AppLanguage english = AppLanguage(
    code: 'en',
    name: 'English',
    englishName: 'English',
    localeId: 'en_US',
    ttsLocale: 'en-US',
    nativeGreeting: "Hi 👋 I'm your HealthCall AI assistant. What health problem or symptoms are you experiencing today?",
    samplePhrase: "I have had fever and headache for 2 days",
    badge: '🇬🇧 English',
  );

  static const AppLanguage tamil = AppLanguage(
    code: 'ta',
    name: 'தமிழ்',
    englishName: 'Tamil',
    localeId: 'ta_IN',
    ttsLocale: 'ta-IN',
    nativeGreeting: "வணக்கம் 👋 நான் உங்கள் HealthCall AI மருத்துவ உதவியாளர்.\nஉங்களுக்கு இன்று என்ன உடல்நல பிரச்சனை அல்லது அறிகுறிகள் உள்ளன?",
    samplePhrase: "நேற்று முதல் காய்ச்சல் மற்றும் தலைவலி இருக்கு",
    badge: '🇮🇳 தமிழ்',
  );

  static const AppLanguage hindi = AppLanguage(
    code: 'hi',
    name: 'हिन्दी',
    englishName: 'Hindi',
    localeId: 'hi_IN',
    ttsLocale: 'hi-IN',
    nativeGreeting: "नमस्ते 👋 मैं आपका HealthCall AI सहायक हूँ।\nआज आपको क्या स्वास्थ्य समस्या या लक्षण महसूस हो रहे हैं?",
    samplePhrase: "मुझे दो दिन से बुखार और सिरदर्द है",
    badge: '🇮🇳 हिन्दी',
  );

  static const AppLanguage kannada = AppLanguage(
    code: 'kn',
    name: 'ಕನ್ನಡ',
    englishName: 'Kannada',
    localeId: 'kn_IN',
    ttsLocale: 'kn-IN',
    nativeGreeting: "ನಮಸ್ಕಾರ 👋 ನಾನು ನಿಮ್ಮ HealthCall AI ಸಹಾಯಕ.\nಇಂದು ನಿಮಗೆ ಯಾವ ಆರೋಗ್ಯ ಸಮಸ್ಯೆ ಅಥವಾ ಲಕ್ಷಣಗಳು ಕಾಣಿಸಿಕೊಂಡಿವೆ?",
    samplePhrase: "ನನಗೆ ಎರಡು ದಿನಗಳಿಂದ ಜ್ವರ ಮತ್ತು ತಲೆನೋವು ಇದೆ",
    badge: '🇮🇳 ಕನ್ನಡ',
  );

  static const AppLanguage telugu = AppLanguage(
    code: 'te',
    name: 'తెలుగు',
    englishName: 'Telugu',
    localeId: 'te_IN',
    ttsLocale: 'te-IN',
    nativeGreeting: "నమస్కారం 👋 నేను మీ HealthCall AI అసిస్టెంట్.\nఈరోజు మీకు ఎలాంటి ఆరోగ్య సమస్య లేదా లక్షణాలు ఉన్నాయి?",
    samplePhrase: "నాకు రెండు రోజుల నుండి జ్వరం మరియు తలనొప్పి ఉంది",
    badge: '🇮🇳 తెలుగు',
  );

  static const AppLanguage malayalam = AppLanguage(
    code: 'ml',
    name: 'മലയാളം',
    englishName: 'Malayalam',
    localeId: 'ml_IN',
    ttsLocale: 'ml-IN',
    nativeGreeting: "നമസ്കാരം 👋 ഞാൻ നിങ്ങളുടെ HealthCall AI അസിസ്റ്റന്റ്.\nഇന്ന് നിങ്ങൾക്ക് എന്തെങ്കിലും ആരോഗ്യ പ്രശ്നങ്ങളോ ലക്ഷണങ്ങളോ ഉണ്ടോ?",
    samplePhrase: "എനിക്ക് രണ്ടു ദിവസമായി പനിയും തലവേദനയും ഉണ്ട്",
    badge: '🇮🇳 മലയാളം',
  );

  static const AppLanguage bengali = AppLanguage(
    code: 'bn',
    name: 'বাংলা',
    englishName: 'Bengali',
    localeId: 'bn_IN',
    ttsLocale: 'bn-IN',
    nativeGreeting: "নমস্কার 👋 আমি আপনার HealthCall AI সহকারী।\nআজ আপনার কি স্বাস্থ্য সমস্যা বা লক্ষণ দেখা দিচ্ছে?",
    samplePhrase: "আমার দুই দিন ধরে জ্বর ও মাথা ব্যাথা",
    badge: '🇮🇳 বাংলা',
  );

  static const AppLanguage marathi = AppLanguage(
    code: 'mr',
    name: 'मराठी',
    englishName: 'Marathi',
    localeId: 'mr_IN',
    ttsLocale: 'mr-IN',
    nativeGreeting: "नमस्कार 👋 मी तुमचा HealthCall AI सहाय्यक आहे.\nआज तुम्हाला काय आरोग्याच्या तक्रारी किंवा लक्षणे जाणवत आहेत?",
    samplePhrase: "मला दोन दिवसांपासून ताप आणि डोकेदुखी आहे",
    badge: '🇮🇳 मराठी',
  );

  static const List<AppLanguage> all = [
    tamil,
    english,
    hindi,
    kannada,
    telugu,
    malayalam,
    bengali,
    marathi,
  ];

  static AppLanguage fromCode(String? code) {
    if (code == null) return english;
    final normalized = code.toLowerCase().trim().split('_').first.split('-').first;
    for (final l in all) {
      if (l.code == normalized) return l;
    }
    return english;
  }
}

class LanguageState {
  final AppLanguage currentLanguage;
  final bool hasChosenPreference;

  const LanguageState({
    this.currentLanguage = AppLanguage.english,
    this.hasChosenPreference = false,
  });

  LanguageState copyWith({
    AppLanguage? currentLanguage,
    bool? hasChosenPreference,
  }) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      hasChosenPreference: hasChosenPreference ?? this.hasChosenPreference,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _prefKeyLanguage = 'healthcall_preferred_language';
  static const String _prefKeyChosen = 'healthcall_language_chosen_flag';

  LanguageNotifier() : super(const LanguageState()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKeyLanguage);
      final hasChosen = prefs.getBool(_prefKeyChosen) ?? false;
      if (code != null) {
        state = state.copyWith(
          currentLanguage: AppLanguage.fromCode(code),
          hasChosenPreference: hasChosen,
        );
      }
    } catch (e) {
      debugPrint('Error loading language preferences: $e');
    }
  }

  Future<void> selectLanguage(AppLanguage language) async {
    state = state.copyWith(
      currentLanguage: language,
      hasChosenPreference: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, language.code);
      await prefs.setBool(_prefKeyChosen, true);
    } catch (e) {
      debugPrint('Error saving language preferences: $e');
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});
