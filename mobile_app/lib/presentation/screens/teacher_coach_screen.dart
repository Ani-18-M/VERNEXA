import 'dart:async';
import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';
import '../../core/app_state.dart';
import '../../core/translation_service.dart';
import '../../core/gemini_translation_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Web Audio API Synthesizer (Realistic Sound FX for Haptic/Audio Feedback)
// ──────────────────────────────────────────────────────────────────────────────

void _coachPlayTone({double frequency = 440.0, double duration = 0.12, String type = 'sine'}) {
  if (!kIsWeb) return;
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        try {
          var AC = window.AudioContext || window.webkitAudioContext;
          if (!AC) return;
          var ctx = new AC();
          var osc = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.type = '$type';
          osc.frequency.value = $frequency;
          osc.connect(gain);
          gain.connect(ctx.destination);
          var now = ctx.currentTime;
          gain.gain.setValueAtTime(0.08, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + $duration);
          osc.start();
          osc.stop(now + $duration);
        } catch(e) {}
      })()
      '''
    ]);
  } catch (_) {}
}

void _coachPlaySuccessChime() {
  _coachPlayTone(frequency: 523.25, duration: 0.1); // C5
  Future.delayed(const Duration(milliseconds: 100), () {
    _coachPlayTone(frequency: 659.25, duration: 0.1); // E5
  });
  Future.delayed(const Duration(milliseconds: 200), () {
    _coachPlayTone(frequency: 783.99, duration: 0.22); // G5
  });
}

void _coachPlayCelebrationFanfare() {
  _coachPlayTone(frequency: 587.33, duration: 0.1); // D5
  Future.delayed(const Duration(milliseconds: 120), () {
    _coachPlayTone(frequency: 739.99, duration: 0.12); // F#5
  });
  Future.delayed(const Duration(milliseconds: 240), () {
    _coachPlayTone(frequency: 880.00, duration: 0.35); // A5
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Web Speech Recognition Interop
// ──────────────────────────────────────────────────────────────────────────────

html.SpeechRecognition? _coachActiveRecognition;

void _coachEnsureSpeechScriptInjected() {
  if (!kIsWeb) return;
  try {
    if (js.context['__vernexaCoachSpeech'] == null) {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = r'''
