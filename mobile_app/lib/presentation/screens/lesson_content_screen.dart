// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../../core/translation_service.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TTS Engine (reuses same browser speech synthesis pattern)
// ─────────────────────────────────────────────────────────────────────────────

List<html.SpeechSynthesisVoice> _lcCachedVoices = [];

void _lcInitVoices() {
  if (!kIsWeb) return;
  try {
    final synth = html.window.speechSynthesis;
    if (synth != null) {
      _lcCachedVoices = synth.getVoices();
      synth.addEventListener('voiceschanged', (_) {
        _lcCachedVoices = synth.getVoices();
      });
    }
  } catch (_) {}
}

void _lcSpeak({
  required String text,
  required String langName,
  String phoneticGuide = '',
  double rate = 1.0,
  void Function()? onStarted,
  void Function()? onFinished,
}) {
  if (!kIsWeb) { onFinished?.call(); return; }
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) { onFinished?.call(); return; }

    _lcInitVoices();
    synth.cancel();
    synth.resume();

    final hasOlChiki = RegExp(r'[\u1C50-\u1C7F]').hasMatch(text);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    final voices = _lcCachedVoices.isNotEmpty ? _lcCachedVoices : synth.getVoices();

    String toSpeak = text;
    String targetLang = 'en-US';

    if (langName == 'English') {
      toSpeak = text; targetLang = 'en-US';
    } else if (langName == 'Hindi') {
      toSpeak = text; targetLang = 'hi-IN';
    } else if (hasOlChiki || langName == 'Santali') {
      toSpeak = phoneticGuide.trim().isNotEmpty ? phoneticGuide.trim() : olChikiToPhonetic(text);
      targetLang = 'en-IN';
    } else {
      final hasHindi = voices.any((v) => (v.lang ?? '').toLowerCase().startsWith('hi'));
      if (hasHindi && hasDevanagari) {
        toSpeak = text.replaceAll(':', 'ह');
        targetLang = 'hi-IN';
      } else if (phoneticGuide.trim().isNotEmpty) {
        toSpeak = phoneticGuide.trim();
        targetLang = 'en-IN';
      } else {
        toSpeak = hasDevanagari ? devanagariToPhonetic(text) : text;
        targetLang = 'en-IN';
      }
    }

    toSpeak = toSpeak
        .replaceAll(':', 'h').replaceAll('ः', 'h')
        .replaceAll(RegExp(r'[।॥|]'), '.')
        .replaceAll(RegExp(r'\s+'), ' ').trim();

    if (toSpeak.isEmpty) { onFinished?.call(); return; }

    final utterance = html.SpeechSynthesisUtterance(toSpeak);
    utterance.rate = rate;
    utterance.volume = 1.0;
    utterance.pitch = 1.0;
    utterance.lang = targetLang;

    if (voices.isNotEmpty) {
      final voice = voices.firstWhere(
        (v) {
          final l = (v.lang ?? '').toLowerCase();
          final n = (v.name ?? '').toLowerCase();
          if (targetLang == 'hi-IN') return l.startsWith('hi') || n.contains('hindi') || n.contains('lekha');
          if (targetLang == 'en-IN') return l == 'en-in' || n.contains('india') || n.contains('rishi');
          return l.startsWith('en');
        },
        orElse: () => voices.firstWhere(
          (v) => (v.lang ?? '').toLowerCase().startsWith('en'),
          orElse: () => voices.first,
        ),
      );
      utterance.voice = voice;
    }

    onStarted?.call();
    utterance.onEnd.listen((_) => onFinished?.call());
    utterance.onError.listen((_) => onFinished?.call());
    synth.speak(utterance);
  } catch (_) { onFinished?.call(); }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waveform animation widget
// ─────────────────────────────────────────────────────────────────────────────

