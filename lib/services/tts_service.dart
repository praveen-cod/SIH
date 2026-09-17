import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service supporting multilingual speech synthesis (English, Tamil, Hindi, Telugu, etc.)
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _autoSpeakEnabled = true;

  bool get isSpeaking => _isSpeaking;
  bool get autoSpeakEnabled => _autoSpeakEnabled;

  Function(bool isSpeaking)? onSpeakingChanged;

  TextToSpeechService() {
    _initTts();
  }

  void _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingChanged?.call(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  void toggleAutoSpeak() {
    _autoSpeakEnabled = !_autoSpeakEnabled;
    if (!_autoSpeakEnabled && _isSpeaking) {
      stop();
    }
  }

  /// Speaks text in the specified language ('en', 'ta', 'hi', 'te', etc.)
  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;

    try {
      await stop();

      final ttsLang = _mapLanguageCode(languageCode ?? 'en');

      // Check language availability and set
      final isAvail = await _flutterTts.isLanguageAvailable(ttsLang);
      if (isAvail == 1 || isAvail == true) {
        await _flutterTts.setLanguage(ttsLang);
      } else {
        // Fallback to primary language tag or English
        final fallback = languageCode ?? 'en-US';
        await _flutterTts.setLanguage(fallback);
      }

      // Clean markdown, symbols, and formatting for clean audio pronunciation
      final cleanText = _cleanTextForSpeech(text);
      if (cleanText.isEmpty) return;

      debugPrint('TTS Speaking in $ttsLang: $cleanText');
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS speak error: $e. Retrying in en-US default...');
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.speak(_cleanTextForSpeech(text));
      } catch (retryError) {
        debugPrint('TTS fallback error: $retryError');
      }
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      onSpeakingChanged?.call(false);
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stop();
      onSpeakingChanged = null;
    } catch (e) {
      debugPrint('TTS dispose error: $e');
    }
  }

  String _mapLanguageCode(String code) {
    final clean = code.toLowerCase().trim().split('_').first.split('-').first;
    switch (clean) {
      case 'ta':
        return 'ta-IN';
      case 'hi':
        return 'hi-IN';
      case 'kn':
        return 'kn-IN';
      case 'te':
        return 'te-IN';
      case 'ml':
        return 'ml-IN';
      case 'bn':
        return 'bn-IN';
      case 'mr':
        return 'mr-IN';
      case 'en':
      default:
        return 'en-US';
    }
  }

  String _cleanTextForSpeech(String text) {
    // Strip emojis, markdown symbols, asterisks, bullet points
    return text
        .replaceAll(RegExp(r'[*#_`~>⚠️●◌🎙✓👋]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
