import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class LlmNavigationService {
  // Hybrid Approach: Check common local phrases first for zero latency
  static final Map<RegExp, String> _localIntents = {
    RegExp(r'(dashboard|home)', caseSensitive: false): '/dashboard',
    RegExp(r'(slms|string)', caseSensitive: false): '/slms',
    RegExp(r'(sensor)', caseSensitive: false): '/sensors',
    RegExp(r'(alert)', caseSensitive: false): '/alerts',
  };

  static Future<String?> getRouteFromText(String userInput) async {
    // 1. Local Regex Check (Fastest)
    for (var entry in _localIntents.entries) {
      if (entry.key.hasMatch(userInput)) {
        return entry.value;
      }
    }

    // 2. Fallback to LLM (Using OpenAI format as an example)
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.llmApiKey}',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages":[
            {
              "role": "system",
              "content": """You are an AI router for a Solar Plant Flutter app. 
              Map the user's request to a JSON object with a single 'route' key.
              Available routes: /dashboard, /plants/:plantId, /plants/:plantId/inverters/:inverterId, /slms, /slms/:inverterId, /sensors, /alerts.
              Example: User: "Take me to inverter 3" -> Output: {"route": "/inverters/3"}
              Respond ONLY with valid JSON."""
            },
            {"role": "user", "content": userInput}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> jsonRoute = jsonDecode(content);
        return jsonRoute['route'];
      }
    } catch (e) {
      print("LLM Routing failed: $e");
    }
    return null;
  }
}