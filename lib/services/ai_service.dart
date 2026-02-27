import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Provider Definitions ────────────────────────────────────────────────────

enum AiProvider {
  geminiFlash,
  geminiFlashLite,
  groq,
  mistral,
  openRouter,
}

class AiProviderInfo {
  final String id;
  final String name;
  final String badge;
  final String description;
  final String apiKeyUrl;
  final String apiKeyHint;
  final bool isGemini; // uses google_generative_ai package

  const AiProviderInfo({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
    required this.apiKeyUrl,
    required this.apiKeyHint,
    required this.isGemini,
  });
}

const Map<AiProvider, AiProviderInfo> aiProviders = {
  AiProvider.geminiFlash: AiProviderInfo(
    id: 'gemini_flash',
    name: 'Gemini 2.5 Flash',
    badge: '🥇',
    description: '250 req/day • 10 RPM • Best quality',
    apiKeyUrl: 'https://aistudio.google.com/apikey',
    apiKeyHint: 'aistudio.google.com/apikey',
    isGemini: true,
  ),
  AiProvider.geminiFlashLite: AiProviderInfo(
    id: 'gemini_flash_lite',
    name: 'Gemini 2.5 Flash-Lite',
    badge: '🥈',
    description: '1,000 req/day • 15 RPM • Fast & light',
    apiKeyUrl: 'https://aistudio.google.com/apikey',
    apiKeyHint: 'aistudio.google.com/apikey',
    isGemini: true,
  ),
  AiProvider.groq: AiProviderInfo(
    id: 'groq',
    name: 'Groq',
    badge: '🥉',
    description: '⚡ Fastest responses • Free tier',
    apiKeyUrl: 'https://console.groq.com/keys',
    apiKeyHint: 'console.groq.com/keys',
    isGemini: false,
  ),
  AiProvider.mistral: AiProviderInfo(
    id: 'mistral',
    name: 'Mistral AI',
    badge: '🇫🇷',
    description: 'Strong reasoning • Free tier',
    apiKeyUrl: 'https://console.mistral.ai/api-keys',
    apiKeyHint: 'console.mistral.ai/api-keys',
    isGemini: false,
  ),
  AiProvider.openRouter: AiProviderInfo(
    id: 'openrouter',
    name: 'OpenRouter',
    badge: '🌐',
    description: 'Access free models • Multi-provider',
    apiKeyUrl: 'https://openrouter.ai/keys',
    apiKeyHint: 'openrouter.ai/keys',
    isGemini: false,
  ),
};

// ─── AI Service ──────────────────────────────────────────────────────────────

class AiService {
  static const String _providerKey = 'ai_provider';
  static const String _apiKeyPrefix = 'ai_api_key_';

  // ── Provider management ──

