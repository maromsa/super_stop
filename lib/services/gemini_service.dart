import 'package:google_generative_ai/google_generative_ai.dart';

/// A thin wrapper around the Gemini SDK that centralises configuration
/// and provides a simplified API for the rest of the app.
class GeminiService {
  GeminiService({
    String model = defaultModel,
    String? apiKey,
    GenerationConfig? generationConfig,
    List<SafetySetting>? safetySettings,
  })  : _apiKey = (apiKey ?? const String.fromEnvironment('GEMINI_API_KEY')).trim(),
        _modelName = model,
        _generationConfig = generationConfig,
        _safetySettings = safetySettings {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is missing. Provide it explicitly or set the '
        '`GEMINI_API_KEY` compile-time environment variable using --dart-define.',
      );
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: _generationConfig,
      safetySettings: _safetySettings,
    );
  }

  static const String defaultModel = 'gemini-1.5-flash';

  final String _apiKey;
  final String _modelName;
  final GenerationConfig? _generationConfig;
  final List<SafetySetting>? _safetySettings;
  late final GenerativeModel _model;

  /// Exposes whether the service has a usable API key.
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns the underlying [GenerativeModel] for advanced scenarios.
  GenerativeModel get model => _model;

  /// Generates a single text response from the supplied [prompt].
  ///
  /// Optional [history] can be supplied to provide prior conversation
  /// context. Use the [startChat] helper for multi-turn conversations
  /// if you prefer to stream updates into the history automatically.
  Future<String> generateText(
    String prompt, {
    List<Content> history = const [],
  }) async {
    final response = await _model.generateContent([
      ...history,
      Content.text(prompt),
    ]);

    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Gemini returned an empty response.');
    }
    return text;
  }

  /// Streams text chunks for the given [prompt].
  Stream<String> streamText(
    String prompt, {
    List<Content> history = const [],
  }) async* {
    await for (final event in _model.generateContentStream([
      ...history,
      Content.text(prompt),
    ])) {
      final text = event.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Creates a chat session that maintains its own history and is
  /// convenient for conversational UX.
  ChatSession startChat({List<Content> history = const []}) {
    return _model.startChat(history: history);
  }
}