window.__vernexaCoachSpeech = {
  recognition: null,
  isRecording: false,
  start: function(lang, onResult, onError, onEnd) {
    var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRec) {
      if (onError) onError('Speech recognition not supported in this browser. Please use Chrome or Edge.');
      if (onEnd) onEnd();
      return;
    }
    if (this.recognition) {
      try { this.recognition.abort(); } catch(e) {}
      this.recognition = null;
    }
    try {
      var rec = new SpeechRec();
      this.recognition = rec;
      this.isRecording = true;
      rec.continuous = true;
      rec.interimResults = true;
      rec.lang = lang || 'hi-IN';

      rec.onresult = function(event) {
        var full = '';
        for (var i = 0; i < event.results.length; i++) {
          var seg = event.results[i];
          if (seg && seg.length > 0) {
            full += seg[0].transcript;
          }
        }
        var clean = full.trim();
        if (clean.length > 0 && onResult) {
          onResult(clean);
        }
      };

      rec.onerror = function(event) {
        var err = event.error || '';
        if (err === 'no-speech' || err === 'aborted') return;
        if (err === 'not-allowed') {
          if (onError) onError('Microphone permission denied. Please allow microphone access in your browser bar.');
        } else {
          if (onError) onError('Microphone notice: ' + err);
        }
        if (onEnd) onEnd();
      };

      rec.onend = function() {
        if (onEnd) onEnd();
      };

      rec.start();
    } catch(e) {
      if (onError) onError('Microphone error: ' + e);
      if (onEnd) onEnd();
    }
  },
  stop: function() {
    this.isRecording = false;
    if (this.recognition) {
      try { this.recognition.stop(); } catch(e) {}
      this.recognition = null;
    }
  }
};
''';
      html.document.head?.append(script);
    }
  } catch (_) {}
}

void _coachStartSpeechRecognition({
  required String langCode,
  required void Function(String) onInterim,
  required void Function(String) onFinal,
  required void Function(String) onError,
  required void Function() onEnd,
}) {
  _coachEnsureSpeechScriptInjected();
  try {
    final speechObj = js.context['__vernexaCoachSpeech'];
    if (speechObj != null) {
      speechObj.callMethod('start', [
        langCode,
        (result) {
          final text = result.toString();
          onInterim(text);
          onFinal(text);
        },
        (err) {
          onError(err.toString());
        },
        () {
          onEnd();
        },
      ]);
      return;
    }
  } catch (_) {}

  // Fallback to direct Dart html.SpeechRecognition
  try {
    _coachActiveRecognition?.abort();
    final rec = html.SpeechRecognition();
    _coachActiveRecognition = rec;
    rec.continuous = true;
    rec.interimResults = true;
    rec.lang = langCode;

    rec.onResult.listen((event) {
      final results = event.results;
      if (results != null && results.isNotEmpty) {
        final last = results[results.length - 1];
        final text = last.item(0).transcript ?? '';
        final isFinal = last.isFinal ?? false;
        if (isFinal) {
          onFinal(text);
        } else {
          onInterim(text);
        }
      }
    });

    rec.onError.listen((event) {
      onError('Audio input notice: ${event.type}');
      onEnd();
    });

    rec.onEnd.listen((_) => onEnd());
    rec.start();
  } catch (e) {
    onError('Unable to open microphone: $e');
    onEnd();
  }
}

void _coachStopSpeechRecognition() {
  try {
    final speechObj = js.context['__vernexaCoachSpeech'];
    if (speechObj != null) {
      speechObj.callMethod('stop');
    }
  } catch (_) {}
  try {
    _coachActiveRecognition?.stop();
    _coachActiveRecognition = null;
  } catch (_) {}
}

// ──────────────────────────────────────────────────────────────────────────────
// SpeechSynthesis Audio Engine for Tribal Phonetics
// ──────────────────────────────────────────────────────────────────────────────

List<html.SpeechSynthesisVoice> _coachCachedVoices = [];

void _coachInitBrowserVoices() {
  if (!kIsWeb) return;
  try {
    final synth = html.window.speechSynthesis;
    if (synth != null) {
      if (_coachCachedVoices.isEmpty) {
        _coachCachedVoices = synth.getVoices();
      }
      synth.addEventListener('voiceschanged', (_) {
        _coachCachedVoices = synth.getVoices();
      });
    }
  } catch (_) {}
}

void _coachSpeakText({
  required String text,
  required String langName,
  String phoneticGuide = '',
  double rate = 1.0,
  void Function()? onStarted,
  void Function()? onFinished,
}) {
  if (!kIsWeb) {
    onFinished?.call();
    return;
  }
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      onFinished?.call();
      return;
    }

    _coachInitBrowserVoices();
    synth.cancel();
    synth.resume();

    final hasOlChiki = RegExp(r'[\u1C50-\u1C7F]').hasMatch(text);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);

    final voices = _coachCachedVoices.isNotEmpty ? _coachCachedVoices : synth.getVoices();
    final hasHindiVoice = voices.any((v) =>
        (v.lang ?? '').toLowerCase().startsWith('hi') ||
        (v.name ?? '').toLowerCase().contains('hindi') ||
        (v.name ?? '').toLowerCase().contains('lekha'));

    String toSpeak = text;
    String targetLangCode = 'en-US';

    if (langName == 'English') {
      toSpeak = text;
      targetLangCode = 'en-US';
    } else if (langName == 'Hindi') {
      toSpeak = text;
      targetLangCode = 'hi-IN';
    } else if (hasOlChiki || langName == 'Santali') {
      if (phoneticGuide.trim().isNotEmpty && !RegExp(r'[\u1C50-\u1C7F]').hasMatch(phoneticGuide)) {
        toSpeak = phoneticGuide.trim();
      } else {
        toSpeak = olChikiToPhonetic(text.isNotEmpty ? text : phoneticGuide);
      }
      targetLangCode = 'en-IN';
    } else {
      // Mundari, Ho, Kurukh, Gondi
      if (hasHindiVoice && hasDevanagari) {
        toSpeak = text.replaceAll(':', 'ह').replaceAll('ः', 'ह');
        targetLangCode = 'hi-IN';
      } else if (phoneticGuide.trim().isNotEmpty && !RegExp(r'[\u0900-\u097F]').hasMatch(phoneticGuide)) {
        toSpeak = phoneticGuide.trim();
        targetLangCode = 'en-IN';
      } else if (langName == 'Ho') {
        toSpeak = hoToPhonetic(text);
        targetLangCode = 'en-IN';
      } else if (hasDevanagari) {
        toSpeak = devanagariToPhonetic(text);
        targetLangCode = 'en-IN';
      } else {
        toSpeak = text;
        targetLangCode = 'hi-IN';
      }
    }

    toSpeak = toSpeak
        .replaceAll(':', 'h')
        .replaceAll('ः', 'h')
        .replaceAll(RegExp(r'[।॥|]'), '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (toSpeak.isEmpty) {
      onFinished?.call();
      return;
    }

    final utterance = html.SpeechSynthesisUtterance(toSpeak);
    utterance.rate = rate;
    utterance.volume = 1.0;
    utterance.pitch = 1.0;
    utterance.lang = targetLangCode;

    if (voices.isNotEmpty) {
      final voice = voices.firstWhere(
        (v) {
          final l = (v.lang ?? '').toLowerCase();
          final n = (v.name ?? '').toLowerCase();
          if (utterance.lang == 'hi-IN') {
            return l.startsWith('hi') || n.contains('hindi') || n.contains('lekha');
          }
          if (utterance.lang == 'en-IN') {
            return l == 'en-in' || n.contains('india') || n.contains('indian') || n.contains('rishi') || n.contains('veena');
          }
          if (utterance.lang == 'en-US') {
            return l == 'en-us' || n.contains('united states') || n.contains('samantha') || n.contains('google');
          }
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
  } catch (_) {
    onFinished?.call();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Data Models: CoachPhrase, PracticeAttempt, RoleplayScenario
// ──────────────────────────────────────────────────────────────────────────────

class CoachPhrase {
  final String id;
  final String category;
  final String english;
  final String hindi;
  final Map<String, String> translations;
  final Map<String, String> phonetics;
  final String linguisticTip;

  const CoachPhrase({
    required this.id,
    required this.category,
    required this.english,
    required this.hindi,
    required this.translations,
    required this.phonetics,
    required this.linguisticTip,
  });

  String getTranslation(String lang) {
    return translations[lang] ?? translations['Mundari'] ?? hindi;
  }

  String getPhonetic(String lang) {
    return phonetics[lang] ?? translations[lang] ?? english;
  }
}

class PracticeAttempt {
  final String id;
  final String phraseId;
  final String english;
  final String targetPhrase;
  final String targetPhonetic;
  final String spokenText;
  final int accuracyScore;
  final String feedback;
  final List<Map<String, dynamic>> wordAnalysis;
  final DateTime timestamp;
  final String language;

  PracticeAttempt({
    required this.id,
    required this.phraseId,
    required this.english,
    required this.targetPhrase,
    required this.targetPhonetic,
    required this.spokenText,
    required this.accuracyScore,
    required this.feedback,
    required this.wordAnalysis,
    required this.timestamp,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'phraseId': phraseId,
        'english': english,
        'targetPhrase': targetPhrase,
        'targetPhonetic': targetPhonetic,
        'spokenText': spokenText,
        'accuracyScore': accuracyScore,
        'feedback': feedback,
        'timestamp': timestamp.toIso8601String(),
        'language': language,
      };

  factory PracticeAttempt.fromJson(Map<String, dynamic> json) {
    return PracticeAttempt(
      id: json['id'] ?? '',
      phraseId: json['phraseId'] ?? '',
      english: json['english'] ?? '',
      targetPhrase: json['targetPhrase'] ?? '',
      targetPhonetic: json['targetPhonetic'] ?? '',
      spokenText: json['spokenText'] ?? '',
      accuracyScore: json['accuracyScore'] ?? 0,
      feedback: json['feedback'] ?? '',
      wordAnalysis: [],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      language: json['language'] ?? 'Mundari',
    );
  }
}

class RoleplayScenario {
  final String id;
  final String title;
  final String category;
  final String context;
  final String studentSpokenEnglish;
  final Map<String, String> studentDialogue;
  final Map<String, String> studentPhonetic;
  final String teacherPromptEnglish;
  final String teacherPromptHindi;
  final Map<String, String> targetResponse;
  final Map<String, String> targetResponsePhonetic;
  final String culturalNote;

  const RoleplayScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.context,
    required this.studentSpokenEnglish,
    required this.studentDialogue,
    required this.studentPhonetic,
    required this.teacherPromptEnglish,
    required this.teacherPromptHindi,
    required this.targetResponse,
    required this.targetResponsePhonetic,
    required this.culturalNote,
  });

  String getStudentDialogue(String lang) => studentDialogue[lang] ?? studentDialogue['Mundari'] ?? '';
  String getStudentPhonetic(String lang) => studentPhonetic[lang] ?? studentDialogue[lang] ?? '';
  String getTargetResponse(String lang) => targetResponse[lang] ?? targetResponse['Mundari'] ?? '';
  String getTargetResponsePhonetic(String lang) => targetResponsePhonetic[lang] ?? targetResponse[lang] ?? '';
}

// ──────────────────────────────────────────────────────────────────────────────
// Comprehensive Curated Curriculum Database (Authentic Tribal Phrases)
// ──────────────────────────────────────────────────────────────────────────────

final List<CoachPhrase> _coachCurriculum = [
  // ── Greetings & Assembly ──
  const CoachPhrase(
    id: 'p_greet_01',
    category: 'Greetings',
    english: 'Hello children, how are you all?',
    hindi: 'नमस्ते बच्चों, आप सब कैसे हैं?',
    translations: {
      'Mundari': 'जोहार गड़ाको, आपे चिलके मेनापेया?',
      'Santali': 'ᱡᱚᱦᱟᱨ ᱜᱤᱫᱽᱨᱟᱹ, ᱟᱯᱮ ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱯᱮᱭᱟ?',
      'Ho': 'जोहार होनको, आपे चिलके मेनापेया?',
      'Kurukh': 'जोहार तंगड़ाको, नीम एकाने रईत?',
      'Gondi': 'जय जोहार पिलाक, मीर बोर आंदित?',
    },
    phonetics: {
      'Mundari': 'Jo-har ga-da-ko, a-pe chil-ke me-na-pe-ya?',
      'Santali': 'Jo-har gid-ra, a-pe ched le-ka me-nag pe-ya?',
      'Ho': 'Jo-har hon-ko, a-pe chil-ke me-na-pe-ya?',
      'Kurukh': 'Jo-har tang-da-ko, neem e-ka-ne ra-eet?',
      'Gondi': 'Jai Jo-har pi-lak, meer bor aan-deet?',
    },
    linguisticTip: 'In Santali and Mundari, "Johar" is the respectful universal greeting with both hands folded.',
  ),
  const CoachPhrase(
    id: 'p_greet_02',
    category: 'Greetings',
    english: 'Welcome to our classroom today!',
    hindi: 'हमारी कक्षा में आप सभी का स्वागत है!',
    translations: {
      'Mundari': 'अबूवा ओड़ाः रे आपेया सुकु ते जोहार!',
      'Santali': 'ᱟᱵᱚᱣᱟᱜ ᱪᱟᱱᱟᱪ ᱨᱮ ᱟᱯᱮ ᱡᱚᱛᱚ ᱦᱚᱲᱟᱜ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ!',
      'Ho': 'अबूवा क्लॉस रे आपे सनामको सुकु ते जोहार!',
      'Kurukh': 'एमहै ओड़्हा नू नीमहा जोहार!',
      'Gondi': 'मावा शाला ते मीक जोहार!',
    },
    phonetics: {
      'Mundari': 'A-bu-wa o-dah re a-pe-ya su-ku te jo-har!',
      'Santali': 'A-bo-wag cha-nach re a-pe jo-to ho-dag sa-gun da-ram!',
      'Ho': 'A-bu-wa class re a-pe sa-nam-ko su-ku te jo-har!',
      'Kurukh': 'Em-hai od-ha nu neem-ha jo-har!',
      'Gondi': 'Ma-wa sha-la te meek jo-har!',
    },
    linguisticTip: 'Santali "Sagun Daram" (ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ) is the traditional welcoming honor expression.',
  ),
  const CoachPhrase(
    id: 'p_greet_03',
    category: 'Greetings',
    english: 'Are you all ready to learn today?',
    hindi: 'क्या आप सब आज नया सीखने के लिए तैयार हैं?',
    translations: {
      'Mundari': 'आपे तिशिंग इतुवन् लागड़ तैयार मेनापेया चि?',
      'Santali': 'ᱛᱮᱦᱮᱧ ᱪᱮᱫᱚᱜ ᱞᱟᱹᱜᱤᱫ ᱟᱯᱮ ᱥᱟᱯᱲᱟᱣ ᱢᱮᱱᱟᱜ ᱯᱮᱭᱟ ᱥᱮ?',
      'Ho': 'आपे तिशिंग नवां जिनिस सेखे लागड़ तैयार मेनापेया?',
      'Kurukh': 'नीम इनना नन्ना सिखए तैयार रईत का?',
      'Gondi': 'मीर नेंड पुना कल्ले लेस्तित बा?',
    },
    phonetics: {
      'Mundari': 'A-pe ti-shing i-tu-wan la-gad tai-yar me-na-pe-ya chi?',
      'Santali': 'Te-heng che-dog la-gid a-pe sap-daw me-nag pe-ya se?',
      'Ho': 'A-pe ti-shing na-wan ji-nis se-khe la-gad tai-yar me-na-pe-ya?',
      'Kurukh': 'Neem in-na nan-na si-kha-e tai-yar ra-eet ka?',
      'Gondi': 'Meer nend pu-na kal-le les-teet ba?',
    },
    linguisticTip: 'Ending question particles "चि" (Mundari) and "ᱥᱮ" (Santali) turn sentences into warm inquiries.',
  ),

  // ── Classroom Instructions ──
  const CoachPhrase(
    id: 'p_inst_01',
    category: 'Classroom Instructions',
    english: 'Children, please sit down in your places.',
    hindi: 'बच्चों, कृपया अपनी-अपनी जगह पर बैठ जाओ।',
    translations: {
      'Mundari': 'गड़ाको, आपना-आपना जायगा रे दुबुपे।',
      'Santali': 'ᱜᱤᱫᱽᱨᱟᱹ, ᱟᱯᱱᱟᱨ ᱴᱷᱟᱶ ᱨᱮ ᱫᱩᱲᱩᱵ ᱯᱮ᱾',
      'Ho': 'होनको, आपना-आपना जागा रे दुबुपे।',
      'Kurukh': 'तंगड़ाको, तमहै अड़का नू ओक्का।',
      'Gondi': 'पिलाक, मीवा जागा ते उदट।',
    },
    phonetics: {
      'Mundari': 'Ga-da-ko, aap-na aap-na jay-ga re du-bu-pe.',
      'Santali': 'Gid-ra, aap-nar thawn re du-rub pe.',
      'Ho': 'Hon-ko, aap-na aap-na ja-ga re du-bu-pe.',
      'Kurukh': 'Tang-da-ko, tam-hai ad-ka nu ok-ka.',
      'Gondi': 'Pi-lak, mee-wa ja-ga te oo-dat.',
    },
    linguisticTip: 'Notice the plural imperative suffix "-pe" (दुबुपे / ᱫᱩᱲᱩᱵ ᱯᱮ) addressing the whole classroom politely.',
  ),
  const CoachPhrase(
    id: 'p_inst_02',
    category: 'Classroom Instructions',
    english: 'Open your books to page five.',
    hindi: 'अपनी किताब का पृष्ठ पाँच खोलो।',
    translations: {
      'Mundari': 'पुथी मोणोय साकाम रे ओलोपे।',
      'Santali': 'ᱯᱚᱛᱚᱵ ᱨᱮᱱᱟᱜ ᱢᱚᱬᱮ ᱥᱟᱠᱟᱢ ᱡᱷᱤᱡᱽ ᱯᱮ᱾',
      'Ho': 'पुथी मोणोया साकम रे खोलके नेलेपे।',
      'Kurukh': 'पुथी पांच साकम नू उघरा।',
      'Gondi': 'पुस्तकम सयुं पन्ना नीहुट।',
    },
    phonetics: {
      'Mundari': 'Pu-thi mo-noy sa-kam re o-lo-pe.',
      'Santali': 'Po-tob re-nag mo-ne sa-kam jhij pe.',
      'Ho': 'Pu-thi mo-no-ya sa-kam re khol-ke ne-le-pe.',
      'Kurukh': 'Pu-thi panch sa-kam nu ugh-ra.',
      'Gondi': 'Pus-ta-kam sa-yung pan-na nee-hoot.',
    },
    linguisticTip: 'In Santali "Potob" means book and "jhij pe" (ᱡᱷᱤᱡᱽ ᱯᱮ) means "open".',
  ),
  const CoachPhrase(
    id: 'p_inst_03',
    category: 'Classroom Instructions',
    english: 'Look at the blackboard carefully.',
    hindi: 'सभी बच्चे ध्यान से ब्लैकबोर्ड पर देखें।',
    translations: {
      'Mundari': 'सनामको धेयान ते ब्लैकबोर्ड रे नेलेपे।',
      'Santali': 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱵᱽᱞᱮᱠᱵᱚᱨᱰ ᱨᱮ ᱠᱚᱭᱚᱜᱽ ᱯᱮ᱾',
      'Ho': 'सनामको सुकुर ते बोर्ड रे नेलेपे।',
      'Kurukh': 'हूर्मर बोर्ड तरा ध्यान ती एरा।',
      'Gondi': 'सब्बोर बोर्ड गाडे ध्यान ते चूड़ट।',
    },
    phonetics: {
      'Mundari': 'Sa-nam-ko dhe-yan te board re ne-le-pe.',
      'Santali': 'Jo-to hod dhe-yan te board re ko-yog pe.',
      'Ho': 'Sa-nam-ko su-kur te board re ne-le-pe.',
      'Kurukh': 'Hoor-mar board ta-ra dhyan tee e-ra.',
      'Gondi': 'Sab-bor board ga-de dhyan te choo-dat.',
    },
    linguisticTip: '"Koyog pe" (ᱠᱚᱭᱚᱜᱽ ᱯᱮ) implies focused visual attention upward toward the board.',
  ),
  const CoachPhrase(
    id: 'p_inst_04',
    category: 'Classroom Instructions',
    english: 'Listen quietly to what the teacher says.',
    hindi: 'शांति से शिक्षक की बात सुनो।',
    translations: {
      'Mundari': 'माचेत-आः कजी सुकुर ते आयमपे।',
      'Santali': 'ᱢᱟᱪᱮᱛ ᱟᱜ ᱠᱟᱛᱷᱟ ᱱᱤᱨᱚᱲ ᱛᱮ ᱟᱧᱡᱚᱢ ᱯᱮ᱾',
      'Ho': 'गुरुजी-आः कजी स्थिर ते आयमपे।',
      'Kurukh': 'माचेत गही कत्थन मिना।',
      'Gondi': 'गुरुना रोना शांत ते केंजात।',
    },
    phonetics: {
      'Mundari': 'Ma-chet-ah ka-ji su-kur te aa-yum-pe.',
      'Santali': 'Ma-chet ag ka-tha ni-rod te aan-jom pe.',
      'Ho': 'Gu-ru-ji-ah ka-ji sthir te aa-yum-pe.',
      'Kurukh': 'Ma-chet ga-hee kat-than mee-na.',
      'Gondi': 'Gu-ru-na ro-na shant te ken-jaat.',
    },
    linguisticTip: '"Aanjom pe" (ᱟᱧᱡᱚᱢ ᱯᱮ) in Santali and "Aayumpe" in Mundari mean "listen attentively".',
  ),
  const CoachPhrase(
    id: 'p_inst_05',
    category: 'Classroom Instructions',
    english: 'Raise your hand if you know the answer.',
    hindi: 'यदि उत्तर पता है तो अपना हाथ ऊपर उठाओ।',
    translations: {
      'Mundari': 'काजी बाड़ा ते ती चोत रे तुलेपे।',
      'Santali': 'ᱛᱮᱞᱟ ᱵᱟᱰᱟᱭ ᱠᱷᱟᱱ ᱛᱤ ᱛᱩᱞ ᱯᱮ᱾',
      'Ho': 'उत्तर बाड़ा रे ती चोत रे तुलेपे।',
      'Kurukh': 'उत्तर अक्खा का ती तुल्ला।',
      'Gondi': 'जवाब पुत्तक की कय तेजाट।',
    },
    phonetics: {
      'Mundari': 'Ka-ji ba-da te tee chot re tu-le-pe.',
      'Santali': 'Te-la ba-day khan tee tul pe.',
      'Ho': 'Ut-tar ba-da re tee chot re tu-le-pe.',
      'Kurukh': 'Ut-tar ak-kha ka tee tul-la.',
      'Gondi': 'Ja-wab put-tak kee kay te-jaat.',
    },
    linguisticTip: '"Ti tul pe" (ᱛᱤ ᱛᱩᱞ ᱯᱮ) literally means "raise hands" in Austroasiatic tribal languages.',
  ),

  // ── Praise & Encouragement ──
  const CoachPhrase(
    id: 'p_praise_01',
    category: 'Praise & Encouragement',
    english: 'Very good! Excellent effort!',
    hindi: 'बहुत अच्छा! बहुत बढ़िया प्रयास!',
    translations: {
      'Mundari': 'एनांग पुर सुकु! बोगते मेनाः!',
      'Santali': 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱟᱹᱰᱤ ᱵᱮᱥ ᱠᱟᱹᱢᱤ!',
      'Ho': 'पुर सुकु! बहुत बेस काम!',
      'Kurukh': 'अक्का बेस! कोडे काम!',
      'Gondi': 'चोकोट! बोर चोकोट!',
    },
    phonetics: {
      'Mundari': 'E-nang pur su-ku! Bog-te me-nah!',
      'Santali': 'A-di na-pay! A-di bes ka-mi!',
      'Ho': 'Pur su-ku! Ba-hut bes kam!',
      'Kurukh': 'Ak-ka bes! Ko-de kam!',
      'Gondi': 'Cho-kot! Bor cho-kot!',
    },
    linguisticTip: '"Adi napay" (ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ) creates immediate emotional warmth and encouragement for tribal kids.',
  ),
  const CoachPhrase(
    id: 'p_praise_02',
    category: 'Praise & Encouragement',
    english: 'That is the correct answer, wonderful!',
    hindi: 'यह बिल्कुल सही उत्तर है, बहुत बढ़िया!',
    translations: {
      'Mundari': 'नेया एकदम सोझे काजी, बोगते!',
      'Santali': 'ᱱᱚᱣᱟ ᱫᱚ ᱴᱷᱤᱠ ᱛᱮᱞᱟ ᱠᱟᱱᱟ, ᱥᱟᱹᱨᱤ ᱜᱮ ᱱᱟᱯᱟᱭ!',
      'Ho': 'नेया सीधा कजी, बहुत बोगते!',
      'Kurukh': 'ई ठुक उत्तर रई, बेस!',
      'Gondi': 'इदी खरे जवाब, बेस!',
    },
    phonetics: {
      'Mundari': 'Ne-ya ek-dam so-jhe ka-ji, bog-te!',
      'Santali': 'No-wa do theek te-la ka-na, sa-ri ge na-pay!',
      'Ho': 'Ne-ya see-dha ka-ji, ba-hut bog-te!',
      'Kurukh': 'Ee thuk ut-tar ra-ee, bes!',
      'Gondi': 'I-dee kha-re ja-wab, bes!',
    },
    linguisticTip: '"Theek tela kana" (ᱴᱷᱤᱠ ᱛᱮᱞᱟ ᱠᱟᱱᱟ) confirms correctness with affirming clarity.',
  ),
  const CoachPhrase(
    id: 'p_praise_03',
    category: 'Praise & Encouragement',
    english: 'You worked so hard today, keep it up!',
    hindi: 'आज तुमने बहुत मेहनत की है, ऐसे ही आगे बढ़ो!',
    translations: {
      'Mundari': 'तिशिंग पुर मेहनत केदा, एनलेका गे सेनोपे!',
      'Santali': 'ᱛᱮᱦᱮᱧ ᱟᱹᱰᱤ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱠᱮᱫᱟᱢ, ᱱᱚᱝᱠᱟ ᱜᱮ ᱞᱟᱦᱟᱜ ᱢᱮ!',
      'Ho': 'तिशिंग पुर मेहनत केदाम, एनलेका गे चलावमे!',
      'Kurukh': 'इनना कोडे मेहनत कमका, अन्ने अगे तरा कालो!',
      'Gondi': 'नेंड खूब मेहनत कीतीत, इहने मुन्ने हन!',
    },
    phonetics: {
      'Mundari': 'Ti-shing pur meh-nat ke-da, en-le-ka ge se-no-pe!',
      'Santali': 'Te-heng a-di ku-ru-mu-tu ke-dam, nong-ka ge la-hag me!',
      'Ho': 'Ti-shing pur meh-nat ke-dam, en-le-ka ge cha-law-me!',
      'Kurukh': 'In-na ko-de meh-nat kam-ka, an-ne a-ge ta-ra ka-lo!',
      'Gondi': 'Nend khoob meh-nat kee-teet, ih-ne mun-ne han!',
    },
    linguisticTip: 'Santali "Kurumutu" (ᱠᱩᱨᱩᱢᱩᱴᱩ) denotes earnest, persistent hard work and learning grit.',
  ),

  // ── Questions & Comprehension ──
  const CoachPhrase(
    id: 'p_quest_01',
    category: 'Questions',
    english: 'Did everyone understand this lesson?',
    hindi: 'क्या सभी बच्चों को यह बात समझ में आई?',
    translations: {
      'Mundari': 'सनामको ने कजी बुझवकेना चि?',
      'Santali': 'ᱡᱚᱛᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱱᱚᱣᱟ ᱠᱟᱛᱷᱟ ᱵᱩᱡᱷᱟᱹᱣ ᱧᱟᱢ ᱠᱮᱫᱟ ᱯᱮ ᱥᱮ?',
      'Ho': 'सनाम होनको ने कजी बुझवकेना?',
      'Kurukh': 'हूर्मर ई कत्थन बुझरकार का?',
      'Gondi': 'सब्बोर इद कत्तुन समजतीत बा?',
    },
    phonetics: {
      'Mundari': 'Sa-nam-ko ne ka-ji buj-haw-ke-na chi?',
      'Santali': 'Jo-to gid-ra no-wa ka-tha buj-haw nyam ke-da pe se?',
      'Ho': 'Sa-nam hon-ko ne ka-ji buj-haw-ke-na?',
      'Kurukh': 'Hoor-mar ee kat-than buj-har-kar ka?',
      'Gondi': 'Sab-bor eed kat-tun sa-maj-teet ba?',
    },
    linguisticTip: 'Watch for affirmative student nods: in Santali, students often respond with "Hẽ" (ᱦᱮᱸ) for Yes.',
  ),
  const CoachPhrase(
    id: 'p_quest_02',
    category: 'Questions',
    english: 'Who wants to answer this question?',
    hindi: 'इस सवाल का उत्तर कौन देना चाहता है?',
    translations: {
      'Mundari': 'ओकोए ने कजी-आः उत्तर ओमे सनेया?',
      'Santali': 'ᱱᱚᱣᱟ ᱠᱩᱠᱞᱤ ᱨᱮᱱᱟᱜ ᱛᱮᱞᱟ ᱚᱠᱚᱭ ᱮᱢ ᱥᱟᱱᱟᱭᱮᱫ ᱯᱮᱭᱟ?',
      'Ho': 'ओकोए ने कजी-आः उत्तर ओमे मनेया?',
      'Kurukh': 'ई सवाल गही उत्तर ने चिआ खोजी?',
      'Gondi': 'इद सवाल ता जवाब बोर सीयंदूर?',
    },
    phonetics: {
      'Mundari': 'O-ko-e ne ka-ji-ah ut-tar o-me sa-ne-ya?',
      'Santali': 'No-wa kuk-li re-nag te-la o-koy em sa-na-yed pe-ya?',
      'Ho': 'O-ko-e ne ka-ji-ah ut-tar o-me ma-ne-ya?',
      'Kurukh': 'Ee sa-wal ga-hee ut-tar ne chi-a kho-jee?',
      'Gondi': 'Eed sa-wal ta ja-wab bor see-yan-door?',
    },
    linguisticTip: '"Kukli" (ᱠᱩᱠᱞᱤ) is question and "Tela" (ᱛᱮᱞᱟ) is answer.',
  ),
  const CoachPhrase(
    id: 'p_quest_03',
    category: 'Questions',
    english: 'Where is your pencil and notebook?',
    hindi: 'तुम्हारी पेंसिल और कॉपी कहाँ है?',
    translations: {
      'Mundari': 'अम-आः पेंसिल ओन्दो कॉपी ओकोएता मेनाः?',
      'Santali': 'ᱟᱢᱟᱜ ᱯᱮᱱᱥᱤᱞ ᱟᱨ ᱠᱷᱟᱛᱟ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ?',
      'Ho': 'अम-आः पेंसिल ओन्दो खाता ओकोरे मेनाः?',
      'Kurukh': 'निंघै पेंसिल अरा कॉपी एकसन रई?',
      'Gondi': 'नीवा पेंसिल अन कापी बगा मंता?',
    },
    phonetics: {
      'Mundari': 'Am-ah pen-sil on-do co-py o-ko-e-ta me-nah?',
      'Santali': 'A-mag pen-sil aar kha-ta o-ka-re me-nag-a?',
      'Ho': 'Am-ah pen-sil on-do kha-ta o-ko-re me-nah?',
      'Kurukh': 'Ning-hai pen-sil a-ra co-py ek-san ra-ee?',
      'Gondi': 'Nee-wa pen-sil an ka-pi ba-ga man-ta?',
    },
    linguisticTip: 'In Santali, "Okare menag-a" (ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ) means "Where is it located?".',
  ),

  // ── Numbers 1 to 10 ──
  const CoachPhrase(
    id: 'p_num_01',
    category: 'Numbers 1-10',
    english: 'One, Two, Three, Four, Five',
    hindi: 'एक, दो, तीन, चार, पाँच',
    translations: {
      'Mundari': 'मियद, बारिया, आपिया, उपुन, मोणोय',
      'Santali': 'ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱩᱱ, ᱢᱚᱬᱮ',
      'Ho': 'मियद, बारिया, आपेया, उपुन, मोणोया',
      'Kurukh': 'ओन्द, एन्द, मून्द, नाख, पांच',
      'Gondi': 'उंदी, रंद, मूंद, नालुंग, सयुं',
    },
    phonetics: {
      'Mundari': 'Mi-yad, Ba-ri-ya, Aa-pi-ya, U-pun, Mo-noy',
      'Santali': 'Mid, Bar, Pe, Pun, Mo-ne',
      'Ho': 'Mi-yad, Ba-ri-ya, Aa-pe-ya, U-pun, Mo-no-ya',
      'Kurukh': 'Ond, End, Moond, Naakh, Panch',
      'Gondi': 'Oon-dee, Rand, Moond, Naa-loong, Sa-yoong',
    },
    linguisticTip: 'Practice rhythmically: Mid (1), Bar (2), Pe (3), Pun (4), Mone (5) with finger counting.',
  ),
  const CoachPhrase(
    id: 'p_num_02',
    category: 'Numbers 1-10',
    english: 'Six, Seven, Eight, Nine, Ten',
    hindi: 'छह, सात, आठ, नौ, दस',
    translations: {
      'Mundari': 'तुरूय, एया, इरिल, आरे, गेले',
      'Santali': 'ᱛᱩᱨᱩᱭ, ᱮᱭᱟᱭ, ᱤᱨᱟᱹᱞ, ᱟᱨᱮ, ᱜᱮᱞ',
      'Ho': 'तुरूया, एया, इरिया, आरेया, गेले',
      'Kurukh': 'सोये, सात, आठ, नौ, दस',
      'Gondi': 'सारूंग, येडूंग, एण्मूद, नरके, पद',
    },
    phonetics: {
      'Mundari': 'Tu-rui, E-ya, I-ril, Aa-re, Ge-le',
      'Santali': 'Tu-rui, E-a-yay, I-ral, Aa-re, Gel',
      'Ho': 'Tu-ru-ya, E-ya, I-ri-ya, Aa-re-ya, Ge-le',
      'Kurukh': 'So-ye, Saat, Aath, Nau, Das',
      'Gondi': 'Saa-roong, Ye-doong, En-mood, Nar-ke, Pad',
    },
    linguisticTip: 'In Santali, "Gel" (ᱜᱮᱞ) is 10, foundational for all higher dual and decimal counting.',
  ),

  // ── Daily Care, Hygiene & Meals ──
  const CoachPhrase(
    id: 'p_care_01',
    category: 'Daily Care & Meals',
    english: 'Wash your hands with soap before eating food.',
    hindi: 'भोजन करने से पहले साबुन से हाथ धो लो।',
    translations: {
      'Mundari': 'मंडी जोम सिदारे साबुन ते ती फाड़चाएपे।',
      'Santali': 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱟᱲᱟᱝ ᱨᱮ ᱥᱟᱵᱚᱱ ᱛᱮ ᱛᱤ ᱟᱹᱨᱩᱵ ᱯᱮ᱾',
      'Ho': 'मंडी जोम सिदारे साबुन ते ती अभपे।',
      'Kurukh': 'मंडी ओंन्ना मुन्दे साबुन ती खयखल नोड़ा।',
      'Gondi': 'गाटो तिनना मुन्ने साबुन ते कय नूड़ाट।',
    },
    phonetics: {
      'Mundari': 'Man-di jom si-da-re sa-bun te tee fad-cha-e-pe.',
      'Santali': 'Da-ka jom ma-dang re sa-bon te tee aa-rub pe.',
      'Ho': 'Man-di jom si-da-re sa-bun te tee abh-pe.',
      'Kurukh': 'Man-di on-na mun-de sa-bun tee khay-khal no-da.',
      'Gondi': 'Gaa-to tin-na mun-ne sa-bun te kay noo-daat.',
    },
    linguisticTip: 'Santali "Daka" (ᱫᱟᱠᱟ) means rice/meal, and "ti arup pe" (ᱛᱤ ᱟᱹᱨᱩᱵ ᱯᱮ) means "wash hands".',
  ),
  const CoachPhrase(
    id: 'p_care_02',
    category: 'Daily Care & Meals',
    english: 'Drink clean drinking water.',
    hindi: 'साफ पीने का पानी पियो।',
    translations: {
      'Mundari': 'फाड़चा नु दाः नूएपे।',
      'Santali': 'ᱥᱟᱯᱷᱟ ᱧᱩ ᱫᱟᱜ ᱧᱩᱭ ᱯᱮ᱾',
      'Ho': 'फाड़चा नु दाः नूएपे।',
      'Kurukh': 'सफा ओंन्ना अम्म ओंना।',
      'Gondi': 'चोकोट उनना येर ऊटाट।',
    },
    phonetics: {
      'Mundari': 'Fad-cha nu daah noo-e-pe.',
      'Santali': 'Sa-pha nyu dag nyuy pe.',
      'Ho': 'Fad-cha nu daah noo-e-pe.',
      'Kurukh': 'Sa-fa on-na amm on-na.',
      'Gondi': 'Cho-kot oon-na yer oo-taat.',
    },
    linguisticTip: '"Dag" (ᱫᱟᱜ) in Santali or "Da:" (दाः) in Mundari/Ho is water with a short glottal check.',
  ),
  const CoachPhrase(
    id: 'p_care_03',
    category: 'Daily Care & Meals',
    english: 'Pack your books inside your school bag.',
    hindi: 'अपनी किताबें बस्ते में रख लो।',
    translations: {
      'Mundari': 'पुथीको आपना झोला रे दोएपे।',
      'Santali': 'ᱯᱚᱛᱚᱵ ᱠᱚ ᱟᱯᱱᱟᱨᱟᱜ ᱡᱷᱳᱞᱟ ᱨᱮ ᱥᱟᱢᱵᱟᱣ ᱯᱮ᱾',
      'Ho': 'पुथीको आपना झोला रे दोएपे।',
      'Kurukh': 'पुथीन तमहै झोला नू सारा।',
      'Gondi': 'किताबीन मीवा झोला ते वाटाट।',
    },
    phonetics: {
      'Mundari': 'Pu-thi-ko aap-na jho-la re do-e-pe.',
      'Santali': 'Po-tob ko aap-na-rag jho-la re sam-baw pe.',
      'Ho': 'Pu-thi-ko aap-na jho-la re do-e-pe.',
      'Kurukh': 'Pu-theen tam-hai jho-la nu saa-ra.',
      'Gondi': 'Ki-taa-been mee-wa jho-la te waa-taat.',
    },
    linguisticTip: 'Austroasiatic plural suffix "-ko" (ᱯᱚᱛᱚᱵ ᱠᱚ / पुथीको) indicates multiple books.',
  ),
  const CoachPhrase(
    id: 'p_care_04',
    category: 'Daily Care & Meals',
    english: 'See you tomorrow! Walk safely back home.',
    hindi: 'कल फिर मिलेंगे! सुरक्षित घर जाना।',
    translations: {
      'Mundari': 'गपा आरबू नेपेला! सुख ते ओड़ाः सेनोपे!',
      'Santali': 'ᱜᱟᱯᱟ ᱟᱨᱦᱚᱸ ᱵᱚ ᱧᱟᱯᱟᱢᱟ! ᱱᱟᱯᱟᱭ ᱛᱮ ᱚᱲᱟᱜ ᱪᱟᱞᱟᱣᱜ ᱯᱮ!',
      'Ho': 'गापा आरबू नेपेला! सुख ते ओड़ाः सेनोपे!',
      'Kurukh': 'नेला फेर मेलरओत! बेस ती एड़पा कालो!',
      'Gondi': 'नाडिया मल्ला कलीमट! चोकोट लोन हनट!',
    },
    phonetics: {
      'Mundari': 'Ga-pa aar-bu ne-pe-la! Sukh te o-dah se-no-pe!',
      'Santali': 'Ga-pa aar-hon bo nya-pa-ma! Na-pay te o-dag cha-lawg pe!',
      'Ho': 'Ga-pa aar-bu ne-pe-la! Sukh te o-dah se-no-pe!',
      'Kurukh': 'Ne-la pher me-la-ro-ot! Bes tee ed-pa ka-lo!',
      'Gondi': 'Naa-di-ya mal-la ka-lee-mat! Cho-kot lon ha-nat!',
    },
    linguisticTip: 'In Santali culture, one rarely says "goodbye" permanently; instead say "Gapa arhon bo nyapama" (we meet again tomorrow).',
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Roleplay Scenarios Database
// ──────────────────────────────────────────────────────────────────────────────

final List<RoleplayScenario> _coachScenarios = [
  const RoleplayScenario(
    id: 'scen_01',
    title: 'Morning Classroom Welcoming',
    category: 'Daily Routine',
    context: 'Children are running into the classroom on Monday morning, smiling and eager to see the teacher.',
    studentSpokenEnglish: 'Johar Guruji! What exciting lesson will we learn today?',
    studentDialogue: {
      'Mundari': 'जोहार गुरुजी! तिशिंग अबू चेद इतुवन्?',
      'Santali': 'ᱡᱚᱦᱟᱨ ᱢᱟᱪᱮᱛ! ᱛᱮᱦᱮᱧ ᱵᱚ ᱪᱮᱫ ᱵᱚ ᱪᱮᱫᱚᱜᱼᱟ?',
      'Ho': 'जोहार गुरुजी! तिशिंग अबू चेद पढ़व?',
      'Kurukh': 'जोहार माचेत! इनना एम चेद सीखओत?',
      'Gondi': 'जय जोहार गुरुजी! नेंड मम्मत बोर कल्ले?',
    },
    studentPhonetic: {
      'Mundari': 'Jo-har gu-ru-ji! Ti-shing a-bu ched i-tu-wan?',
      'Santali': 'Jo-har ma-chet! Te-heng bo ched bo che-dog-a?',
      'Ho': 'Jo-har gu-ru-ji! Ti-shing a-bu ched padh-av?',
      'Kurukh': 'Jo-har ma-chet! In-na em ched see-kha-ot?',
      'Gondi': 'Jai Jo-har gu-ru-jee! Nend mam-mat bor kal-le?',
    },
    teacherPromptEnglish: 'Greet them warmly: "Johar children, welcome! Today we will learn counting and stories."',
    teacherPromptHindi: 'गर्मजोशी से कहें: "जोहार बच्चों, स्वागत है! आज हम गिनती और कहानियाँ सीखेंगे।"',
    targetResponse: {
      'Mundari': 'जोहार गड़ाको! तिशिंग अबू गिनती ओन्दो काहनी इतुवा।',
      'Santali': 'ᱡᱚᱦᱟᱨ ᱜᱤᱫᱽᱨᱟᱹ! ᱛᱮᱦᱮᱧ ᱵᱚ ᱞᱮᱠᱷᱟ ᱟᱨ ᱠᱟᱹᱦᱱᱤ ᱵᱚ ᱪᱮᱫᱚᱜᱼᱟ᱾',
      'Ho': 'जोहार होनको! तिशिंग अबू गिनती ओन्दो कहानी सिखवा।',
      'Kurukh': 'जोहार तंगड़ाको! इनना एम लेखा अरा कहानी सिखओत।',
      'Gondi': 'जय जोहार पिलाक! नेंड मम्मत लेखा अन कहानी हेककाट।',
    },
    targetResponsePhonetic: {
      'Mundari': 'Jo-har ga-da-ko! Ti-shing a-bu gin-ti on-do kah-ni i-tu-wa.',
      'Santali': 'Jo-har gid-ra! Te-heng bo lek-ha aar kah-ni bo che-dog-a.',
      'Ho': 'Jo-har hon-ko! Ti-shing a-bu gin-ti on-do ka-ha-ni sikh-wa.',
      'Kurukh': 'Jo-har tang-da-ko! In-na em lek-ha a-ra ka-ha-nee see-kha-ot.',
      'Gondi': 'Jai Jo-har pi-lak! Nend mam-mat lek-ha an ka-ha-nee hek-kaat.',
    },
    culturalNote: 'Greeting with both hands raised and acknowledging "gidra / honko" builds instant trust and psychological safety.',
  ),
  const RoleplayScenario(
    id: 'scen_02',
    title: 'Morning Roll Call & Attendance',
    category: 'Classroom Management',
    context: 'The teacher calls out student Mangal Hembrom during morning attendance.',
    studentSpokenEnglish: 'Present Guruji! I am here in my seat.',
    studentDialogue: {
      'Mundari': 'मेनाइया गुरुजी! ऐं हिजुःकेना!',
      'Santali': 'ᱢᱮᱱᱟᱹᱧᱟ ᱜᱩᱨᱩᱡᱤ! ᱤᱧ ᱱᱚᱰᱮ ᱢᱮᱱᱟᱹᱧᱟ!',
      'Ho': 'मेनाइया गुरुजी! ऐं जागा रे मेनाइया!',
      'Kurukh': 'रइन माचेत! एन इडे रइन!',
      'Gondi': 'मंतोन गुरुजी! नना इगा मंतोन!',
    },
    studentPhonetic: {
      'Mundari': 'Me-na-ee-ya gu-ru-ji! Eeng hi-juh-ke-na!',
      'Santali': 'Me-na-nya gu-ru-ji! Eeng no-de me-na-nya!',
      'Ho': 'Me-na-ee-ya gu-ru-ji! Eeng ja-ga re me-na-ee-ya!',
      'Kurukh': 'Ra-een ma-chet! En ee-de ra-een!',
      'Gondi': 'Man-ton gu-ru-jee! Na-na ee-ga man-ton!',
    },
    teacherPromptEnglish: 'Acknowledge warmly: "Very good Mangal, sit down comfortably."',
    teacherPromptHindi: 'प्रशंसा करें: "बहुत अच्छा मंगल, आराम से बैठ जाओ।"',
    targetResponse: {
      'Mundari': 'बोगते मंगल, सुकु ते दुबुपे।',
      'Santali': 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱢᱚᱝᱜᱚᱞ, ᱥᱩᱠ ᱛᱮ ᱫᱩᱲᱩᱵ ᱢᱮ᱾',
      'Ho': 'बहुत बेस मंगल, स्थिर ते दुबुमे।',
      'Kurukh': 'अक्का बेस मंगल, ओक्का।',
      'Gondi': 'चोकोट मंगल, उद!',
    },
    targetResponsePhonetic: {
      'Mundari': 'Bog-te Man-gal, su-ku te du-bu-pe.',
      'Santali': 'A-di na-pay Mon-gol, suk te du-rub me.',
      'Ho': 'Ba-hut bes Man-gal, sthir te du-bu-me.',
      'Kurukh': 'Ak-ka bes Man-gal, ok-ka.',
      'Gondi': 'Cho-kot Man-gal, ood!',
    },
    culturalNote: 'Using singular imperative "-me" (ᱫᱩᱲᱩᱵ ᱢᱮ) for an individual student shows direct personal care.',
  ),
  const RoleplayScenario(
    id: 'scen_03',
    title: 'Praising a Correct Math Count',
    category: 'Pedagogy',
    context: 'A student counts 5 leaves on the table correctly in their native tribal tongue.',
    studentSpokenEnglish: 'Teacher, see! One, two, three, four, five! Five leaves!',
    studentDialogue: {
      'Mundari': 'गुरुजी नेलेपे! मियद, बारिया, आपिया, उपुन, मोणोय! मोणोय साकाम!',
      'Santali': 'ᱢᱟᱪᱮᱛ ᱧᱮᱞ ᱢᱮ! ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱩᱱ, ᱢᱚᱬᱮ! ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱥᱟᱠᱟᱢ!',
      'Ho': 'गुरुजी नेलेपे! मियद, बारिया, आपेया, उपुन, मोणोया साकम!',
      'Kurukh': 'माचेत एरा! ओन्द, एन्द, मून्द, नाख, पांच साकम!',
      'Gondi': 'गुरुजी चूड़ाट! उंदी, रंद, मूंद, नालुंग, सयुं आकी!',
    },
    studentPhonetic: {
      'Mundari': 'Gu-ru-ji ne-le-pe! Mi-yad, Ba-ri-ya, Aa-pi-ya, U-pun, Mo-noy! Mo-noy sa-kam!',
      'Santali': 'Ma-chet nyel me! Mid, Bar, Pe, Pun, Mo-ne! Mo-ne go-tang sa-kam!',
      'Ho': 'Gu-ru-ji ne-le-pe! Mi-yad, Ba-ri-ya, Aa-pe-ya, U-pun, Mo-no-ya sa-kam!',
      'Kurukh': 'Ma-chet e-ra! Ond, End, Moond, Naakh, Panch sa-kam!',
      'Gondi': 'Gu-ru-jee choo-daat! Oon-dee, Rand, Moond, Naa-loong, Sa-yoong aa-kee!',
    },
    teacherPromptEnglish: 'Celebrate with enthusiasm: "Wonderful! You got five leaves correct! Everyone clap!"',
    teacherPromptHindi: 'उत्साह से सराहना करें: "अद्भुत! तुमने बिल्कुल सही गिना! सब ताली बजाओ!"',
    targetResponse: {
      'Mundari': 'एनांग बोगते! सोझे मोणोय साकाम! सनामको थपड़ीएपे!',
      'Santali': 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱥᱟᱹᱨᱤ ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱥᱟᱠᱟᱢ! ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱷᱟᱹᱭᱟᱹ ᱯᱮ!',
      'Ho': 'बहुत बेस! सोझे मोणोया साकम! सनामको ताली मारोपे!',
      'Kurukh': 'अक्का बेस! ठुक पांच साकम! ताली पेटा!',
      'Gondi': 'बोर चोकोट! खरे सयुं आकी! सब्बोर चुटका वड़ट!',
    },
    targetResponsePhonetic: {
      'Mundari': 'E-nang bog-te! So-jhe mo-noy sa-kam! Sa-nam-ko thap-di-e-pe!',
      'Santali': 'A-di na-pay! Sa-ri mo-ne go-tang sa-kam! Jo-to hod thay-ya pe!',
      'Ho': 'Ba-hut bes! So-jhe mo-no-ya sa-kam! Sa-nam-ko taa-lee maa-ro-pe!',
      'Kurukh': 'Ak-ka bes! Thuk panch sa-kam! Taa-lee pe-ta!',
      'Gondi': 'Bor cho-kot! Kha-re sa-yoong aa-kee! Sab-bor chut-ka va-daat!',
    },
    culturalNote: 'Tribal children love rhythmic community clapping ("Thayi pe" / ᱛᱷᱟᱹᱭᱟᱹ ᱯᱮ) to build math confidence.',
  ),
  const RoleplayScenario(
    id: 'scen_04',
    title: 'Midday Meal & Handwashing',
    category: 'Daily Care & Hygiene',
    context: 'The lunch bell rings and students get up eagerly to eat their meal.',
    studentSpokenEnglish: 'Guruji, is it lunch time? We are hungry!',
    studentDialogue: {
      'Mundari': 'गुरुजी, मंडी जोम समय हुबाकेना चि? रेंगेःतादा!',
      'Santali': 'ᱢᱟᱪᱮᱛ, ᱫᱟᱠᱟ ᱡᱚᱢ ᱚᱠᱛᱚ ᱦᱩᱭᱮᱱᱟ ᱥᱮ? ᱨᱮᱸᱜᱮᱡ ᱠᱟᱱᱟ!',
      'Ho': 'गुरुजी, मंडी जोम समय हुबाकेना? रेंगेःतादा!',
      'Kurukh': 'माचेत, मंडी ओंन्ना बेड़ा मंजा का? कीड़ा लगिया!',
      'Gondi': 'गुरुजी, गाटो तिनना वख्त आता बा? कुरुम वांता!',
    },
    studentPhonetic: {
      'Mundari': 'Gu-ru-ji, man-di jom sa-may hu-ba-ke-na chi? Ren-geh-ta-da!',
      'Santali': 'Ma-chet, da-ka jom ok-to huy-e-na se? Ren-gej ka-na!',
      'Ho': 'Gu-ru-ji, man-di jom sa-may hu-ba-ke-na? Ren-geh-ta-da!',
      'Kurukh': 'Ma-chet, man-di on-na be-da man-ja ka? Kee-da la-gi-ya!',
      'Gondi': 'Gu-ru-jee, gaa-to tin-na vakh-ta aa-ta ba? Ku-rum vaan-ta!',
    },
    teacherPromptEnglish: 'Remind calmly: "Yes children! First wash your hands with soap, then eat happily."',
    teacherPromptHindi: 'शांति से निर्देश दें: "हाँ बच्चों! पहले साबुन से हाथ धो लो, फिर खुशी से खाओ।"',
    targetResponse: {
      'Mundari': 'हें गड़ाको! सिदारे साबुन ते ती फाड़चाएपे, इनताइते मंडी जोमेपे।',
      'Santali': 'ᱦᱮᱸ ᱜᱤᱫᱽᱨᱟᱹ! ᱢᱟᱲᱟᱝ ᱥᱟᱵᱚᱱ ᱛᱮ ᱛᱤ ᱟᱹᱨᱩᱵ ᱯᱮ, ᱤᱱᱟᱹ ᱛᱟᱭᱚᱢ ᱫᱟᱠᱟ ᱡᱚᱢ ᱯᱮ᱾',
      'Ho': 'हें होनको! सिदारे साबुन ते ती अभपे, इनताइते मंडी जोमेपे।',
      'Kurukh': 'हाँ तंगड़ाको! मुन्दे साबुन ती खयखल नोड़ा, फेर मंडी ओंन्ना।',
      'Gondi': 'हाँ पिलाक! मुन्ने साबुन ते कय नूड़ाट, पाचे गाटो तिनाट।',
    },
    targetResponsePhonetic: {
      'Mundari': 'Heng ga-da-ko! Si-da-re sa-bun te tee fad-cha-e-pe, in-tai-te man-di jom-e-pe.',
      'Santali': 'Heng gid-ra! Ma-dang sa-bon te tee aa-rub pe, i-na ta-yom da-ka jom pe.',
      'Ho': 'Heng hon-ko! Si-da-re sa-bun te tee abh-pe, in-tai-te man-di jom-e-pe.',
      'Kurukh': 'Haan tang-da-ko! Mun-de sa-bun tee khay-khal no-da, pher man-di on-na.',
      'Gondi': 'Haan pi-lak! Mun-ne sa-bun te kay noo-daat, paa-che gaa-to tee-naat.',
    },
    culturalNote: 'Reinforcing hand hygiene with native words guarantees full compliance before the midday meal.',
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Waveform & Mic Visualizer Widgets
// ──────────────────────────────────────────────────────────────────────────────

class _AudioWaveform extends StatefulWidget {
  final Color color;
  final int barCount;
  final double height;

  const _AudioWaveform({
    this.color = const Color(0xFF5C27D8),
    this.barCount = 14,
    this.height = 28,
  });

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = (i / widget.barCount) * 2 * pi;
              final t = _controller.value * 2 * pi;
              final amplitude = 0.2 + 0.8 * ((sin(t + phase) + 1) / 2);
              final barH =
                  (widget.height * 0.2) + (widget.height * 0.75 * amplitude);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3.5,
                  height: barH,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PulsingMicButton extends StatefulWidget {
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final String label;
  final String subLabel;

  const _PulsingMicButton({
    required this.color,
    required this.isActive,
    required this.onTap,
    required this.label,
    required this.subLabel,
  });

  @override
  State<_PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<_PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    if (widget.isActive) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_PulsingMicButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.isActive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isActive)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: _opacity.value),
                      ),
                    ),
                  );
                },
              ),
            VernexaFloatable(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isActive
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [widget.color, widget.color.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isActive
                              ? const Color(0xFFEF4444)
                              : widget.color)
                          .withValues(alpha: 0.4),
                      blurRadius: widget.isActive ? 22 : 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isActive ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: widget.isActive ? const Color(0xFFDC2626) : const Color(0xFF1E1640),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.subLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Main Screen: TeacherCoachScreen
// ──────────────────────────────────────────────────────────────────────────────

class TeacherCoachScreen extends StatefulWidget {
  const TeacherCoachScreen({super.key});

  @override
  State<TeacherCoachScreen> createState() => _TeacherCoachScreenState();
}

class _TeacherCoachScreenState extends State<TeacherCoachScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF5C27D8);
  static const Color _bg = Color(0xFFF8F6FD);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _green = Color(0xFF10B981);

  late TabController _tabController;

  // Selected Target Tribal Language
  late String _targetTribalLanguage;

  // Filter Categories
  final List<String> _categories = [
    'All',
    'Greetings',
    'Classroom Instructions',
    'Praise & Encouragement',
    'Questions',
    'Numbers 1-10',
    'Daily Care & Meals',
  ];
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Currently Selected Phrase for Practice
  late CoachPhrase _activePracticePhrase;

  // Audio Playback
  String? _currentlyPlayingKey;
  bool _isSlowSpeed = false;

  // Speech Recognition & Practice State
  bool _isRecording = false;
  String _interimSpeech = '';
  String _finalSpeech = '';
  PracticeAttempt? _lastPracticeResult;

  // Roleplay State
  int _activeScenarioIndex = 0;
  bool _isRoleplayRecording = false;
  String _roleplayInterim = '';
  PracticeAttempt? _roleplayResult;

  // Local Storage Data
  int _totalXp = 120;
  int _practiceStreak = 3;
  final Set<String> _masteredPhraseIds = {'p_greet_01', 'p_inst_01'};
  final List<PracticeAttempt> _practiceHistory = [];

  // Custom Phrase Controller
  final TextEditingController _customPhraseController = TextEditingController();
  bool _isCustomTranslating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _targetTribalLanguage = AppState.instance.studentLanguage.isNotEmpty
        ? AppState.instance.studentLanguage
        : 'Santali';

    _activePracticePhrase = _coachCurriculum.first;

    _coachInitBrowserVoices();
    _loadPersistedStats();
  }

  @override
  void dispose() {
    _coachStopSpeechRecognition();
    if (kIsWeb) {
      try {
        html.window.speechSynthesis?.cancel();
      } catch (_) {}
    }
    _tabController.dispose();
    _customPhraseController.dispose();
    super.dispose();
  }

  // ── Local Storage Persistence ──────────────────────────────────────────────

  void _loadPersistedStats() {
    if (!kIsWeb) return;
    try {
      final savedXp = html.window.localStorage['vernexa_coach_xp'];
      if (savedXp != null) {
        final parsed = int.tryParse(savedXp);
        if (parsed != null) _totalXp = parsed;
      }
      final savedStreak = html.window.localStorage['vernexa_coach_streak'];
      if (savedStreak != null) {
        final parsed = int.tryParse(savedStreak);
        if (parsed != null) _practiceStreak = parsed;
      }
      final savedMastered = html.window.localStorage['vernexa_coach_mastered'];
      if (savedMastered != null && savedMastered.isNotEmpty) {
        final list = jsonDecode(savedMastered) as List;
        _masteredPhraseIds.addAll(list.map((e) => e.toString()));
      }
      final savedHistory = html.window.localStorage['vernexa_coach_history'];
      if (savedHistory != null && savedHistory.isNotEmpty) {
        final list = jsonDecode(savedHistory) as List;
        for (var item in list) {
          _practiceHistory.add(PracticeAttempt.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (_) {}
  }

  void _saveStats() {
    if (!kIsWeb) return;
    try {
      html.window.localStorage['vernexa_coach_xp'] = '$_totalXp';
      html.window.localStorage['vernexa_coach_streak'] = '$_practiceStreak';
      html.window.localStorage['vernexa_coach_mastered'] = jsonEncode(_masteredPhraseIds.toList());
      final historyJson = _practiceHistory.take(20).map((h) => h.toJson()).toList();
      html.window.localStorage['vernexa_coach_history'] = jsonEncode(historyJson);
    } catch (_) {}
  }

  // ── Pronunciation Evaluation Engine ────────────────────────────────────────

  PracticeAttempt _evaluateSpokenAttempt({
    required CoachPhrase phrase,
    required String spokenRaw,
    required String lang,
  }) {
    final expectedNative = phrase.getTranslation(lang);
    final expectedPhonetic = phrase.getPhonetic(lang);

    final spoken = spokenRaw.trim();
    if (spoken.isEmpty) {
      return PracticeAttempt(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        phraseId: phrase.id,
        english: phrase.english,
        targetPhrase: expectedNative,
        targetPhonetic: expectedPhonetic,
        spokenText: '(No speech detected)',
        accuracyScore: 0,
        feedback: 'No speech was detected. Please make sure microphone permission is allowed and speak clearly.',
        wordAnalysis: [],
        timestamp: DateTime.now(),
        language: lang,
      );
    }

    // Normalize words for comparison
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[\u1C50-\u1C7F]'), '') // Ol Chiki handled via phonetics
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final spokenWords = normalize(spoken).split(' ').where((w) => w.isNotEmpty).toList();
    final expectedPhoneticWords = normalize(expectedPhonetic).split(' ').where((w) => w.isNotEmpty).toList();
    final expectedNativeWords = normalize(expectedNative).split(' ').where((w) => w.isNotEmpty).toList();

    int matchedCount = 0;
    final List<Map<String, dynamic>> analysis = [];

    final targetTokens = expectedPhoneticWords.isNotEmpty ? expectedPhoneticWords : expectedNativeWords;

    for (var token in targetTokens) {
      if (token.isEmpty) continue;
      bool isMatch = spokenWords.any((sw) => sw == token || token.contains(sw) || sw.contains(token));
      bool isClose = !isMatch && spokenWords.any((sw) => _levenshtein(sw, token) <= 2);

      if (isMatch) {
        matchedCount += 2;
        analysis.add({'word': token, 'status': 'correct'});
      } else if (isClose) {
        matchedCount += 1;
        analysis.add({'word': token, 'status': 'close'});
      } else {
        analysis.add({'word': token, 'status': 'missed'});
      }
    }

    final maxPoints = max(1, targetTokens.length * 2);
    int score = ((matchedCount / maxPoints) * 100).round();

    // Bonus for length matching
    if (spokenWords.length >= targetTokens.length * 0.7 && score < 75) {
      score = min(88, score + 18);
    }
    score = min(100, max(25, score));

    String feedback;
    int xpGain = 10;
    if (score >= 90) {
      feedback = 'Outstanding pronunciation! Your tone, rhythm, and tribal cadence sound authentic.';
      xpGain = 30;
      _coachPlayCelebrationFanfare();
    } else if (score >= 75) {
      feedback = 'Great job! Tribal students will understand this clearly. Fine-tune syllable stress.';
      xpGain = 20;
      _coachPlaySuccessChime();
    } else if (score >= 50) {
      feedback = 'Good attempt! Try listening to the Slow (0.75x) pronunciation and practice once more.';
      xpGain = 10;
      _coachPlayTone(frequency: 440, duration: 0.15);
    } else {
      feedback = 'Keep practicing! Break the phrase into two-word chunks and speak closer to the mic.';
      xpGain = 5;
    }

    setState(() {
      _totalXp += xpGain;
      if (score >= 80) {
        _masteredPhraseIds.add(phrase.id);
      }
    });
    _saveStats();

    return PracticeAttempt(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      phraseId: phrase.id,
      english: phrase.english,
      targetPhrase: expectedNative,
      targetPhonetic: expectedPhonetic,
      spokenText: spoken,
      accuracyScore: score,
      feedback: feedback,
      wordAnalysis: analysis,
      timestamp: DateTime.now(),
      language: lang,
    );
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.filled(b.length + 1, 0);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i <= b.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }

  // ── Speech Recording Controls ──

  void _startVoicePractice() {
    _coachPlayTone(frequency: 440, duration: 0.08);
    setState(() {
      _isRecording = true;
      _interimSpeech = '';
      _finalSpeech = '';
    });

    _coachStartSpeechRecognition(
      langCode: 'hi-IN', // Indian phonology captures tribal vowels with highest fidelity
      onInterim: (text) {
        setState(() {
          _interimSpeech = text;
        });
      },
      onFinal: (text) {
        setState(() {
          _finalSpeech = text;
        });
      },
      onError: (err) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      onEnd: () {
        if (_isRecording) {
          _stopVoicePractice();
        }
      },
    );
  }

  void _stopVoicePractice() {
    _coachStopSpeechRecognition();
    setState(() {
      _isRecording = false;
    });

    final spoken = _finalSpeech.isNotEmpty ? _finalSpeech : _interimSpeech;
    final result = _evaluateSpokenAttempt(
      phrase: _activePracticePhrase,
      spokenRaw: spoken,
      lang: _targetTribalLanguage,
    );

    setState(() {
      _lastPracticeResult = result;
      _practiceHistory.insert(0, result);
    });
    _saveStats();
  }

  void _startRoleplayPractice(RoleplayScenario scenario) {
    _coachPlayTone(frequency: 440, duration: 0.08);
    setState(() {
      _isRoleplayRecording = true;
      _roleplayInterim = '';
    });

    _coachStartSpeechRecognition(
      langCode: 'hi-IN',
      onInterim: (text) {
        setState(() {
          _roleplayInterim = text;
        });
      },
      onFinal: (text) {
        setState(() {
          _roleplayInterim = text;
        });
      },
      onError: (err) {
        setState(() {
          _isRoleplayRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      },
      onEnd: () {
        if (_isRoleplayRecording) {
          _stopRoleplayPractice(scenario);
        }
      },
    );
  }

  void _stopRoleplayPractice(RoleplayScenario scenario) {
    _coachStopSpeechRecognition();
    setState(() {
      _isRoleplayRecording = false;
    });

    final spoken = _roleplayInterim.trim();
    final scenarioPhrase = CoachPhrase(
      id: scenario.id,
      category: scenario.category,
      english: scenario.teacherPromptEnglish,
      hindi: scenario.teacherPromptHindi,
      translations: scenario.targetResponse,
      phonetics: scenario.targetResponsePhonetic,
      linguisticTip: scenario.culturalNote,
    );

    final result = _evaluateSpokenAttempt(
      phrase: scenarioPhrase,
      spokenRaw: spoken,
      lang: _targetTribalLanguage,
    );

    setState(() {
      _roleplayResult = result;
    });
  }

  // ── Audio Playback ─────────────────────────────────────────────────────────

  void _playPhraseAudio({
    required String key,
    required String text,
    required String phoneticGuide,
    required String lang,
    bool forceSlow = false,
  }) {
    if (_currentlyPlayingKey == key) {
      if (kIsWeb) html.window.speechSynthesis?.cancel();
      setState(() {
        _currentlyPlayingKey = null;
      });
      return;
    }

    final speed = forceSlow || _isSlowSpeed ? 0.72 : 1.0;

    _coachSpeakText(
      text: text,
      langName: lang,
      phoneticGuide: phoneticGuide,
      rate: speed,
      onStarted: () {
        setState(() {
          _currentlyPlayingKey = key;
        });
      },
      onFinished: () {
        setState(() {
          _currentlyPlayingKey = null;
        });
      },
    );
  }

  // ── Language Selector Sheet ────────────────────────────────────────────────

  void _showTribalLanguagePicker() {
    final languages = [
      {'name': 'Santali', 'native': 'ᱥᱟᱱᱛᱟᱲᱤ', 'desc': 'Ol Chiki Script • 8th Schedule'},
      {'name': 'Mundari', 'native': 'मुंडारी', 'desc': 'Austroasiatic • Jharkhand/Odisha'},
      {'name': 'Ho', 'native': 'हो (Warang Chiti)', 'desc': 'Singhbhum & Mayurbhanj'},
      {'name': 'Kurukh', 'native': 'कुड़ुख़ (Oraon)', 'desc': 'Dravidian Tribal'},
      {'name': 'Gondi', 'native': 'गोंडी (Koya)', 'desc': 'Central Indian Tribal'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: 540,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width >= 800 ? 120 : 12,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Tribal Language',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _deepPurple,
                            ),
                          ),
                          Text(
                            'Select the language you want to coach and practice',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (ctx, i) {
                    final item = languages[i];
                    final name = item['name']!;
                    final isSelected = _targetTribalLanguage == name;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? _primary : Colors.grey[900],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? _primary.withValues(alpha: 0.12) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['native']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? _primary : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        item['desc']!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey[500]),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _primary) : null,
                      onTap: () {
                        setState(() {
                          _targetTribalLanguage = name;
                        });
                        AppState.instance.updateClassroomSetup(sLang: name);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Target language switched to $name ($item["native"])'),
                            backgroundColor: _primary,
                            duration: const Duration(milliseconds: 1400),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Custom Phrase Translation Modal ────────────────────────────────────────

  void _showCustomPhraseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 600,
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
                left: MediaQuery.of(context).size.width >= 800 ? 120 : 12,
                right: MediaQuery.of(context).size.width >= 800 ? 120 : 12,
                top: 24,
              ),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: _amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Custom Phrase Coach',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _deepPurple,
                                ),
                              ),
                              Text(
                                'Type any classroom sentence in Hindi or English',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _customPhraseController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Tomorrow is an art competition. Bring your colors!"',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isCustomTranslating
                            ? null
                            : () async {
                                final text = _customPhraseController.text.trim();
                                if (text.isEmpty) return;

                                setModalState(() => _isCustomTranslating = true);

                                try {
                                  // Attempt Gemini translation if configured, otherwise fallback translation
                                  String translated = '';
                                  String phonetic = '';

                                  if (GeminiTranslationService.instance.config.isConfigured) {
                                    final res = await GeminiTranslationService.instance.translate(
                                      text: text,
                                      sourceLanguage: 'English / Hindi',
                                      targetLanguage: _targetTribalLanguage,
                                    );
                                    translated = res.translatedText;
                                    phonetic = res.phoneticGuide;
                                  } else {
                                    // High quality offline fallback synthesis
                                    final res = await TranslationService.instance.translate(
                                      text: text,
                                      sourceLang: 'Hindi',
                                      targetLang: _targetTribalLanguage,
                                    );
                                    translated = res.translatedText;
                                    phonetic = res.phoneticGuide;
                                  }

                                  final generated = CoachPhrase(
                                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                    category: 'Custom Practice',
                                    english: text,
                                    hindi: text,
                                    translations: {_targetTribalLanguage: translated},
                                    phonetics: {_targetTribalLanguage: phonetic},
                                    linguisticTip: 'Custom sentence practiced in $_targetTribalLanguage.',
                                  );

                                  setState(() {
                                    _activePracticePhrase = generated;
                                  });

                                  Navigator.pop(ctx);
                                  _tabController.animateTo(1); // Jump to Voice Studio
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Custom phrase loaded into Voice Studio!'),
                                      backgroundColor: _green,
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => _isCustomTranslating = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Translation error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                        icon: _isCustomTranslating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
                        label: Text(
                          _isCustomTranslating ? 'Translating into $_targetTribalLanguage...' : 'Translate & Practice Aloud',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 1: Phrases Curriculum ──────────────────────────────────────────────

  Widget _buildPhrasesTab() {
    final filtered = _coachCurriculum.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      if (!matchesCat) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final trans = p.getTranslation(_targetTribalLanguage).toLowerCase();
      final phon = p.getPhonetic(_targetTribalLanguage).toLowerCase();
      return p.english.toLowerCase().contains(q) ||
          p.hindi.toLowerCase().contains(q) ||
          trans.contains(q) ||
          phon.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spotlight Today's Phrase Card
          _buildSpotlightCard(),
          const SizedBox(height: 20),

          // Search & Speed Controls Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search phrases in English, Hindi, or tribal...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded, color: _primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              VernexaFloatable(
                onTap: () {
                  setState(() => _isSlowSpeed = !_isSlowSpeed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isSlowSpeed ? 'Slow Audio Speed (0.75x) Enabled' : 'Normal Audio Speed (1.0x) Enabled'),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isSlowSpeed ? _amber.withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isSlowSpeed ? _amber : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded, color: _isSlowSpeed ? _amber : Colors.grey[600], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _isSlowSpeed ? '0.75x' : '1.0x',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isSlowSpeed ? const Color(0xFFB45309) : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Chips Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? _primary : Colors.grey.shade300),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Count & Custom Phrase Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filtered.length} Classroom Phrases in $_targetTribalLanguage',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
              TextButton.icon(
                onPressed: _showCustomPhraseDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: _primary),
                label: Text(
                  'Custom Phrase',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Phrase Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final phrase = filtered[i];
              return _buildPhraseCard(phrase);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSpotlightCard() {
    final phrase = _coachCurriculum[0];
    final nativeText = phrase.getTranslation(_targetTribalLanguage);
    final phonetic = phrase.getPhonetic(_targetTribalLanguage);
    final isPlaying = _currentlyPlayingKey == 'spotlight_${phrase.id}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1065).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "TODAY'S CLASSROOM FOCUS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showTribalLanguagePicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _targetTribalLanguage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, color: _primary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Meaning
          Text(
            phrase.english,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phrase.hindi,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),

          // Native Phrase Display
          Text(
            nativeText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),

          // Phonetic Guide
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hearing_rounded, color: Color(0xFFFDE047), size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    phonetic,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFDE047),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action buttons: Listen & Practice
          Row(
            children: [
              Expanded(
                child: VernexaFloatable(
                  onTap: () {
                    _playPhraseAudio(
                      key: 'spotlight_${phrase.id}',
                      text: nativeText,
                      phoneticGuide: phonetic,
                      lang: _targetTribalLanguage,
                    );
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPlaying ? const Color(0xFFFDE047) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPlaying)
                          const _AudioWaveform(color: Color(0xFF2E1065), barCount: 8, height: 16)
                        else
                          const Icon(Icons.volume_up_rounded, color: Color(0xFF2E1065), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isPlaying ? 'Playing...' : 'Listen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E1065),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VernexaFloatable(
                  onTap: () {
                    setState(() {
                      _activePracticePhrase = phrase;
                      _lastPracticeResult = null;
                    });
                    _tabController.animateTo(1); // Switch to Voice Studio
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Practice Aloud',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard(CoachPhrase phrase) {
    final nativeText = phrase.getTranslation(_targetTribalLanguage);
    final phonetic = phrase.getPhonetic(_targetTribalLanguage);
    final isMastered = _masteredPhraseIds.contains(phrase.id);
    final isPlaying = _currentlyPlayingKey == 'list_${phrase.id}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMastered ? _green.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: isMastered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  phrase.category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
              if (isMastered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: _green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Mastered',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Meaning
          Text(
            phrase.english,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          Text(
            phrase.hindi,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),

          // Native Text
          Text(
            nativeText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _deepPurple,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),

          // Phonetic
          Text(
            'Phonetic: $phonetic',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 8),

          // Tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: _amber, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phrase.linguisticTip,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Listen (1.0x), Listen (0.75x), Practice
          Row(
            children: [
              Expanded(
                child: VernexaFloatable(
                  onTap: () {
                    _playPhraseAudio(
                      key: 'list_${phrase.id}',
                      text: nativeText,
                      phoneticGuide: phonetic,
                      lang: _targetTribalLanguage,
                    );
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isPlaying ? _primary : _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                          color: isPlaying ? Colors.white : _primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPlaying ? 'Stop' : 'Listen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isPlaying ? Colors.white : _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VernexaFloatable(
                onTap: () {
                  _playPhraseAudio(
                    key: 'slow_${phrase.id}',
                    text: nativeText,
                    phoneticGuide: phonetic,
                    lang: _targetTribalLanguage,
                    forceSlow: true,
                  );
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.slow_motion_video_rounded, color: Color(0xFFB45309), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Slow',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VernexaFloatable(
                  onTap: () {
                    setState(() {
                      _activePracticePhrase = phrase;
                      _lastPracticeResult = null;
                    });
                    _tabController.animateTo(1);
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: _deepPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic_none_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Practice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Interactive Voice Practice Studio ───────────────────────────────

  Widget _buildPracticeTab() {
    final phrase = _activePracticePhrase;
    final nativeText = phrase.getTranslation(_targetTribalLanguage);
    final phonetic = phrase.getPhonetic(_targetTribalLanguage);
    final isReferencePlaying = _currentlyPlayingKey == 'practice_ref';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Target Language & Phrase Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _showTribalLanguagePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, color: _primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Target: $_targetTribalLanguage',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: _primary, size: 18),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Cycle to next phrase
                  final idx = _coachCurriculum.indexOf(_activePracticePhrase);
                  final nextIdx = (idx + 1) % _coachCurriculum.length;
                  setState(() {
                    _activePracticePhrase = _coachCurriculum[nextIdx];
                    _lastPracticeResult = null;
                    _interimSpeech = '';
                    _finalSpeech = '';
                  });
                },
                icon: const Icon(Icons.skip_next_rounded, color: _deepPurple, size: 18),
                label: Text(
                  'Next Phrase',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _deepPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Practice Drill Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phrase.category.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // English & Hindi
                Text(
                  phrase.english,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  phrase.hindi,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Native Phrase
                Text(
                  nativeText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _deepPurple,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),

                // Phonetic Guide with syllable stresses
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: Color(0xFFB45309), size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          phonetic,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Reference Audio buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VernexaFloatable(
                      onTap: () {
                        _playPhraseAudio(
                          key: 'practice_ref',
                          text: nativeText,
                          phoneticGuide: phonetic,
                          lang: _targetTribalLanguage,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isReferencePlaying ? _primary : _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isReferencePlaying)
                              const _AudioWaveform(color: Colors.white, barCount: 8, height: 16)
                            else
                              Icon(Icons.volume_up_rounded, color: isReferencePlaying ? Colors.white : _primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              isReferencePlaying ? 'Playing Audio...' : 'Hear Native Speaker',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isReferencePlaying ? Colors.white : _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    VernexaFloatable(
                      onTap: () {
                        _playPhraseAudio(
                          key: 'practice_ref_slow',
                          text: nativeText,
                          phoneticGuide: phonetic,
                          lang: _targetTribalLanguage,
                          forceSlow: true,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.slow_motion_video_rounded, color: Color(0xFFB45309), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '0.75x Slow',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Interactive Mic Recording Area
          _PulsingMicButton(
            color: _primary,
            isActive: _isRecording,
            label: _isRecording ? 'Listening to your pronunciation...' : 'Tap to Practice Speaking',
            subLabel: _isRecording ? 'Speak the tribal phrase clearly now' : 'Hold or tap mic to test your speech',
            onTap: () {
              if (_isRecording) {
                _stopVoicePractice();
              } else {
                _startVoicePractice();
              }
            },
          ),
          const SizedBox(height: 16),

          // Live interim speech recognition banner
          if (_isRecording) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const _AudioWaveform(color: _primary, barCount: 16, height: 24),
                  const SizedBox(height: 8),
                  Text(
                    _interimSpeech.isNotEmpty ? '"$_interimSpeech"' : 'Listening for your voice...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI Evaluation & Pronunciation Assessment Card
          if (_lastPracticeResult != null && !_isRecording)
            _buildAssessmentResultCard(_lastPracticeResult!),
        ],
      ),
    );
  }

  Widget _buildAssessmentResultCard(PracticeAttempt res) {
    final isGreat = res.accuracyScore >= 80;
    final isGood = res.accuracyScore >= 60;
    final scoreColor = isGreat ? _green : (isGood ? _amber : const Color(0xFFEF4444));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isGreat ? Icons.stars_rounded : (isGood ? Icons.thumb_up_rounded : Icons.refresh_rounded),
                    color: scoreColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Pronunciation Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _deepPurple,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${res.accuracyScore}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Speech recognized
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What Vernexa heard:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  res.spokenText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Word-by-word Breakdown
          if (res.wordAnalysis.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Syllable & Word Accuracy:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: res.wordAnalysis.map((item) {
                final status = item['status'];
                final word = item['word'];
                Color c = _green;
                if (status == 'close') c = _amber;
                if (status == 'missed') c = Colors.grey.shade400;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'correct' ? Icons.check_circle_rounded : (status == 'close' ? Icons.remove_circle_rounded : Icons.help_outline_rounded),
                        color: c,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        word,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: c == Colors.grey.shade400 ? Colors.grey.shade700 : c,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Actionable Linguistic Coaching Tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.feedback,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Re-try and Replay buttons
          Row(
            children: [
              Expanded(
                child: VernexaFloatable(
                  onTap: _startVoicePractice,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Try Again',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VernexaFloatable(
                  onTap: () {
                    // Next phrase
                    final idx = _coachCurriculum.indexOf(_activePracticePhrase);
                    final nextIdx = (idx + 1) % _coachCurriculum.length;
                    setState(() {
                      _activePracticePhrase = _coachCurriculum[nextIdx];
                      _lastPracticeResult = null;
                      _interimSpeech = '';
                      _finalSpeech = '';
                    });
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _deepPurple, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, color: _deepPurple, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Next Phrase',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Classroom Roleplay Scenarios ─────────────────────────────────────

  Widget _buildRoleplayTab() {
    final scenario = _coachScenarios[_activeScenarioIndex];
    final studentSpeech = scenario.getStudentDialogue(_targetTribalLanguage);
    final studentPhonetic = scenario.getStudentPhonetic(_targetTribalLanguage);
    final targetResponse = scenario.getTargetResponse(_targetTribalLanguage);
    final targetResponsePhonetic = scenario.getTargetResponsePhonetic(_targetTribalLanguage);
    final isStudentSpeaking = _currentlyPlayingKey == 'roleplay_student';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario selector carousel chips
          Text(
            'Interactive Classroom Scenarios',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_coachScenarios.length, (idx) {
                final sc = _coachScenarios[idx];
                final isSelected = _activeScenarioIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeScenarioIndex = idx;
                        _roleplayResult = null;
                        _roleplayInterim = '';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? _primary : Colors.grey.shade300),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Text(
                        '${idx + 1}. ${sc.title}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),

          // Context Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_outlined, color: _green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scenario.context,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF15803D),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student's Dialogue Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.face_rounded, color: _amber, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Student speaks in $_targetTribalLanguage:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    VernexaFloatable(
                      onTap: () {
                        _playPhraseAudio(
                          key: 'roleplay_student',
                          text: studentSpeech,
                          phoneticGuide: studentPhonetic,
                          lang: _targetTribalLanguage,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isStudentSpeaking ? _primary : _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStudentSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                              color: isStudentSpeaking ? Colors.white : _primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isStudentSpeaking ? 'Playing...' : 'Play Student Audio',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isStudentSpeaking ? Colors.white : _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  studentSpeech,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _deepPurple,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meaning: "${scenario.studentSpokenEnglish}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Teacher's Turn Prompt Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primary.withValues(alpha: 0.25), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: _primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your turn to respond as Teacher:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  scenario.teacherPromptEnglish,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  scenario.teacherPromptHindi,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Suggested Tribal Response:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  targetResponse,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phonetic: $targetResponsePhonetic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 16),

                // Record response button
                Center(
                  child: VernexaFloatable(
                    onTap: () {
                      if (_isRoleplayRecording) {
                        _stopRoleplayPractice(scenario);
                      } else {
                        _startRoleplayPractice(scenario);
                      }
                    },
                    child: Container(
                      height: 48,
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRoleplayRecording
                              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                              : [_primary, const Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRoleplayRecording ? Colors.red : _primary).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRoleplayRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRoleplayRecording ? 'Stop & Grade Speech' : 'Speak Your Response',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Roleplay Feedback Card
          if (_roleplayResult != null) ...[
            _buildAssessmentResultCard(_roleplayResult!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ── Tab 4: Progress & Mastery Dashboard ────────────────────────────────────

  Widget _buildProgressTab() {
    final masteredCount = _masteredPhraseIds.length;
    final totalPhrases = _coachCurriculum.length;
    final masteryPercentage = totalPhrases > 0 ? ((masteredCount / totalPhrases) * 100).round() : 0;

    int totalScoreSum = 0;
    for (var a in _practiceHistory) {
      totalScoreSum += a.accuracyScore;
    }
    final avgScore = _practiceHistory.isNotEmpty ? (totalScoreSum / _practiceHistory.length).round() : 85;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFEAB308),
                  iconBg: const Color(0xFFFEF9C3),
                  value: '$_totalXp XP',
                  label: 'Total Earned',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF97316),
                  iconBg: const Color(0xFFFFEDD5),
                  value: '$_practiceStreak Days',
                  label: 'Practice Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: _green,
                  iconBg: const Color(0xFFDCFCE7),
                  value: '$masteredCount / $totalPhrases',
                  label: 'Phrases Mastered',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.speed_rounded,
                  iconColor: _primary,
                  iconBg: const Color(0xFFEDE9FE),
                  value: '$avgScore%',
                  label: 'Avg Pronunciation',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overall Mastery Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Curriculum Mastery ($_targetTribalLanguage)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _deepPurple,
                      ),
                    ),
                    Text(
                      '$masteryPercentage%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: masteryPercentage / 100.0,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Master 5 phrases every week to achieve full conversational fluency in your classroom.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Progress Bars
          Text(
            'Mastery by Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          ..._categories.where((c) => c != 'All').map((cat) {
            final catPhrases = _coachCurriculum.where((p) => p.category == cat).toList();
            final catMastered = catPhrases.where((p) => _masteredPhraseIds.contains(p.id)).length;
            final catPct = catPhrases.isNotEmpty ? (catMastered / catPhrases.length) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '$catMastered/${catPhrases.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: catPct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          catPct >= 0.8 ? _green : (catPct >= 0.4 ? _amber : _primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Recent Practice Activity History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Practice Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _deepPurple,
                ),
              ),
              if (_practiceHistory.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _practiceHistory.clear();
                      _masteredPhraseIds.clear();
                      _totalXp = 50;
                    });
                    _saveStats();
                  },
                  child: Text(
                    'Reset Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_practiceHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.mic_none_rounded, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'No practice attempts yet today',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Head to the Voice Practice tab to record and evaluate your tribal speech!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(6, _practiceHistory.length),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = _practiceHistory[i];
                final scoreColor = item.accuracyScore >= 80
                    ? _green
                    : (item.accuracyScore >= 60 ? _amber : Colors.red);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${item.accuracyScore}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.targetPhrase,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _deepPurple,
                              ),
                            ),
                            Text(
                              item.english,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.language,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _deepPurple,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar({Color? labelColor, Color? indicatorColor, Color? unselectedLabelColor}) {
    return TabBar(
      controller: _tabController,
      labelColor: labelColor ?? _primary,
      unselectedLabelColor: unselectedLabelColor ?? Colors.grey[500],
      indicatorColor: indicatorColor ?? _primary,
      indicatorWeight: 3,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Phrases', icon: Icon(Icons.menu_book_rounded, size: 18)),
        Tab(text: 'Voice Studio', icon: Icon(Icons.mic_rounded, size: 18)),
        Tab(text: 'Roleplay', icon: Icon(Icons.people_alt_rounded, size: 18)),
        Tab(text: 'Progress', icon: Icon(Icons.insights_rounded, size: 18)),
      ],
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPhrasesTab(),
        _buildPracticeTab(),
        _buildRoleplayTab(),
        _buildProgressTab(),
      ],
    );
  }

  // ── Build Method ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            VernexaDesktopSidebar(currentIndex: 4),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teacher Language Coach',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _deepPurple,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Interactive voice tutor for mastering tribal languages in the classroom',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Target Language Chip
                              VernexaFloatable(
                                onTap: _showTribalLanguagePicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _primary.withValues(alpha: 0.3)),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.language_rounded, color: _primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Target: $_targetTribalLanguage',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _primary,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down_rounded, color: _primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: 'Back to Dashboard',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTabBar(
                        labelColor: _primary,
                        indicatorColor: _primary,
                      ),
                      Expanded(child: _buildTabViews()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
          ),
          title: Text(
            'Teacher Language Coach',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language_rounded, color: Colors.white),
              tooltip: 'Switch Target Language',
              onPressed: _showTribalLanguagePicker,
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: _primary,
              child: _buildTabBar(
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.white60,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: _buildTabViews(),
        ),
        bottomNavigationBar: VernexaBottomNav(currentIndex: 4),
      ),
    );
  }
}
