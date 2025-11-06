import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../services/gemini_service.dart';

/// Lightweight view-model to coordinate Gemini chat interactions with the UI.
class GeminiProvider extends ChangeNotifier {
  GeminiProvider(this._service) : _chat = _service.startChat();

  final GeminiService _service;
  late ChatSession _chat;

  final List<GeminiChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<GeminiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _service.isConfigured;

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    _messages.add(GeminiChatMessage(role: GeminiRole.user, text: trimmed));
    notifyListeners();

    try {
      final response = await _chat.sendMessage(Content.text(trimmed));
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        _messages.add(GeminiChatMessage(role: GeminiRole.model, text: text));
      } else {
        _error = 'Gemini returned an empty response.';
      }
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Gemini sendMessage failed: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetConversation({List<Content> seedHistory = const []}) {
    _messages.clear();
    _error = null;
    _chat = _service.startChat(history: seedHistory);
    notifyListeners();
  }
}

class GeminiChatMessage {
  const GeminiChatMessage({required this.role, required this.text});

  final GeminiRole role;
  final String text;
}

enum GeminiRole { user, model }