  static Future<AiProvider> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_providerKey);
    return AiProvider.values.firstWhere(
      (p) => aiProviders[p]!.id == id,
      orElse: () => AiProvider.geminiFlash,
    );
  }

  static Future<void> setSelectedProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, aiProviders[provider]!.id);
  }

  // ── API Key management (per provider) ──

  static Future<String?> getApiKey([AiProvider? provider]) async {
    provider ??= await getSelectedProvider();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_apiKeyPrefix${aiProviders[provider]!.id}');
  }

  static Future<void> setApiKey(String apiKey, [AiProvider? provider]) async {
    provider ??= await getSelectedProvider();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_apiKeyPrefix${aiProviders[provider]!.id}', apiKey);
  }

  static Future<void> removeApiKey([AiProvider? provider]) async {
    provider ??= await getSelectedProvider();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_apiKeyPrefix${aiProviders[provider]!.id}');
  }

  static Future<bool> hasApiKey([AiProvider? provider]) async {
    final key = await getApiKey(provider);
    return key != null && key.isNotEmpty;
  }

  // ── Core generation ──

  Future<String> _generate(String prompt) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
          'API key not configured. Go to Profile → AI Playground to add your ${aiProviders[provider]!.name} API key.');
    }

    final info = aiProviders[provider]!;
    if (info.isGemini) {
      return _generateGemini(prompt, apiKey, provider);
    } else {
      return _generateHttp(prompt, apiKey, provider);
    }
  }

  Future<String> _generateGemini(
      String prompt, String apiKey, AiProvider provider) async {
    final modelName = provider == AiProvider.geminiFlashLite
        ? 'gemini-2.5-flash-lite'
        : 'gemini-2.5-flash';

    final model = GenerativeModel(model: modelName, apiKey: apiKey);
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Failed to generate response. Please try again.';
    } catch (e) {
      throw Exception('${aiProviders[provider]!.name} Error: $e');
    }
  }

  Future<String> _generateHttp(
      String prompt, String apiKey, AiProvider provider) async {
    late String url;
    late String model;
    Map<String, String> extraHeaders = {};

    switch (provider) {
      case AiProvider.groq:
        url = 'https://api.groq.com/openai/v1/chat/completions';
        model = 'llama-3.3-70b-versatile';
        break;
      case AiProvider.mistral:
        url = 'https://api.mistral.ai/v1/chat/completions';
        model = 'mistral-small-latest';
        break;
      case AiProvider.openRouter:
        url = 'https://openrouter.ai/api/v1/chat/completions';
        model = 'meta-llama/llama-3.3-70b-instruct:free';
        extraHeaders = {
          'HTTP-Referer': 'https://examsprint.app',
          'X-Title': 'ExamSprint',
        };
        break;
      default:
        throw Exception('Unsupported HTTP provider');
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          ...extraHeaders,
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Failed to generate response.';
      } else {
        final errBody = jsonDecode(response.body);
        final errMsg = errBody['error']?['message'] ?? response.body;
        throw Exception('${aiProviders[provider]!.name} Error: $errMsg');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('${aiProviders[provider]!.name} Error: $e');
    }
  }

  // ─── Feature Methods ──────────────────────────────────────────────────────

  Future<String> generateQuiz({
    required String context,
    required String subjectName,
    int questionCount = 10,
  }) async {
    final prompt = '''
You are an expert exam preparation assistant. Based on the following study material, generate exactly $questionCount multiple-choice questions.

**Subject**: $subjectName

**Study Material**:
$context

**Instructions**:
- Generate exactly $questionCount questions
- Each question should have 4 options (A, B, C, D)
- Mark the correct answer clearly
- Questions should test understanding, not just memorization
- Cover different topics from the material
- Use this EXACT format for each question:

**Q1.** [Question text]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
**Answer: [Letter]**
**Explanation:** [Brief explanation]

---

Generate the quiz now:
''';
    return _generate(prompt);
  }

  Future<String> generateSummary({
    required String context,
    required String subjectName,
  }) async {
    final prompt = '''
You are an expert academic summarizer. Create a comprehensive, well-structured summary of the following study material.

**Subject**: $subjectName

**Study Material**:
$context

**Instructions**:
- Start with a brief overview (2-3 sentences)
- Organize into clear sections with headings
- Highlight key concepts, definitions, and formulas
- Use bullet points for easy scanning
- Include "Key Takeaways" at the end
- Make it exam-focused and concise
- Use markdown formatting for structure

Generate the summary now:
''';
    return _generate(prompt);
  }

  Future<String> answerQuestion({
    required String context,
    required String question,
    required String subjectName,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    final historyText = chatHistory.map((msg) {
      return '${msg['role'] == 'user' ? 'Student' : 'Tutor'}: ${msg['content']}';
    }).join('\n');

    final prompt = '''
You are a friendly, knowledgeable tutor helping a student prepare for exams. Answer their question based on the study material provided.

**Subject**: $subjectName

**Study Material**:
$context

${historyText.isNotEmpty ? '**Previous Conversation**:\n$historyText\n' : ''}

**Student's Question**: $question

**Instructions**:
- Answer accurately based on the study material
- If the answer is not in the material, say so and provide general knowledge
- Use simple, clear language
- Include examples where helpful
- Use markdown formatting
- Keep the response concise but thorough

Your answer:
''';
    return _generate(prompt);
  }

  Future<String> generateStudyPlan({
    required String context,
    required String subjectName,
    int daysAvailable = 7,
  }) async {
    final prompt = '''
You are an expert academic planner. Create a detailed, day-wise study plan for the following subject material.

**Subject**: $subjectName
**Days Available**: $daysAvailable days

**Study Material**:
$context

**Instructions**:
- Create a day-by-day study plan for $daysAvailable days
- Prioritize important topics
- Include time estimates for each topic
- Add revision sessions
- Include practice/self-test suggestions
- Use markdown formatting with clear structure
- Add tips for effective studying
- Include breaks and review periods

**Format each day like**:
## Day X: [Focus Area]
- **Morning (2 hrs)**: [Topics]
- **Afternoon (2 hrs)**: [Topics]
- **Evening (1 hr)**: [Review/Practice]
- 💡 **Tip**: [Study tip]

Generate the study plan now:
''';
    return _generate(prompt);
  }
}
