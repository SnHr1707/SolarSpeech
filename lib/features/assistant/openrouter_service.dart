import 'package:flutter/foundation.dart' show debugPrint;
import 'package:openrouter_api/openrouter_api.dart';
import 'package:openrouter_api/src/models/open_router_error.dart';
import 'package:openrouter_api/src/models/open_router_inference.dart';
import 'package:openrouter_api/src/models/llm_response.dart';
import '../../core/config/app_config.dart';

/// Core LLM service using the openrouter_api package with conversation memory.
class OpenRouterService {
  // Typed conversation history for the openrouter_api package
  final List<LlmMessage> _conversationHistory = [];

  // Two separate instances: one for chat (persistent memory), one for voice
  static final OpenRouterService _chatInstance = OpenRouterService._();
  static final OpenRouterService _voiceInstance = OpenRouterService._();
  OpenRouterService._();

  static OpenRouterService get chat => _chatInstance;
  static OpenRouterService get voice => _voiceInstance;

  // Shared OpenRouter client (stateless — safe to reuse)
  static final OpenRouterInference _client = OpenRouter.inference(
    key: AppConfig.openRouterApiKey,
    appId: 'https://solarspeech.app',
    appTitle: 'SolarSpeech',
  );

  void clearHistory() => _conversationHistory.clear();

  /// Send a message to the LLM and get a response.
  /// [systemPrompt] defines the LLM's behavior.
  /// [additionalContext] is database data injected before the user message.
  /// [rememberConversation] controls whether this exchange is saved to history.
  Future<String> sendMessage({
    required String userMessage,
    required String systemPrompt,
    String? additionalContext,
    bool rememberConversation = true,
  }) async {
    // Build message list: system → history → user
    final messages = <LlmMessage>[
      LlmMessage.system(systemPrompt),
    ];

    // Inject conversation history for context memory
    if (rememberConversation) {
      messages.addAll(_conversationHistory);
    }

    // Build the user message with optional database context
    String fullUserMessage = userMessage;
    if (additionalContext != null && additionalContext.isNotEmpty) {
      fullUserMessage =
          '$userMessage\n\n[DATABASE CONTEXT — use this data to answer]\n$additionalContext';
    }

    messages.add(
      LlmMessage.user(LlmMessageContent.text(fullUserMessage)),
    );

    try {
      final LlmResponse response = await _client.getCompletion(
        modelId: AppConfig.llmModel,
        messages: messages,
      );

      final content = response.choices.first.content;

      // Strip <think>…</think> blocks from thinking models
      final cleanContent = _stripThinking(content);

      // Persist conversation
      if (rememberConversation) {
        _conversationHistory.add(
          LlmMessage.user(LlmMessageContent.text(userMessage)),
        );
        _conversationHistory.add(
          LlmMessage.assistant(cleanContent),
        );

        // Keep history manageable — last 20 exchanges (40 messages)
        while (_conversationHistory.length > 40) {
          _conversationHistory.removeAt(0);
        }
      }

      return cleanContent;
    } on OpenRouterError catch (e) {
      debugPrint('[SolarSpeech LLM] OpenRouter error: ${e.code} — ${e.message}');
      rethrow;
    }
  }

  /// Strip `<think>…</think>` blocks produced by thinking models.
  static String _stripThinking(String content) {
    return content
        .replaceAll(
            RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .trim();
  }
}
