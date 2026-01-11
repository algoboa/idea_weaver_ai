import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Voice input state
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final String? error;
  final double soundLevel;

  const VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.error,
    this.soundLevel = 0.0,
  });

  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    String? error,
    double? soundLevel,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

/// Voice input notifier for managing speech recognition
class VoiceInputNotifier extends Notifier<VoiceInputState> {
  late SpeechToText _speechToText;
  String _selectedLocaleId = 'en_US';

  @override
  VoiceInputState build() {
    _speechToText = SpeechToText();
    _initSpeech();
    return const VoiceInputState();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );

      state = state.copyWith(isAvailable: available);

      if (available) {
        // Get available locales and set preferred one
        final locales = await _speechToText.locales();
        if (locales.isNotEmpty) {
          // Try to find Japanese locale first, then English
          final japaneseLocale = locales.firstWhere(
            (locale) => locale.localeId.startsWith('ja'),
            orElse: () => locales.firstWhere(
              (locale) => locale.localeId.startsWith('en'),
              orElse: () => locales.first,
            ),
          );
          _selectedLocaleId = japaneseLocale.localeId;
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize speech recognition: $e');
    }
  }

  void _handleError(SpeechRecognitionError error) {
    state = state.copyWith(
      error: error.errorMsg,
      isListening: false,
    );
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(isListening: false);
    }
  }

  /// Start listening for voice input
  Future<void> startListening({String? localeId}) async {
    if (!state.isAvailable) {
      state = state.copyWith(error: 'Speech recognition not available');
      return;
    }

    state = state.copyWith(
      isListening: true,
      recognizedText: '',
      error: null,
    );

    await _speechToText.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: _onSoundLevelChange,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId ?? _selectedLocaleId,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  /// Cancel listening and discard results
  Future<void> cancelListening() async {
    await _speechToText.cancel();
    state = state.copyWith(
      isListening: false,
      recognizedText: '',
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    state = state.copyWith(
      recognizedText: result.recognizedWords,
    );
  }

  void _onSoundLevelChange(double level) {
    state = state.copyWith(soundLevel: level);
  }

  /// Clear the recognized text
  void clearText() {
    state = state.copyWith(recognizedText: '');
  }

  /// Set the locale for speech recognition
  void setLocale(String localeId) {
    _selectedLocaleId = localeId;
  }

  /// Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speechToText.locales();
  }
}

/// Provider for voice input
final voiceInputProvider = NotifierProvider<VoiceInputNotifier, VoiceInputState>(() {
  return VoiceInputNotifier();
});