class _MiniWaveform extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  const _MiniWaveform({this.color = const Color(0xFF5C27D8), this.isPlaying = true});

  @override
  State<_MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<_MiniWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MiniWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) { _ctrl.repeat(reverse: true); }
    else if (!widget.isPlaying && _ctrl.isAnimating) { _ctrl.stop(); }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(6, (i) {
          final h = widget.isPlaying ? (8 + (i.isOdd ? _ctrl.value * 14 : (1 - _ctrl.value) * 14)) : 4.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson Content Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _LessonScript {
  final String hindi;
  final String hindiPhonetic;
  final Map<String, String> translations;
  final Map<String, String> phonetics;

  const _LessonScript({
    required this.hindi,
    required this.hindiPhonetic,
    required this.translations,
    required this.phonetics,
  });

  String getTranslation(String lang) =>
      translations[lang] ?? translations['Mundari'] ?? hindi;

  String getPhonetic(String lang) =>
      phonetics[lang] ?? translations[lang] ?? hindiPhonetic;
}

class _ActivityStep {
  final String title;
  final String instruction;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<String> tips;

  const _ActivityStep({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.tips,
  });
}

class _AssessmentQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _AssessmentQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson Database (keyed by lesson title)
// ─────────────────────────────────────────────────────────────────────────────

final Map<String, List<_LessonScript>> _lessonScripts = {
  'Numbers 1 to 10': [
    const _LessonScript(
      hindi: 'बच्चों, आज हम एक से दस तक गिनती सीखेंगे।',
      hindiPhonetic: 'Bachchon, aaj hum ek se das tak ginti seekhenge.',
      translations: {
        'Mundari': 'गड़ाको, तिशिंग अबू मियद ते गेले गिनती इतुवा।',
        'Santali': 'ᱜᱤᱫᱽᱨᱟᱹ, ᱛᱮᱦᱮᱧ ᱵᱚ ᱑ ᱠᱷᱚᱱ ᱑᱐ ᱞᱮᱠᱷᱟ ᱵᱚ ᱪᱮᱫᱚᱜᱼᱟ᱾',
        'Ho': 'होनको, तिशिंग अबू मियद ते गेले गिनती सिखवा।',
        'Kurukh': 'तंगड़ाको, इनना 1 ती 10 तक लेखा सिखओत।',
        'Gondi': 'पिलाक, नेंड मम्मत उंदी ता पद लेखा हेककाट।',
      },
      phonetics: {
        'Mundari': 'Gadako, tishing abu miyad te gele ginti ituwa.',
        'Santali': 'Gidra, teheng bo 1 khon 10 lekha bo chedog-a.',
        'Ho': 'Honko, tishing abu miyad te gele ginti sikhwa.',
        'Kurukh': 'Tangdako, inna 1 tee 10 tak lekha sikhot.',
        'Gondi': 'Pilak, nend mammat undi ta pad lekha hekkat.',
      },
    ),
    const _LessonScript(
      hindi: 'मेरे साथ गिनें — एक, दो, तीन, चार, पाँच।',
      hindiPhonetic: 'Mere saath ginein — ek, do, teen, char, panch.',
      translations: {
        'Mundari': 'अबूवा संगे गनाव — मियद, बारिया, आपिया, उपुन, मोणोय।',
        'Santali': 'ᱟᱵᱚᱣᱟᱜ ᱥᱟᱝᱜᱮ ᱠᱩᱜᱤ — ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱩᱱ, ᱢᱚᱬᱮ᱾',
        'Ho': 'अबूवा संगे गिनती — मियद, बारिया, आपेया, उपुन, मोणोया।',
        'Kurukh': 'मेरे साथ गिनो — ओन्द, एन्द, मून्द, नाख, पांच।',
        'Gondi': 'मम्मत संगे लेखा — उंदी, रंद, मूंद, नालुंग, सयुं।',
      },
      phonetics: {
        'Mundari': 'Abuwa sange ganav — Miyad, Bariya, Aapiya, Upun, Monoy.',
        'Santali': 'Abowag sange kugi — Mid, Bar, Pe, Pun, Mone.',
        'Ho': 'Abuwa sange ginti — Miyad, Bariya, Aapeya, Upun, Monoya.',
        'Kurukh': 'Mere saath gino — Ond, End, Moond, Naakh, Panch.',
        'Gondi': 'Mammat sange lekha — Oondee, Rand, Moond, Naaloong, Sayoong.',
      },
    ),
    const _LessonScript(
      hindi: 'अब छह से दस — छह, सात, आठ, नौ, दस।',
      hindiPhonetic: 'Ab chhe se das — chhe, saat, aath, nau, das.',
      translations: {
        'Mundari': 'आब तुरूय ते गेले — तुरूय, एया, इरिल, आरे, गेले।',
        'Santali': 'ᱱᱚᱣᱟ ᱛᱩᱨᱩᱭ ᱠᱷᱚᱱ ᱜᱮᱞ — ᱛᱩᱨᱩᱭ, ᱮᱭᱟᱭ, ᱤᱨᱟᱹᱞ, ᱟᱨᱮ, ᱜᱮᱞ᱾',
        'Ho': 'आब तुरूया ते गेले — तुरूया, एया, इरिया, आरेया, गेले।',
        'Kurukh': 'अब सोये से दस — सोये, सात, आठ, नौ, दस।',
        'Gondi': 'नेंड सारूंग ते पद — सारूंग, येडूंग, एण्मूद, नरके, पद।',
      },
      phonetics: {
        'Mundari': 'Aab turui te gele — Turui, Eya, Iril, Aare, Gele.',
        'Santali': 'Nowa turui khon gel — Turui, Eayay, Iral, Aare, Gel.',
        'Ho': 'Aab turuya te gele — Turuya, Eya, Iriya, Areya, Gele.',
        'Kurukh': 'Ab soye se das — Soye, Saat, Aath, Nau, Das.',
        'Gondi': 'Nend saaroong te pad — Saaroong, Yedoong, Enmood, Narke, Pad.',
      },
    ),
  ],
  'Alphabet and Sounds': [
    const _LessonScript(
      hindi: 'बच्चों, आज हम हिंदी के अक्षर सीखेंगे।',
      hindiPhonetic: 'Bachchon, aaj hum hindi ke akshar seekhenge.',
      translations: {
        'Mundari': 'गड़ाको, तिशिंग अबू हिंदी लिपि इतुवा।',
        'Santali': 'ᱜᱤᱫᱽᱨᱟᱹ, ᱛᱮᱦᱮᱧ ᱵᱚ ᱦᱤᱸᱫᱤ ᱚᱞ ᱪᱮᱫᱚᱜᱼᱟ᱾',
        'Ho': 'होनको, तिशिंग अबू हिंदी अक्षर सिखवा।',
        'Kurukh': 'तंगड़ाको, इनना हिंदी अक्षर सिखओत।',
        'Gondi': 'पिलाक, नेंड मम्मत हिंदी अक्षर हेककाट।',
      },
      phonetics: {
        'Mundari': 'Gadako, tishing abu Hindi lipi ituwa.',
        'Santali': 'Gidra, teheng bo Hindi ol chedog-a.',
        'Ho': 'Honko, tishing abu Hindi akshar sikhwa.',
        'Kurukh': 'Tangdako, inna Hindi akshar sikhot.',
        'Gondi': 'Pilak, nend mammat Hindi akshar hekkat.',
      },
    ),
  ],
};

final Map<String, List<_ActivityStep>> _lessonActivities = {
  'Numbers 1 to 10': [
    const _ActivityStep(
      title: 'Finger Counting Round',
      instruction: 'Ask all students to hold up fingers while counting together. Teacher calls a number in tribal language; students hold up that many fingers. Repeat 3 rounds.',
      icon: Icons.back_hand_rounded,
      iconColor: Color(0xFF5C27D8),
      iconBg: Color(0xFFEDE9FE),
      tips: [
        'Use the Mundari/Santali counting words each time (Miyad, Bar, Pe…)',
        'Let students call the number back to you in their language',
        'Clap together after every correct answer',
      ],
    ),
    const _ActivityStep(
      title: 'Pebble Count Station',
      instruction: 'Place a pile of 10 pebbles at each desk group. Teacher says a number in the tribal language; students pick out that many pebbles and count aloud. Groups compete to finish first.',
      icon: Icons.circle_rounded,
      iconColor: Color(0xFF10B981),
      iconBg: Color(0xFFD1FAE5),
      tips: [
        'Pebbles, seeds, or chalk pieces all work equally well',
        'Let the fastest group lead the next count',
        'Encourage students to announce the count in their home language',
      ],
    ),
    const _ActivityStep(
      title: 'Number Song Chant',
      instruction: 'Sing/chant the numbers 1–10 in Mundari/Santali to a simple clapping rhythm. Repeat 3 times, getting faster each round.',
      icon: Icons.music_note_rounded,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFEF3C7),
      tips: [
        'Mid-Bar-Pe rhythm: clap once for each syllable',
        'Students can drum on their desks as percussion',
        'Finish by all writing 1–10 in their copy',
      ],
    ),
  ],
};

final Map<String, List<_AssessmentQuestion>> _lessonAssessments = {
  'Numbers 1 to 10': [
    const _AssessmentQuestion(
      question: 'How do you say "Five" in Mundari?',
      options: ['Miyad', 'Bariya', 'Monoy', 'Turui'],
      correctIndex: 2,
      explanation: '"Monoy" (मोणोय) means Five in Mundari. Miyad = 1, Bariya = 2, Turui = 6.',
    ),
    const _AssessmentQuestion(
      question: 'What number comes after "आरे" (Aare) in Mundari counting?',
      options: ['इरिल (Iril)', 'गेले (Gele)', 'तुरूय (Turui)', 'एया (Eya)'],
      correctIndex: 1,
      explanation: '"गेले (Gele)" means Ten (10). आरे (Aare) = Nine, so Ten comes next.',
    ),
    const _AssessmentQuestion(
      question: 'In Santali (Ol Chiki), how is the number Three written?',
      options: ['ᱢᱤᱫ', 'ᱵᱟᱨ', 'ᱯᱮ', 'ᱯᱩᱱ'],
      correctIndex: 2,
      explanation: '"ᱯᱮ" (Pe) means Three in Santali. ᱢᱤᱫ = One, ᱵᱟᱨ = Two, ᱯᱩᱱ = Four.',
    ),
    const _AssessmentQuestion(
      question: 'A student holds up 7 fingers. Which Mundari word do they say?',
      options: ['एया (Eya)', 'तुरूय (Turui)', 'आरे (Aare)', 'इरिल (Iril)'],
      correctIndex: 0,
      explanation: '"एया (Eya)" means Seven in Mundari. Turui = 6, Iril = 8, Aare = 9.',
    ),
    const _AssessmentQuestion(
      question: 'Which counting word is shared across Mundari, Ho, and Santali for "One"?',
      options: ['Monoy', 'Miyad / Mid', 'Turui', 'Gele'],
      correctIndex: 1,
      explanation: '"Miyad" (Mundari/Ho) / "Mid" (Santali) are cognates meaning One across Austroasiatic tribal languages.',
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen Widget
// ─────────────────────────────────────────────────────────────────────────────

class LessonContentScreen extends StatefulWidget {
  const LessonContentScreen({super.key});

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF5C27D8);
  static const _deepPurple = Color(0xFF28127D);
  static const _bg = Color(0xFFF8F6FD);

  String _activeTab = 'Lesson Script';
  final List<String> _tabs = ['Lesson Script', 'Activities', 'Assessment'];

  // TTS state
  String? _currentlyPlayingKey;

  // Assessment state
  int _questionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answerRevealed = false;
  int _correctCount = 0;
  bool _assessmentComplete = false;
  final List<bool> _answerRecord = [];

  @override
  void initState() {
    super.initState();
    _lcInitVoices();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      try { html.window.speechSynthesis?.cancel(); } catch (_) {}
    }
    super.dispose();
  }

  void _playAudio({required String key, required String text, required String lang, String phonetic = ''}) {
    if (_currentlyPlayingKey == key) {
      if (kIsWeb) html.window.speechSynthesis?.cancel();
      setState(() => _currentlyPlayingKey = null);
      return;
    }
    _lcSpeak(
      text: text,
      langName: lang,
      phoneticGuide: phonetic,
      rate: 0.9,
      onStarted: () => setState(() => _currentlyPlayingKey = key),
      onFinished: () => setState(() => _currentlyPlayingKey = null),
    );
  }

  String get _lessonTitle => AppState.instance.selectedLesson;
  String get _studentLang => AppState.instance.studentLanguage;

  List<_LessonScript> get _scripts =>
      _lessonScripts[_lessonTitle] ?? _lessonScripts['Numbers 1 to 10']!;

  List<_ActivityStep> get _activities =>
      _lessonActivities[_lessonTitle] ?? _lessonActivities['Numbers 1 to 10']!;

  List<_AssessmentQuestion> get _questions =>
      _lessonAssessments[_lessonTitle] ?? _lessonAssessments['Numbers 1 to 10']!;

  // ── Lesson Script Tab ──────────────────────────────────────────────────────

  Widget _buildScriptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bilingual Lesson Script',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tap any speaker icon to hear native pronunciation',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hindi ⇌ $_studentLang',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // All script items
          ...List.generate(_scripts.length, (i) {
            final script = _scripts[i];
            final nativeText = script.getTranslation(_studentLang);
            final phonetic = script.getPhonetic(_studentLang);
            final hindiKey = 'hindi_$i';
            final nativeKey = 'native_$i';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      'Step ${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Hindi card
                  _buildScriptCard(
                    key: hindiKey,
                    language: 'Hindi',
                    text: script.hindi,
                    phonetic: script.hindiPhonetic,
                    accent: const Color(0xFF1E40AF),
                    accentBg: const Color(0xFFEFF6FF),
                    isPlaying: _currentlyPlayingKey == hindiKey,
                  ),
                  const SizedBox(height: 8),
                  // Student language card
                  _buildScriptCard(
                    key: nativeKey,
                    language: _studentLang,
                    text: nativeText,
                    phonetic: phonetic,
                    accent: _purple,
                    accentBg: const Color(0xFFEDE9FE),
                    isPlaying: _currentlyPlayingKey == nativeKey,
                  ),
                  if (phonetic.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.hearing_rounded, size: 13, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Phonetic: $phonetic',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          // Action buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/translate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.translate_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Live Translate',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/voice_conversation'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _purple, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFEDE9FE),
                  ),
                  icon: const Icon(Icons.mic_rounded, color: _purple, size: 18),
                  label: Text(
                    'Voice Bridge',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: _purple),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScriptCard({
    required String key,
    required String language,
    required String text,
    required String phonetic,
    required Color accent,
    required Color accentBg,
    required bool isPlaying,
  }) {
    return VernexaFloatable(
      hoverOffset: -2,
      hoverElevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying ? accent : const Color(0xFFE5E0F5),
            width: isPlaying ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Language label badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                language,
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
            const SizedBox(width: 12),
            // Script text
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF261080),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Play button
            InkWell(
              onTap: () => _playAudio(key: key, text: text, lang: language, phonetic: phonetic),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPlaying ? accent : accentBg,
                  shape: BoxShape.circle,
                ),
                child: isPlaying
                    ? Center(child: _MiniWaveform(color: Colors.white, isPlaying: true))
                    : Icon(Icons.volume_up_rounded, color: accent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activities Tab ─────────────────────────────────────────────────────────

  Widget _buildActivitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.extension_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hands-On Classroom Activities',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF166534)),
                      ),
                      Text(
                        '${_activities.length} activities • All use local materials',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(_activities.length, (i) {
            final step = _activities[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: step.iconBg, shape: BoxShape.circle),
                          child: Icon(step.icon, color: step.iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity ${i + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: step.iconColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                step.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.instruction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Teacher Tips:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...step.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(color: step.iconColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            );
          }),

          // Navigation to Learning Pulse
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/learning_pulse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              label: Text(
                'Check Class Understanding via Learning Pulse',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Assessment Tab ─────────────────────────────────────────────────────────

  Widget _buildAssessmentTab() {
    if (_assessmentComplete) return _buildAssessmentSummary();

    final question = _questions[_questionIndex];
    final progress = (_questionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comprehension Check',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _deepPurple),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_questionIndex + 1} / ${_questions.length}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _purple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(_purple),
            ),
          ),
          const SizedBox(height: 18),

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'Q${_questionIndex + 1}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: _purple),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _deepPurple,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Answer options
          ...List.generate(question.options.length, (i) {
            final isSelected = _selectedAnswerIndex == i;
            final isCorrect = i == question.correctIndex;
            Color borderColor = const Color(0xFFE5E0F5);
            Color bgColor = Colors.white;
            IconData? trailIcon;

            if (_answerRevealed) {
              if (isCorrect) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFFF0FDF4);
                trailIcon = Icons.check_circle_rounded;
              } else if (isSelected) {
                borderColor = const Color(0xFFEF4444);
                bgColor = const Color(0xFFFEF2F2);
                trailIcon = Icons.cancel_rounded;
              }
            } else if (isSelected) {
              borderColor = _purple;
              bgColor = const Color(0xFFEDE9FE);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _answerRevealed ? null : () => setState(() => _selectedAnswerIndex = i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected && !_answerRevealed
                              ? _purple
                              : (_answerRevealed && isCorrect ? const Color(0xFF10B981) : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: (isSelected && !_answerRevealed) || (_answerRevealed && isCorrect)
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _deepPurple,
                          ),
                        ),
                      ),
                      if (trailIcon != null)
                        Icon(
                          trailIcon,
                          color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Explanation box (shown after answer)
          if (_answerRevealed)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF92400E), height: 1.45),
                    ),
                  ),
                ],
              ),
            ),

          // Submit / Next button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedAnswerIndex == null
                  ? null
                  : () {
                      if (!_answerRevealed) {
                        final isCorrect = _selectedAnswerIndex == question.correctIndex;
                        if (isCorrect) _correctCount++;
                        _answerRecord.add(isCorrect);
                        setState(() => _answerRevealed = true);
                      } else {
                        if (_questionIndex < _questions.length - 1) {
                          setState(() {
                            _questionIndex++;
                            _selectedAnswerIndex = null;
                            _answerRevealed = false;
                          });
                        } else {
                          setState(() => _assessmentComplete = true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _answerRevealed ? const Color(0xFF10B981) : _purple,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                !_answerRevealed
                    ? 'Submit Answer'
                    : (_questionIndex < _questions.length - 1 ? 'Next Question →' : 'View Results'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _selectedAnswerIndex == null ? Colors.grey.shade400 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAssessmentSummary() {
    final pct = ((_correctCount / _questions.length) * 100).round();
    final isExcellent = pct >= 80;
    final isGood = pct >= 60;
    final scoreColor = isExcellent
        ? const Color(0xFF10B981)
        : (isGood ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final message = isExcellent
        ? 'Excellent comprehension! Students are ready for the next lesson.'
        : (isGood
            ? 'Good understanding. A quick tribal language review will solidify the concepts.'
            : 'Low comprehension. Re-teach using hands-on activities and tribal language examples before moving on.');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text('Assessment Complete!',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: _deepPurple)),
          const SizedBox(height: 24),

          // Score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.12),
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$pct%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: scoreColor)),
                  Text('Score',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: scoreColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '$_correctCount of ${_questions.length} correct',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: scoreColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.grey.shade800, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Per-question breakdown
          ...List.generate(_answerRecord.length, (i) {
            final correct = _answerRecord[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: correct ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Q${i + 1}: ${_questions[i].question}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Retry button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _questionIndex = 0;
                  _selectedAnswerIndex = null;
                  _answerRevealed = false;
                  _correctCount = 0;
                  _assessmentComplete = false;
                  _answerRecord.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: Text('Retry Assessment',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/learning_pulse'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _purple, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFEDE9FE),
              ),
              icon: const Icon(Icons.insights_rounded, color: _purple, size: 18),
              label: Text('Open Learning Pulse',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Learning Outcome Banner ────────────────────────────────────────────────

  Widget _buildOutcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E0F5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: Color(0xFFFFF7ED), shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF97316), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Outcome',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: _deepPurple),
                ),
                Text(
                  'Students can identify and count numbers 1–10 in Hindi and $_studentLang.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF422A76)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Pill Selector ─────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeTab = tab),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFECE8FB) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _purple : const Color(0xFFE5E0F5),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab == 'Lesson Script' ? Icons.article_rounded : (tab == 'Activities' ? Icons.extension_rounded : Icons.assignment_turned_in_rounded),
                      size: 14,
                      color: isSelected ? _purple : const Color(0xFF6F62AB),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tab,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _purple : const Color(0xFF6F62AB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Body Selector ─────────────────────────────────────────────────────────

  Widget _activeTabBody() {
    switch (_activeTab) {
      case 'Activities': return _buildActivitiesTab();
      case 'Assessment': return _buildAssessmentTab();
      default: return _buildScriptTab();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            const VernexaDesktopSidebar(currentIndex: 1),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 860),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: _deepPurple, size: 22),
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/lessons', (r) => false),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lessonTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _deepPurple),
                                ),
                                Text(
                                  'Grade ${AppState.instance.selectedGrade} • ${AppState.instance.studentLanguage} Vernacular',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6F62AB), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildOutcomeBanner(),
                      const SizedBox(height: 12),
                      _buildTabSelector(),
                      const SizedBox(height: 4),
                      Expanded(child: _activeTabBody()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/lessons', (r) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _purple,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/lessons', (r) => false),
          ),
          title: Text(
            _lessonTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Outcome + tabs sub-header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    _buildOutcomeBanner(),
                    const SizedBox(height: 10),
                    _buildTabSelector(),
                  ],
                ),
              ),
              Expanded(child: _activeTabBody()),
            ],
          ),
        ),
        bottomNavigationBar: const VernexaBottomNav(currentIndex: 1),
      ),
    );
  }
}
