class AppConfig {
  static const bool useSyntheticData = false;

  // ── Assistant Mode ──
  // true  = Rule-based entity resolution + LLM response formatting
  //         (falls back to rule-based on LLM API error)
  // false = Sole rule-based mode (no LLM calls for chat responses)
  static const bool useLlmAssisted = true;

  // ── OpenRouter LLM Configuration ──
  // API key from https://openrouter.ai/settings/keys
  static const String openRouterApiKey =
      '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';

  // Model to use — fast model for responsive chatbot
  static const String llmModel = 'google/gemini-2.0-flash-001';
}