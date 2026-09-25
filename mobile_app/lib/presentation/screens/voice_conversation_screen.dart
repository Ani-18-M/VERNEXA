import 'dart:async';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';
import '../../core/app_state.dart';
import '../../core/translation_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Web Speech API Helpers (Continuous JS Interop + Dart Fallback)
// ──────────────────────────────────────────────────────────────────────────────

html.SpeechRecognition? _vcActiveRecognition;

void _vcEnsureSpeechScriptInjected() {
  try {
    if (js.context['__vernexaVCSpeech'] == null) {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = r'''
window.__vernexaVCSpeech = {
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

void _vcStartSpeechRecognition({
  required String langCode,
  required void Function(String) onInterim,
  required void Function(String) onFinal,
  required void Function(String) onError,
  required void Function() onEnd,
}) {
  _vcEnsureSpeechScriptInjected();
  try {
    final speechObj = js.context['__vernexaVCSpeech'];
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

  // Fallback to Dart native SpeechRecognition
  _vcFallbackDartSpeechRecognition(
    langCode: langCode,
    onInterim: onInterim,
    onFinal: onFinal,
    onError: onError,
    onEnd: onEnd,
  );
}

void _vcFallbackDartSpeechRecognition({
  required String langCode,
  required void Function(String) onInterim,
  required void Function(String) onFinal,
  required void Function(String) onError,
  required void Function() onEnd,
}) {
  try {
    _vcActiveRecognition?.abort();
    final recognition = html.SpeechRecognition();
    _vcActiveRecognition = recognition;
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = langCode;

    recognition.onResult.listen((event) {
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

    recognition.onError.listen((event) {
      onError('Audio input event: ${event.type}');
      onEnd();
    });

    recognition.onEnd.listen((_) => onEnd());
    recognition.start();
  } catch (e) {
    onError('Unable to open microphone: $e');
    onEnd();
  }
}

void _vcStopSpeechRecognition() {
  try {
    final speechObj = js.context['__vernexaVCSpeech'];
    if (speechObj != null) {
      speechObj.callMethod('stop');
    }
  } catch (_) {}
  try {
    _vcActiveRecognition?.stop();
    _vcActiveRecognition = null;
  } catch (_) {}
}

// ──────────────────────────────────────────────────────────────────────────────
// Browser Voices & Text-to-Speech Engine with Tribal Phonetics
// ──────────────────────────────────────────────────────────────────────────────

List<html.SpeechSynthesisVoice> _vcCachedBrowserVoices = [];

void _vcInitBrowserVoices() {
  try {
    final synth = html.window.speechSynthesis;
    if (synth != null) {
      if (_vcCachedBrowserVoices.isEmpty) {
        _vcCachedBrowserVoices = synth.getVoices();
      }
      synth.addEventListener('voiceschanged', (_) {
        _vcCachedBrowserVoices = synth.getVoices();
      });
    }
  } catch (_) {}
}

void _vcSpeakText({
  required String text,
  required String langName,
  String phoneticGuide = '',
  double rate = 1.0,
  void Function()? onStarted,
  void Function()? onFinished,
}) {
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      onFinished?.call();
      return;
    }

    _vcInitBrowserVoices();
    synth.cancel();
    synth.resume(); // Fix Chromium background pause bug

    final hasOlChiki = RegExp(r'[\u1C50-\u1C7F]').hasMatch(text);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);

    final voices = _vcCachedBrowserVoices.isNotEmpty
        ? _vcCachedBrowserVoices
        : synth.getVoices();
    final hasHindiVoice = voices.any((v) =>
        (v.lang ?? '').toLowerCase().startsWith('hi') ||
        (v.name ?? '').toLowerCase().contains('hindi') ||
        (v.name ?? '').toLowerCase().contains('lekha'));

    String toSpeak = text;
    String targetSpeechLang = 'en-US';

    if (langName == 'English') {
      toSpeak = text;
      targetSpeechLang = 'en-US';
    } else if (langName == 'Hindi') {
      toSpeak = text;
      targetSpeechLang = 'hi-IN';
    } else if (hasOlChiki || langName == 'Santali') {
      // Ol Chiki glyphs produce silence in standard browser TTS, so speak Romanized phonetics
      if (phoneticGuide.trim().isNotEmpty &&
          !RegExp(r'[\u1C50-\u1C7F]').hasMatch(phoneticGuide)) {
        toSpeak = phoneticGuide.trim();
      } else {
        toSpeak = olChikiToPhonetic(text.isNotEmpty ? text : phoneticGuide);
      }
      targetSpeechLang = 'en-IN';
    } else {
      // Tribal languages (Ho, Mundari, Kurukh, Gondi)
      if (hasHindiVoice && hasDevanagari) {
        toSpeak = text.replaceAll(':', 'ह').replaceAll('ः', 'ह');
        targetSpeechLang = 'hi-IN';
      } else if (phoneticGuide.trim().isNotEmpty &&
          !RegExp(r'[\u0900-\u097F]').hasMatch(phoneticGuide)) {
        toSpeak = phoneticGuide.trim();
        targetSpeechLang = 'en-IN';
      } else if (langName == 'Ho') {
        toSpeak = hoToPhonetic(text);
        targetSpeechLang = 'en-IN';
      } else if (hasDevanagari) {
        toSpeak = devanagariToPhonetic(text);
        targetSpeechLang = 'en-IN';
      } else {
        toSpeak = text;
        targetSpeechLang = 'hi-IN';
      }
    }

    // Clean pronunciation blockers
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
    utterance.lang = targetSpeechLang;

    if (voices.isNotEmpty) {
      final voice = voices.firstWhere(
        (v) {
          final l = (v.lang ?? '').toLowerCase();
          final n = (v.name ?? '').toLowerCase();
          if (utterance.lang == 'hi-IN') {
            return l.startsWith('hi') || n.contains('hindi') || n.contains('lekha');
          }
          if (utterance.lang == 'en-IN') {
            return l == 'en-in' ||
                n.contains('india') ||
                n.contains('indian') ||
                n.contains('rishi') ||
                n.contains('veena');
          }
          if (utterance.lang == 'en-US') {
            return l == 'en-us' ||
                n.contains('united states') ||
                n.contains('samantha') ||
                n.contains('google');
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

String _langToBcp47(String language) {
  switch (language) {
    case 'Hindi':
      return 'hi-IN';
    case 'English':
      return 'en-US';
    case 'Mundari':
    case 'Santali':
    case 'Ho':
    case 'Kurukh':
    case 'Gondi':
    default:
      // Tribal languages are spoken using Indian phonology
      return 'hi-IN';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Data Model & Classroom Phrase Starters
// ──────────────────────────────────────────────────────────────────────────────

class _ConversationMessage {
  final String id;
  final String role; // 'teacher' or 'student'
  final String original;
  final String translated;
  final String phonetic;
  final String sourceLang;
  final String targetLang;
  final DateTime time;
  bool isFavorite;

  _ConversationMessage({
    required this.id,
    required this.role,
    required this.original,
    required this.translated,
    required this.phonetic,
    required this.sourceLang,
    required this.targetLang,
    DateTime? time,
  })  : isFavorite = false,
        time = time ?? DateTime.now();
}

class _QuickPrompt {
  final String label;
  final String textHindi;
  final String textEnglish;
  final IconData icon;

  const _QuickPrompt({
    required this.label,
    required this.textHindi,
    required this.textEnglish,
    required this.icon,
  });
}

const List<_QuickPrompt> _kTeacherPrompts = [
  _QuickPrompt(
    label: 'Morning Greeting',
    textHindi: 'नमस्ते बच्चों, आप सब कैसे हैं?',
    textEnglish: 'Hello children, how are you all?',
    icon: Icons.wb_sunny_rounded,
  ),
  _QuickPrompt(
    label: 'Open Books',
    textHindi: 'बच्चों, अपनी किताबें पेज नंबर पाँच पर खोलें।',
    textEnglish: 'Children, please open your books to page five.',
    icon: Icons.menu_book_rounded,
  ),
  _QuickPrompt(
    label: 'What is your name?',
    textHindi: 'तुम्हारा नाम क्या है?',
    textEnglish: 'What is your name?',
    icon: Icons.person_search_rounded,
  ),
  _QuickPrompt(
    label: 'Sit Down Quietly',
    textHindi: 'सब बच्चे अपनी जगह पर शांत होकर बैठ जाएं।',
    textEnglish: 'All children please sit down quietly in your places.',
    icon: Icons.chair_rounded,
  ),
  _QuickPrompt(
    label: 'Do you understand?',
    textHindi: 'क्या आपको यह समझ में आया?',
    textEnglish: 'Do you understand this?',
    icon: Icons.help_outline_rounded,
  ),
  _QuickPrompt(
    label: 'Repeat After Me',
    textHindi: 'मेरे पीछे सब बच्चे ज़ोर से दोहराएं।',
    textEnglish: 'Everyone repeat loudly after me.',
    icon: Icons.record_voice_over_rounded,
  ),
  _QuickPrompt(
    label: 'Count 1 to 10',
    textHindi: 'बच्चों, आज हम एक से दस तक गिनती सीखेंगे।',
    textEnglish: 'Children, today we will learn numbers one to ten.',
    icon: Icons.format_list_numbered_rounded,
  ),
  _QuickPrompt(
    label: 'Very Good Praise',
    textHindi: 'बहुत अच्छा, शाबाश बच्चों!',
    textEnglish: 'Very good, wonderful job children!',
    icon: Icons.thumb_up_rounded,
  ),
  _QuickPrompt(
    label: 'Drink Water',
    textHindi: 'जाओ पानी पी लो और हाथ धोकर आओ।',
    textEnglish: 'Go drink water and wash your hands.',
    icon: Icons.water_drop_rounded,
  ),
];

const List<_QuickPrompt> _kStudentPrompts = [
  _QuickPrompt(
    label: 'Yes Teacher',
    textHindi: 'हाँ शिक्षक, मुझे समझ आ गया।',
    textEnglish: 'Yes teacher, I understood.',
    icon: Icons.check_circle_outline_rounded,
  ),
  _QuickPrompt(
    label: 'Please Explain Again',
    textHindi: 'मुझे समझ नहीं आया, कृपया फिर से समझाएं।',
    textEnglish: "I didn't understand, please explain again.",
    icon: Icons.replay_rounded,
  ),
  _QuickPrompt(
    label: 'Present Teacher',
    textHindi: 'उपस्थित हूँ शिक्षक!',
    textEnglish: 'Present teacher!',
    icon: Icons.how_to_reg_rounded,
  ),
  _QuickPrompt(
    label: 'My Name is Somra',
    textHindi: 'मेरा नाम सोमरा है।',
    textEnglish: 'My name is Somra.',
    icon: Icons.badge_rounded,
  ),
  _QuickPrompt(
    label: 'May I Drink Water?',
    textHindi: 'क्या मैं पानी पीने जा सकता हूँ?',
    textEnglish: 'May I go drink water?',
    icon: Icons.local_drink_rounded,
  ),
  _QuickPrompt(
    label: 'Finished Work',
    textHindi: 'शिक्षक, मैंने अपना काम पूरा कर लिया है।',
    textEnglish: 'Teacher, I have completed my work.',
    icon: Icons.task_alt_rounded,
  ),
  _QuickPrompt(
    label: 'Thank You Teacher',
    textHindi: 'धन्यवाद शिक्षक!',
    textEnglish: 'Thank you teacher!',
    icon: Icons.favorite_rounded,
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Animated Waveform Widget
// ──────────────────────────────────────────────────────────────────────────────

class _AudioWaveform extends StatefulWidget {
  final Color color;
  final int barCount;
  final double height;

  const _AudioWaveform({
    this.color = const Color(0xFF5C27D8),
    this.barCount = 12,
    this.height = 24,
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
                  width: 3.2,
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

// ──────────────────────────────────────────────────────────────────────────────
// Pulsing Mic Button Widget
// ──────────────────────────────────────────────────────────────────────────────

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
    return VernexaFloatable(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isActive)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color.withValues(alpha: _opacity.value),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? widget.color
                        : widget.color.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color
                            .withValues(alpha: widget.isActive ? 0.55 : 0.28),
                        blurRadius: widget.isActive ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isActive ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isActive ? 'Listening…' : widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.isActive ? widget.color : const Color(0xFF1E1640),
            ),
          ),
          Text(
            widget.subLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: widget.color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Chat Bubble with Rich Action Bar
// ──────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _ConversationMessage message;
  final bool isPlayingOriginal;
  final bool isPlayingTranslation;
  final VoidCallback onPlayOriginal;
  final VoidCallback onPlayTranslation;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const _ChatBubble({
    required this.message,
    required this.isPlayingOriginal,
    required this.isPlayingTranslation,
    required this.onPlayOriginal,
    required this.onPlayTranslation,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = message.role == 'teacher';
    const teacherColor = Color(0xFF5C27D8);
    const studentColor = Color(0xFF10B981);
    final primaryColor = isTeacher ? teacherColor : studentColor;

    final bgColor = isTeacher ? const Color(0xFFF3EFFF) : const Color(0xFFEAFBF4);
    final borderColor = isTeacher
        ? teacherColor.withValues(alpha: 0.25)
        : studentColor.withValues(alpha: 0.25);

    final timeStr =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment:
            isTeacher ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Role & Language header
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTeacher ? Icons.school_rounded : Icons.face_rounded,
                  size: 13,
                  color: primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isTeacher
                      ? 'Teacher (${message.sourceLang})'
                      : 'Student (${message.sourceLang})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• $timeStr',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment:
                isTeacher ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isTeacher)
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: studentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.face_rounded,
                      color: studentColor, size: 20),
                ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isTeacher
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isTeacher
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.record_voice_over_rounded,
                                size: 13, color: primaryColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.original,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1640),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Container(height: 1, color: borderColor),
                      const SizedBox(height: 10),

                      // Translated Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.translate_rounded,
                                size: 13, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.translated,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF18182E),
                                    height: 1.35,
                                  ),
                                ),
                                if (message.phonetic.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pronunciation: "${message.phonetic}"',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action bar: Audio Play buttons, Copy, Favorite, Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Play Original Audio
                              _BubbleActionBtn(
                                label: isPlayingOriginal ? 'Speaking…' : 'Original',
                                icon: isPlayingOriginal
                                    ? Icons.graphic_eq_rounded
                                    : Icons.volume_up_rounded,
                                color: primaryColor,
                                isWave: isPlayingOriginal,
                                onTap: onPlayOriginal,
                              ),
                              const SizedBox(width: 8),
                              // Play Translated Audio
                              _BubbleActionBtn(
                                label: isPlayingTranslation ? 'Speaking…' : 'Translation',
                                icon: isPlayingTranslation
                                    ? Icons.graphic_eq_rounded
                                    : Icons.headphones_rounded,
                                color: const Color(0xFF0284C7),
                                isWave: isPlayingTranslation,
                                onTap: onPlayTranslation,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Copy translation button
                              Tooltip(
                                message: 'Copy translation',
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: message.translated));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Copied: "${message.translated}"',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: const Color(0xFF1E1640),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.copy_rounded,
                                        size: 16, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Favorite toggle button
                              Tooltip(
                                message: message.isFavorite
                                    ? 'Unfavorite'
                                    : 'Save phrase',
                                child: InkWell(
                                  onTap: onToggleFavorite,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      message.isFavorite
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 18,
                                      color: message.isFavorite
                                          ? const Color(0xFFEAB308)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete button
                              Tooltip(
                                message: 'Delete',
                                child: InkWell(
                                  onTap: onDelete,
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.close_rounded,
                                        size: 16, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isTeacher)
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(left: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: teacherColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: teacherColor, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BubbleActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isWave;
  final VoidCallback onTap;

  const _BubbleActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isWave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VernexaFloatable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isWave ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: color.withValues(alpha: isWave ? 0.6 : 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWave) ...[
              _AudioWaveform(color: color, barCount: 4, height: 12),
              const SizedBox(width: 4),
            ] else ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Main Voice Conversation Screen
// ──────────────────────────────────────────────────────────────────────────────

class VoiceConversationScreen extends StatefulWidget {
  const VoiceConversationScreen({super.key});

  @override
  State<VoiceConversationScreen> createState() =>
      _VoiceConversationScreenState();
}

class _VoiceConversationScreenState extends State<VoiceConversationScreen> {
  static const _purple = Color(0xFF5C27D8);
  static const _deepPurple = Color(0xFF28127D);
  static const _green = Color(0xFF10B981);
  static const _bg = Color(0xFFF7F5FC);

  bool _twoWayMode = true;
  bool _teacherListening = false;
  bool _studentListening = false;
  bool _isTranslating = false;
  bool _isSlowSpeech = false;

  final List<_ConversationMessage> _messages = [];
  String _teacherInterim = '';
  String _studentInterim = '';

  // Currently playing audio identifier ('${msg.id}_orig' or '${msg.id}_trans')
  String? _currentlyPlayingKey;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textInputController = TextEditingController();
  final FocusNode _textInputFocus = FocusNode();
  String _activeInputRole = 'teacher'; // 'teacher' or 'student'

  @override
  void initState() {
    super.initState();
    _vcInitBrowserVoices();
  }

  @override
  void dispose() {
    _vcStopSpeechRecognition();
    html.window.speechSynthesis?.cancel();
    _scrollController.dispose();
    _textInputController.dispose();
    _textInputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Language Selector Modal ────────────────────────────────────────────────

  void _showLanguagePicker({required bool isTeacher}) {
    final current = isTeacher
        ? AppState.instance.teacherLanguage
        : AppState.instance.studentLanguage;

    final languages = [
      {'name': 'Hindi', 'native': 'हिंदी', 'desc': 'Official State / National'},
      {'name': 'English', 'native': 'English', 'desc': 'Standard Medium'},
      {'name': 'Mundari', 'native': 'मुंडारी', 'desc': 'Austroasiatic • Jharkhand/Odisha'},
      {'name': 'Santali', 'native': 'ᱥᱟᱱᱛᱟᱲᱤ', 'desc': 'Ol Chiki Script • 8th Schedule'},
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
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isTeacher ? _purple : _green)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTeacher ? Icons.school_rounded : Icons.face_rounded,
                        color: isTeacher ? _purple : _green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTeacher
                                ? 'Select Teacher Language'
                                : 'Select Student Language',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _deepPurple,
                            ),
                          ),
                          Text(
                            'Audio speech & translation will sync instantly',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Language options list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 64),
                  itemBuilder: (context, i) {
                    final item = languages[i];
                    final name = item['name']!;
                    final native = item['native']!;
                    final desc = item['desc']!;
                    final isSelected = current == name;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isTeacher ? _purple : _green)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.substring(0, 1),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _deepPurple,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isTeacher ? _purple : _green)
                                  : const Color(0xFF1E1640),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            native,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        desc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: isTeacher ? _purple : _green, size: 22)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          if (isTeacher) {
                            AppState.instance.updateClassroomSetup(tLang: name);
                          } else {
                            AppState.instance.updateClassroomSetup(sLang: name);
                          }
                        });
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

  // ── Swap Languages ─────────────────────────────────────────────────────────

  void _swapLanguages() {
    final t = AppState.instance.teacherLanguage;
    final s = AppState.instance.studentLanguage;
    setState(() {
      AppState.instance.updateClassroomSetup(tLang: s, sLang: t);
    });
  }

  // ── Speech Recognition Actions ─────────────────────────────────────────────

  void _onTeacherMicTap() {
    if (_teacherListening) {
      _vcStopSpeechRecognition();
      setState(() => _teacherListening = false);
      return;
    }
    if (_studentListening || _isTranslating) return;

    setState(() {
      _teacherListening = true;
      _teacherInterim = '';
    });

    final langCode = _langToBcp47(AppState.instance.teacherLanguage);
    _vcStartSpeechRecognition(
      langCode: langCode,
      onInterim: (text) {
        if (mounted) setState(() => _teacherInterim = text);
      },
      onFinal: (text) async {
        if (!mounted) return;
        _vcStopSpeechRecognition();
        setState(() {
          _teacherListening = false;
          _teacherInterim = '';
          _isTranslating = true;
        });
        await _translateAndAppend(text: text, isTeacher: true);
        if (mounted) setState(() => _isTranslating = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _teacherListening = false;
            _teacherInterim = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _teacherListening = false;
            _teacherInterim = '';
          });
        }
      },
    );
  }

  void _onStudentMicTap() {
    if (_studentListening) {
      _vcStopSpeechRecognition();
      setState(() => _studentListening = false);
      return;
    }
    if (_teacherListening || _isTranslating) return;

    setState(() {
      _studentListening = true;
      _studentInterim = '';
    });

    final langCode = _langToBcp47(AppState.instance.studentLanguage);
    _vcStartSpeechRecognition(
      langCode: langCode,
      onInterim: (text) {
        if (mounted) setState(() => _studentInterim = text);
      },
      onFinal: (text) async {
        if (!mounted) return;
        _vcStopSpeechRecognition();
        setState(() {
          _studentListening = false;
          _studentInterim = '';
          _isTranslating = true;
        });
        await _translateAndAppend(text: text, isTeacher: false);
        if (mounted) setState(() => _isTranslating = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _studentListening = false;
            _studentInterim = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _studentListening = false;
            _studentInterim = '';
          });
        }
      },
    );
  }

  // ── Core Translation Execution ─────────────────────────────────────────────

  Future<void> _translateAndAppend({
    required String text,
    required bool isTeacher,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final sourceLang = isTeacher
        ? AppState.instance.teacherLanguage
        : AppState.instance.studentLanguage;
    final targetLang = isTeacher
        ? AppState.instance.studentLanguage
        : AppState.instance.teacherLanguage;

    try {
      final result = await TranslationService.instance.translate(
        text: trimmed,
        sourceLang: sourceLang,
        targetLang: targetLang,
        isTeacherSpeaker: isTeacher,
      );

      if (!mounted) return;

      final msg = _ConversationMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        role: isTeacher ? 'teacher' : 'student',
        original: trimmed,
        translated: result.translatedText,
        phonetic: result.phoneticGuide,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      setState(() => _messages.add(msg));
      _scrollToBottom();

      // Automatically speak the translation aloud
      final rate = _isSlowSpeech ? 0.78 : 0.95;
      final playKey = '${msg.id}_trans';
      setState(() => _currentlyPlayingKey = playKey);

      _vcSpeakText(
        text: result.translatedText,
        langName: targetLang,
        phoneticGuide: result.phoneticGuide,
        rate: rate,
        onFinished: () {
          if (mounted && _currentlyPlayingKey == playKey) {
            setState(() => _currentlyPlayingKey = null);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Translation notice: $e',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Text Input Submission ──────────────────────────────────────────────────

  void _submitTextInput() {
    final text = _textInputController.text.trim();
    if (text.isEmpty) return;
    _textInputController.clear();
    _translateAndAppend(
      text: text,
      isTeacher: _activeInputRole == 'teacher',
    );
  }

  // ── Manual Speech Replay ───────────────────────────────────────────────────

  void _playMessageAudio(_ConversationMessage msg, bool isOriginal) {
    final playKey = '${msg.id}_${isOriginal ? "orig" : "trans"}';
    if (_currentlyPlayingKey == playKey) {
      html.window.speechSynthesis?.cancel();
      setState(() => _currentlyPlayingKey = null);
      return;
    }

    final text = isOriginal ? msg.original : msg.translated;
    final lang = isOriginal ? msg.sourceLang : msg.targetLang;
    final phonetic = isOriginal ? '' : msg.phonetic;
    final rate = _isSlowSpeech ? 0.75 : 0.95;

    setState(() => _currentlyPlayingKey = playKey);

    _vcSpeakText(
      text: text,
      langName: lang,
      phoneticGuide: phonetic,
      rate: rate,
      onFinished: () {
        if (mounted && _currentlyPlayingKey == playKey) {
          setState(() => _currentlyPlayingKey = null);
        }
      },
    );
  }

  // ── Clear Conversation Dialog ──────────────────────────────────────────────

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 26),
            const SizedBox(width: 8),
            Text(
              'Clear Conversation?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: _deepPurple,
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove all ${_messages.length} messages from the current voice session.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
            },
            child: Text('Clear All',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Session Summary Dialog ─────────────────────────────────────────────────

  void _showSessionSummary() {
    final teacherCount = _messages.where((m) => m.role == 'teacher').length;
    final studentCount = _messages.where((m) => m.role == 'student').length;
    final favCount = _messages.where((m) => m.isFavorite).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, color: _purple, size: 24),
            const SizedBox(width: 8),
            Text(
              'Session Summary',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: _deepPurple,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Total Phrases:', '${_messages.length}'),
            _buildSummaryRow('Teacher Spoken:', '$teacherCount'),
            _buildSummaryRow('Student Spoken:', '$studentCount'),
            _buildSummaryRow('Starred Phrases:', '$favCount'),
            _buildSummaryRow(
              'Active Languages:',
              '${AppState.instance.teacherLanguage} ↔ ${AppState.instance.studentLanguage}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.grey.shade700)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _deepPurple)),
        ],
      ),
    );
  }

  // ── Layout Components ──────────────────────────────────────────────────────

  Widget _buildLanguageBar() {
    final tLang = AppState.instance.teacherLanguage;
    final sLang = AppState.instance.studentLanguage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teacher Language Pill
          Expanded(
            child: VernexaFloatable(
              onTap: () => _showLanguagePicker(isTeacher: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _purple.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: _purple, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Teacher',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600)),
                          Text(tLang,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _purple)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: _purple, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // Swap Languages Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: VernexaFloatable(
              onTap: _swapLanguages,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: _purple.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: _purple, size: 20),
              ),
            ),
          ),

          // Student Language Pill
          Expanded(
            child: VernexaFloatable(
              onTap: () => _showLanguagePicker(isTeacher: false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.face_rounded, color: _green, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600)),
                          Text(sLang,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _green)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: _green, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopModeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Two-way conversation toggle
          Row(
            children: [
              Text(
                'Two-Way Chat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(width: 6),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: _twoWayMode,
                  activeColor: _purple,
                  onChanged: (v) => setState(() => _twoWayMode = v),
                ),
              ),
            ],
          ),

          // Audio speed toggle & Summary
          Row(
            children: [
              // Slow speech toggle
              VernexaFloatable(
                onTap: () => setState(() => _isSlowSpeech = !_isSlowSpeech),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isSlowSpeech
                        ? const Color(0xFFFEF3C7)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSlowSpeech
                          ? const Color(0xFFD97706)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 14,
                        color: _isSlowSpeech
                            ? const Color(0xFFD97706)
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSlowSpeech ? 'Slow (0.8x)' : '1.0x',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isSlowSpeech
                              ? const Color(0xFFD97706)
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Summary
              if (_messages.isNotEmpty)
                IconButton(
                  onPressed: _showSessionSummary,
                  icon: const Icon(Icons.analytics_outlined,
                      size: 20, color: _purple),
                  tooltip: 'Session Summary',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final prompts =
        _activeInputRole == 'teacher' ? _kTeacherPrompts : _kStudentPrompts;
    final isTeacher = _activeInputRole == 'teacher';
    final roleColor = isTeacher ? _purple : _green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(
                isTeacher ? Icons.tips_and_updates_rounded : Icons.child_care_rounded,
                size: 13,
                color: roleColor,
              ),
              const SizedBox(width: 5),
              Text(
                isTeacher
                    ? 'Classroom Starter Prompts (Tap to Speak):'
                    : 'Student Reply Prompts (Tap to Simulate):',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: prompts.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: VernexaFloatable(
                  onTap: () {
                    final text = AppState.instance.teacherLanguage == 'English'
                        ? p.textEnglish
                        : p.textHindi;
                    _translateAndAppend(
                      text: text,
                      isTeacher: isTeacher,
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: roleColor.withValues(alpha: 0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p.icon, size: 14, color: roleColor),
                        const SizedBox(width: 5),
                        Text(
                          p.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1640),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.record_voice_over_rounded,
                  color: _purple, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'Bilingual Voice Bridge',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _deepPurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time bilingual voice bridge between teacher and student.\nTap the mic below or select a starter prompt.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInterimBanner() {
    final hasInterim = _teacherInterim.isNotEmpty ||
        _studentInterim.isNotEmpty ||
        _isTranslating;
    if (!hasInterim) return const SizedBox.shrink();

    String label;
    Color color;
    if (_isTranslating) {
      label = 'Translating into tribal speech…';
      color = _purple;
    } else if (_teacherInterim.isNotEmpty) {
      label = 'Teacher: "${_teacherInterim}"';
      color = _purple;
    } else {
      label = 'Student: "${_studentInterim}"';
      color = _green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          if (!_isTranslating) ...[
            _AudioWaveform(color: color, barCount: 8, height: 18),
            const SizedBox(width: 10),
          ] else ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock() {
    final tLang = AppState.instance.teacherLanguage;
    final sLang = AppState.instance.studentLanguage;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text Input bar (for noisy classrooms or typing fallback)
            Row(
              children: [
                // Role indicator switch
                VernexaFloatable(
                  onTap: () {
                    setState(() {
                      _activeInputRole =
                          _activeInputRole == 'teacher' ? 'student' : 'teacher';
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: (_activeInputRole == 'teacher' ? _purple : _green)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_activeInputRole == 'teacher' ? _purple : _green)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _activeInputRole == 'teacher'
                              ? Icons.school_rounded
                              : Icons.face_rounded,
                          size: 15,
                          color: _activeInputRole == 'teacher' ? _purple : _green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _activeInputRole == 'teacher' ? 'Teacher' : 'Student',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _activeInputRole == 'teacher'
                                ? _purple
                                : _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _textInputController,
                      focusNode: _textInputFocus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitTextInput(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF1E1640),
                      ),
                      decoration: InputDecoration(
                        hintText: _activeInputRole == 'teacher'
                            ? 'Type phrase in $tLang…'
                            : 'Type phrase in $sLang…',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Send Button
                VernexaFloatable(
                  onTap: _submitTextInput,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _activeInputRole == 'teacher' ? _purple : _green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Big Mic Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Teacher Mic
                _PulsingMicButton(
                  color: _purple,
                  isActive: _teacherListening,
                  onTap: _onTeacherMicTap,
                  label: 'Teacher Mic',
                  subLabel: tLang,
                ),

                // Center Action (Clear conversation or End)
                Column(
                  children: [
                    if (_messages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: VernexaFloatable(
                          onTap: _clearConversation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep_rounded,
                                    size: 15, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    VernexaFloatable(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Dashboard',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Student Mic (if in two-way mode)
                if (_twoWayMode)
                  _PulsingMicButton(
                    color: _green,
                    isActive: _studentListening,
                    onTap: _onStudentMicTap,
                    label: 'Student Mic',
                    subLabel: sLang,
                  )
                else
                  const SizedBox(width: 84),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Language selectors & mode toggles
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            children: [
              _buildLanguageBar(),
              const SizedBox(height: 6),
              _buildTopModeBar(),
              const SizedBox(height: 6),
              _buildQuickPromptsBar(),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Conversation history list
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    return _ChatBubble(
                      message: msg,
                      isPlayingOriginal:
                          _currentlyPlayingKey == '${msg.id}_orig',
                      isPlayingTranslation:
                          _currentlyPlayingKey == '${msg.id}_trans',
                      onPlayOriginal: () => _playMessageAudio(msg, true),
                      onPlayTranslation: () => _playMessageAudio(msg, false),
                      onToggleFavorite: () {
                        setState(() => msg.isFavorite = !msg.isFavorite);
                      },
                      onDelete: () {
                        setState(() => _messages.removeAt(i));
                      },
                    );
                  },
                ),
        ),

        // Interim transcription bar
        _buildInterimBanner(),

        // Bottom control dock
        _buildControlDock(),
      ],
    );
  }

  // ── Build Screen (Desktop & Mobile) ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: VernexaFloatable(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                title: Text(
                  'Voice Conversation',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (_messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.white),
                      tooltip: 'Clear conversation',
                      onPressed: _clearConversation,
                    ),
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined,
                        color: Colors.white),
                    tooltip: 'Session Summary',
                    onPressed: _showSessionSummary,
                  ),
                ],
              ),
        body: isDesktop
            ? Row(
                children: [
                  const VernexaDesktopSidebar(currentIndex: 4),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: Column(
                          children: [
                            // Desktop header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              color: Colors.white,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        color: _deepPurple, size: 22),
                                    onPressed: () =>
                                        Navigator.pushNamedAndRemoveUntil(
                                            context, '/home', (route) => false),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Voice Conversation Engine',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _deepPurple,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_messages.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: _clearConversation,
                                      icon: const Icon(
                                          Icons.delete_sweep_rounded,
                                          size: 16),
                                      label: const Text('Clear'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildBody()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _buildBody(),
        bottomNavigationBar: const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }
}
