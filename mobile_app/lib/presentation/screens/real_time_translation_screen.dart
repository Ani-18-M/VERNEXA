import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../../core/gemini_translation_service.dart';
import '../../core/translation_service.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';

// ─── Web Speech API helpers (Flutter Web – Chrome/Edge only) ─────────────────

/// Holds the active SpeechRecognition JS object so we can stop it in Dart fallback.
html.SpeechRecognition? _activeRecognition;

/// Ensures the window.__vernexaSpeech JavaScript controller is loaded.
void _ensureSpeechScriptInjected() {
  try {
    if (js.context['__vernexaSpeech'] == null) {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = r'''
window.__vernexaSpeech = {
  recognition: null,
  isRecording: false,
  start: function(lang, onResult, onError, onEnd) {
    var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRec) {
      if (onError) onError('Speech recognition not supported in this browser. Please use Google Chrome or Microsoft Edge.');
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
      rec.lang = lang || 'en-IN';

      rec.onresult = function(event) {
        var full = '';
        for (var i = 0; i < event.results.length; i++) {
          var seg = event.results[i];
          if (seg && seg.length > 0) {
            full += seg[0].transcript;
          }
        }
        var clean = full.trim();
        console.log('[Vernexa] Recognized speech:', clean);
        if (clean.length > 0 && onResult) {
          onResult(clean);
        }
      };

      rec.onerror = function(event) {
        var err = event.error || '';
        console.warn('[Vernexa] Speech recognition error:', err);
        if (err === 'no-speech' || err === 'aborted') {
          return;
        }
        if (err === 'not-allowed') {
          if (onError) onError('Microphone access denied. Click the site settings icon in the browser address bar to Allow.');
        } else {
          if (onError) onError('Speech notice: ' + err);
        }
        if (onEnd) onEnd();
      };

      rec.onend = function() {
        console.log('[Vernexa] Speech recognition ended');
        if (onEnd) onEnd();
      };

      rec.start();
      console.log('[Vernexa] Microphone recording started in language:', rec.lang);
    } catch(e) {
      console.error('[Vernexa] Failed to start speech recognition:', e);
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
    console.log('[Vernexa] Microphone stopped');
  }
};
''';
      html.document.head?.append(script);
    }
  } catch (_) {}
}

/// Starts speech recognition directly within the user tap gesture.
void _startWebSpeechRecognition({
  required String langCode,
  required void Function(String transcript) onResult,
  required void Function() onEnd,
  required void Function(String error) onError,
}) {
  try {
    _ensureSpeechScriptInjected();
    final speechObj = js.context['__vernexaSpeech'];
    if (speechObj != null) {
      speechObj.callMethod('start', [
        langCode,
        (dynamic transcript) {
          onResult(transcript.toString());
        },
        (dynamic error) {
          onError(error.toString());
        },
        () {
          onEnd();
        },
      ]);
    } else {
      _fallbackDartSpeechRecognition(
        langCode: langCode,
        onResult: onResult,
        onEnd: onEnd,
        onError: onError,
      );
    }
  } catch (e) {
    _fallbackDartSpeechRecognition(
      langCode: langCode,
      onResult: onResult,
      onEnd: onEnd,
      onError: onError,
    );
  }
}

/// Fallback speech recognition purely in Dart using safe .item(0) extraction.
void _fallbackDartSpeechRecognition({
  required String langCode,
  required void Function(String transcript) onResult,
  required void Function() onEnd,
  required void Function(String error) onError,
}) {
  try {
    _activeRecognition?.abort();
    final recognition = html.SpeechRecognition();
    _activeRecognition = recognition;
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = langCode;

    recognition.onResult.listen((event) {
      final results = event.results;
      if (results != null) {
        final buffer = StringBuffer();
        for (final res in results) {
          final t = res.item(0).transcript;
          if (t != null && t.isNotEmpty) buffer.write(t);
        }
        final transcript = buffer.toString().trim();
        if (transcript.isNotEmpty) onResult(transcript);
      }
    });

    recognition.onEnd.listen((_) => onEnd());
    recognition.onError.listen((event) {
      final error = (event.error ?? '').toString();
      if (error == 'no-speech' || error == 'aborted') return;
      if (error == 'not-allowed') {
        onError('Microphone access denied. Please click the site icon in address bar to Allow.');
      } else {
        onError('Speech notice: $error');
      }
      onEnd();
    });

    recognition.start();
  } catch (e) {
    onError('Microphone not available in this browser: $e');
    onEnd();
  }
}

/// Stops any active SpeechRecognition session.
void _stopWebSpeechRecognition() {
  try {
    final speechObj = js.context['__vernexaSpeech'];
    if (speechObj != null) {
      speechObj.callMethod('stop');
    }
    _activeRecognition?.stop();
    _activeRecognition = null;
  } catch (_) {}
}

List<html.SpeechSynthesisVoice> _cachedBrowserVoices = [];

void _initBrowserVoices() {
  try {
    final synth = html.window.speechSynthesis;
    if (synth != null) {
      if (_cachedBrowserVoices.isEmpty) {
        _cachedBrowserVoices = synth.getVoices();
      }
      synth.addEventListener('voiceschanged', (_) {
        _cachedBrowserVoices = synth.getVoices();
      });
    }
  } catch (_) {}
}

/// Speaks text via the browser's SpeechSynthesis API with full fallback support.
///
/// NOTE on Tribal Languages & Ol Chiki:
/// Browser speech engines (Google, Apple, Microsoft) do not have phoneme models
/// for Santali Ol Chiki glyphs (\u1C50-\u1C7F). Passing raw Ol Chiki to Web SpeechSynthesis
/// outputs silence. Therefore, when text contains Ol Chiki or when speaking Santali,
/// this synthesizer speaks the Romanized phonetic pronunciation using an Indian voice (en-IN / hi-IN).
void _speakText({
  required String text,
  required String langName,
  String phoneticGuide = '',
  double rate = 1.0,
  void Function()? onFinished,
}) {
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      onFinished?.call();
      return;
    }

    _initBrowserVoices();

    // Cancel existing utterance & resume audio context (fixes Chromium pause bug)
    synth.cancel();
    synth.resume();

    final hasOlChiki = RegExp(r'[\u1C50-\u1C7F]').hasMatch(text);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);

    final voices = _cachedBrowserVoices.isNotEmpty ? _cachedBrowserVoices : synth.getVoices();
    final hasHindiVoice = voices.any((v) => (v.lang ?? '').toLowerCase().startsWith('hi') || (v.name ?? '').toLowerCase().contains('hindi') || (v.name ?? '').toLowerCase().contains('lekha'));

    String toSpeak = text;
    String targetSpeechLang = 'en-US';

    if (langName == 'English') {
      toSpeak = text;
      targetSpeechLang = 'en-US';
    } else if (langName == 'Hindi') {
      toSpeak = text;
      targetSpeechLang = 'hi-IN';
    } else if (hasOlChiki || langName == 'Santali') {
      // Santali / Ol Chiki has no browser TTS engine, must use Romanized phonetics
      if (phoneticGuide.trim().isNotEmpty && !RegExp(r'[\u1C50-\u1C7F]').hasMatch(phoneticGuide)) {
        toSpeak = phoneticGuide.trim();
      } else {
        toSpeak = olChikiToPhonetic(text.isNotEmpty ? text : phoneticGuide);
      }
      targetSpeechLang = 'en-IN';
    } else {
      // Tribal languages (Ho, Mundari, Kurukh, Gondi):
      // If Hindi voice is installed in browser, speaking cleaned Devanagari provides native Indian vocal articulation
      if (hasHindiVoice && hasDevanagari) {
        toSpeak = text.replaceAll(':', 'ह').replaceAll('ः', 'ह');
        targetSpeechLang = 'hi-IN';
      } else if (phoneticGuide.trim().isNotEmpty && !RegExp(r'[\u0900-\u097F]').hasMatch(phoneticGuide)) {
        // Fallback to Romanized phonetic guide with Indian English voice
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

    // Clean glottal colons ':', visarga 'ः', or Devanagari danda that cause TTS stutters
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

    utterance.onEnd.listen((_) => onFinished?.call());
    utterance.onError.listen((_) => onFinished?.call());

    synth.speak(utterance);
  } catch (_) {
    onFinished?.call();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class RealTimeTranslationScreen extends StatefulWidget {
  const RealTimeTranslationScreen({super.key});

  @override
  State<RealTimeTranslationScreen> createState() => _RealTimeTranslationScreenState();
}

class _RealTimeTranslationScreenState extends State<RealTimeTranslationScreen>
    with SingleTickerProviderStateMixin {
  bool _isTeacherToStudent = true;
  bool _isRecording = false;
  bool _isTranslating = false;
  bool _isPlayingTranslation = false;
  bool _isSlowSpeech = false;
  String _selectedCategory = 'All';

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  // Clean empty state initially to prevent lingering text from another language
  String _currentSourceText = '';
  String _currentTranslatedText = '';
  String _currentPhonetic = '';
  final Set<String> _favoriteIds = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _audioTimer;
  Timer? _recordingTimer;

  static const List<String> _teacherCategories = [
    'All',
    'Greetings',
    'Maths',
    'Instruction',
    'Discipline',
    'Question',
    'Praise',
  ];

  static const List<String> _studentCategories = [
    'All',
    'Needs',
    'Questions',
    'Tasks',
    'Health',
    'Numbers',
  ];

  List<String> get _currentCategories =>
      _isTeacherToStudent ? _teacherCategories : _studentCategories;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial state is clean and ready for user input
    _inputController.text = '';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioTimer?.cancel();
    _recordingTimer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String get _sourceLang => _isTeacherToStudent
      ? AppState.instance.teacherLanguage
      : AppState.instance.studentLanguage;

  String get _targetLang => _isTeacherToStudent
      ? AppState.instance.studentLanguage
      : AppState.instance.teacherLanguage;

  /// BCP-47 code for the source language (used with SpeechRecognition).
  String get _sourceSpeechLang {
    switch (_sourceLang) {
      case 'English':
        return 'en-IN'; // en-IN provides superior recognition for Indian accents
      default:
        return 'hi-IN'; // Hindi & tribal languages fall back to hi-IN
    }
  }

  Future<void> _runTranslation(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _currentSourceText = query;
    });

    final result = await TranslationService.instance.translate(
      text: query,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
      isTeacherSpeaker: _isTeacherToStudent,
    );

    if (mounted) {
      setState(() {
        _isTranslating = false;
        _currentTranslatedText = result.translatedText;
        _currentPhonetic = result.phoneticGuide;
      });
    }
  }

  void _switchDirection(bool teacherToStudent) {
    if (_isTeacherToStudent == teacherToStudent) return;
    setState(() {
      _isTeacherToStudent = teacherToStudent;
      // Clear fields to avoid displaying text from another language
      _inputController.clear();
      _currentSourceText = '';
      _currentTranslatedText = '';
      _currentPhonetic = '';
      _selectedCategory = 'All';
    });
  }

  void _swapLanguages() {
    setState(() {
      _isTeacherToStudent = !_isTeacherToStudent;
      _selectedCategory = 'All';
      if (_currentTranslatedText.isNotEmpty) {
        final temp = _currentSourceText;
        _currentSourceText = _currentTranslatedText;
        _currentTranslatedText = temp;
        _inputController.text = _currentSourceText;
        _runTranslation(_currentSourceText);
      } else {
        _inputController.clear();
        _currentSourceText = '';
        _currentTranslatedText = '';
        _currentPhonetic = '';
      }
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      // ── Stop: cancel any in-flight recognition ──────────────────────────
      _recordingTimer?.cancel();
      setState(() => _isRecording = false);
      _stopWebSpeechRecognition();
      final captured = _inputController.text.trim();
      if (captured.isNotEmpty) {
        _runTranslation(captured);
      }
    } else {
      // ── Start: open real browser SpeechRecognition ─────────────────────
      setState(() {
        _isRecording = true;
        _isTranslating = false;
        _inputController.clear();
        _currentSourceText = '';
      });

      _startWebSpeechRecognition(
        langCode: _sourceSpeechLang,
        onResult: (transcript) {
          if (mounted) {
            setState(() {
              _inputController.text = transcript;
              _currentSourceText = transcript;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                content: Text(err, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            );
          }
        },
        onEnd: () {
          if (mounted && _isRecording) {
            setState(() => _isRecording = false);
            final captured = _inputController.text.trim();
            if (captured.isNotEmpty) {
              _runTranslation(captured);
            }
          }
        },
      );

      // Safety net: stop after 30 seconds of continuous listening
      _recordingTimer?.cancel();
      _recordingTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isRecording) {
          setState(() => _isRecording = false);
          _stopWebSpeechRecognition();
          if (_inputController.text.trim().isNotEmpty) {
            _runTranslation(_inputController.text);
          }
        }
      });
    }
  }

  void _playTranslationAudio() {
    if (_currentTranslatedText.isEmpty && _currentPhonetic.isEmpty) return;

    setState(() => _isPlayingTranslation = true);

    final rate = _isSlowSpeech ? 0.75 : 1.0;
    _speakText(
      text: _currentTranslatedText,
      langName: _targetLang,
      phoneticGuide: _currentPhonetic,
      rate: rate,
      onFinished: () {
        if (mounted) setState(() => _isPlayingTranslation = false);
      },
    );

    final speedText = _isSlowSpeech ? ' (Slow 0.75×)' : '';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF5C27D8),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Speaking in $_targetLang$speedText: ${_currentPhonetic.isNotEmpty ? _currentPhonetic : _currentTranslatedText}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    _audioTimer?.cancel();
    final textLen = _currentTranslatedText.length;
    final estimatedMs = (textLen * (rate < 1.0 ? 120 : 80)).clamp(2000, 8000);
    _audioTimer = Timer(Duration(milliseconds: estimatedMs), () {
      if (mounted) setState(() => _isPlayingTranslation = false);
    });
  }

  void _playSourceAudio() {
    if (_currentSourceText.isEmpty) return;
    final rate = _isSlowSpeech ? 0.75 : 1.0;
    _speakText(
      text: _currentSourceText,
      langName: _sourceLang,
      rate: rate,
    );
  }

  /// Interactive teacher reply to student in Student -> Teacher mode
  void _replyToStudent() {
    final studentQuery = _currentSourceText.toLowerCase();
    String teacherReply = 'हाँ, ठीक है।';
    if (studentQuery.contains('दा:') || studentQuery.contains('पानी') || studentQuery.contains('water') || studentQuery.contains('dag')) {
      teacherReply = 'हाँ, पानी पी लो।';
    } else if (studentQuery.contains('बाहर') || studentQuery.contains('bahar') || studentQuery.contains('toilet') || studentQuery.contains('bahre')) {
      teacherReply = 'हाँ, बाहर चले जाओ।';
    } else if (studentQuery.contains('पुथी') || studentQuery.contains('किताब') || studentQuery.contains('कलम') || studentQuery.contains('kalam')) {
      teacherReply = 'यह किताब और कलम ले लो और लिखो।';
    } else if (studentQuery.contains('समझ') || studentQuery.contains('बुझाव') || studentQuery.contains('काइंग') || studentQuery.contains('bujhaw') || studentQuery.contains('बुझिया') || studentQuery.contains('bujhiya')) {
      teacherReply = 'ध्यान से सुनो, मैं दोबारा समझाता हूँ।';
    } else if (studentQuery.contains('चाबा') || studentQuery.contains('काम') || studentQuery.contains('puraw') || studentQuery.contains('chaba')) {
      teacherReply = 'शाबाश! बहुत अच्छा काम किया।';
    } else if (studentQuery.contains('लाज') || studentQuery.contains('पेट') || studentQuery.contains('दर्द') || studentQuery.contains('रुआ') || studentQuery.contains('रुवा') || studentQuery.contains('बोः') || studentQuery.contains('hasu') || studentQuery.contains('boh')) {
      teacherReply = 'आराम करो, हम प्राथमिक उपचार करेंगे।';
    } else if (studentQuery.contains('जीव का बुगिन') || studentQuery.contains('jeev ka bugin')) {
      teacherReply = 'हाँ, आराम करो और घर चले जाओ।';
    } else if (studentQuery.contains('नुतुम') || studentQuery.contains('nutum') || studentQuery.contains('नाम') || studentQuery.contains('name')) {
      teacherReply = 'मेरा नाम शिक्षक है, आपका नाम क्या है?';
    } else if (studentQuery.contains('उमुर') || studentQuery.contains('umur') || studentQuery.contains('उम्र') || studentQuery.contains('age')) {
      teacherReply = 'आपकी उम्र कितनी है?';
    } else if (studentQuery.contains('जोहार') || studentQuery.contains('johar') || studentQuery.contains('नमस्ते')) {
      teacherReply = 'जोहार बच्चों! आप सब कैसे हैं?';
    }

    setState(() {
      _isTeacherToStudent = true;
      _inputController.text = teacherReply;
      _currentSourceText = teacherReply;
      _selectedCategory = 'All';
    });
    _runTranslation(teacherReply);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  void _showLanguageSelector({required bool isTeacher}) {
    final current = isTeacher ? AppState.instance.teacherLanguage : AppState.instance.studentLanguage;
    final other = isTeacher ? AppState.instance.studentLanguage : AppState.instance.teacherLanguage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDD8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isTeacher ? 'Select Teacher Language' : 'Select Student Language',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF261080),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vernexa automatically adapts dialect and phonetics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF6F62AB),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: TranslationService.supportedLanguages.map((lang) {
                      final isSelected = lang == current;
                      final isOther = lang == other;

                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5C27D8)
                                : const Color(0xFFF3F0FA),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check : Icons.language,
                            color: isSelected ? Colors.white : const Color(0xFF6F62AB),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          lang,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF261080),
                          ),
                        ),
                        subtitle: Text(
                          _getLanguageSubtitle(lang),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF8B81B8)),
                        ),
                        trailing: isOther
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECE8FB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Paired',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5C27D8),
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            if (isTeacher) {
                              AppState.instance.updateClassroomSetup(tLang: lang);
                            } else {
                              AppState.instance.updateClassroomSetup(sLang: lang);
                            }
                            // Clear fields to avoid displaying text from another language
                            _inputController.clear();
                            _currentSourceText = '';
                            _currentTranslatedText = '';
                            _currentPhonetic = '';
                            _selectedCategory = 'All';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF5C27D8),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              content: Text(
                                '${isTeacher ? "Teacher" : "Student"} language set to $lang. Ready for translation.',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLanguageSubtitle(String lang) {
    switch (lang) {
      case 'Hindi':
        return 'हिन्दी (National Language)';
      case 'English':
        return 'Standard Classroom English';
      case 'Mundari':
        return 'मुण्डारी (Jharkhand / Odisha / WB)';
      case 'Santali':
        return 'ᱥᱟᱱᱛᱟᱲᱤ / संताली (Ol Chiki)';
      case 'Ho':
        return 'ᱦᱳ / हो (Kolhan & Mayurbhanj)';
      case 'Kurukh':
        return 'कुड़ुख़ / उरांव (Chota Nagpur)';
      case 'Gondi':
        return 'गोंडी (Central India)';
      default:
        return 'Regional dialect';
    }
  }

  bool get _isCloudConfigured =>
      GeminiTranslationService.instance.config.isConfigured;

  String get _activeEngineLabel {
    if (GeminiTranslationService.instance.config.isConfigured) {
      return 'Gemini AI: Online';
    } else {
      return 'Offline Lexicon Mode';
    }
  }

  void _showEngineSettingsDialog() {
    final geminiCfg = GeminiTranslationService.instance.config;
    final geminiKeyCtrl = TextEditingController(text: geminiCfg.apiKey);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF5C27D8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini AI Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF261080),
                      ),
                    ),
                    Text(
                      'Real-time neural tribal language translation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6F62AB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Google Gemini 1.5 Flash is active with Vernexa\'s authentic tribal lexicon system instructions.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF15803D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: geminiKeyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Enter API Key...',
                    prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF5C27D8), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Saved permanently in your browser (you only need to enter it once!).\n• Free instant key from aistudio.google.com.\n• If cleared, Vernexa falls back seamlessly to the built-in offline phrasebook.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF8B81B8), height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            if (geminiCfg.apiKey.isNotEmpty)
              TextButton(
                onPressed: () {
                  GeminiTranslationService.instance.updateApiKey('');
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF6F62AB),
                      content: Text('API Key cleared. Switched to offline phrasebook mode.'),
                    ),
                  );
                },
                child: const Text('Clear Key', style: TextStyle(color: Color(0xFFDC2626))),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C27D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                GeminiTranslationService.instance.updateApiKey(geminiKeyCtrl.text);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF16A34A),
                    content: Text(
                      _isCloudConfigured
                          ? 'Gemini AI configured and saved permanently!'
                          : 'Offline curriculum phrasebook mode active.',
                    ),
                  ),
                );
                if (_isCloudConfigured && _currentSourceText.isNotEmpty) {
                  _runTranslation(_currentSourceText);
                }
              },
              child: const Text('Save & Remember'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF5C27D8);
    const bgColor = Colors.white;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: primaryPurple,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                ),
              title: Text(
                'Real-Time Translation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Gemini AI Settings',
                  icon: Icon(
                    GeminiTranslationService.instance.config.isConfigured
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_queue_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _showEngineSettingsDialog,
                ),
                IconButton(
                  tooltip: 'Swap Languages',
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                  onPressed: _swapLanguages,
                ),
              ],
            ),
      body: SafeArea(
        bottom: false,
        child: isDesktop
            ? Row(
                children: [
                  const VernexaDesktopSidebar(currentIndex: 2),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 960),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                        child: _buildDesktopVerticalLayout(context, primaryPurple),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildDirectionAndLanguageCard(primaryPurple),
                          const SizedBox(height: 18),
                          _buildMicAndInputSection(primaryPurple, isDesktop: false),
                          const SizedBox(height: 20),
                          _buildTranslationResultCard(primaryPurple),
                          const SizedBox(height: 24),
                          _buildClassroomQuickChips(primaryPurple),
                          const SizedBox(height: 24),
                          _buildSessionHistorySection(primaryPurple),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  const VernexaBottomNav(currentIndex: 2),
                ],
              ),
      ),
      ),
    );
  }

  Widget _buildDesktopVerticalLayout(BuildContext context, Color primaryPurple) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF261080), size: 22),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-Time Translation Engine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF261080),
                        ),
                      ),
                      Text(
                        'Offline neural speech-to-speech & dual-script phonetics',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF6F62AB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: _showEngineSettingsDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: GeminiTranslationService.instance.config.isConfigured
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFECE8FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: GeminiTranslationService.instance.config.isConfigured
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFDDD8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        GeminiTranslationService.instance.config.isConfigured
                            ? Icons.cloud_done_rounded
                            : Icons.tune_rounded,
                        color: GeminiTranslationService.instance.config.isConfigured
                            ? const Color(0xFF10B981)
                            : const Color(0xFF5C27D8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _activeEngineLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: GeminiTranslationService.instance.config.isConfigured
                              ? const Color(0xFF047857)
                              : const Color(0xFF5C27D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main 2-column or stacked workspace
          _buildDirectionAndLanguageCard(primaryPurple),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Input + Mic
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildMicAndInputSection(primaryPurple, isDesktop: true),
                    const SizedBox(height: 18),
                    _buildClassroomQuickChips(primaryPurple),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Column: Translation Output + History
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildTranslationResultCard(primaryPurple),
                    const SizedBox(height: 20),
                    _buildSessionHistorySection(primaryPurple),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. Language & Direction Bar
  Widget _buildDirectionAndLanguageCard(Color primaryPurple) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E0F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF261080).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Direction Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionTab(
                title: 'Teacher → Student',
                isSelected: _isTeacherToStudent,
                onTap: () => _switchDirection(true),
              ),
              const SizedBox(width: 10),
              _buildDirectionTab(
                title: 'Student → Teacher',
                isSelected: !_isTeacherToStudent,
                onTap: () => _switchDirection(false),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Role Clarification Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isTeacherToStudent ? const Color(0xFFF3F0FA) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isTeacherToStudent ? const Color(0xFFDDD8F0) : const Color(0xFFA7F3D0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isTeacherToStudent ? Icons.record_voice_over_rounded : Icons.school_rounded,
                  color: _isTeacherToStudent ? primaryPurple : const Color(0xFF059669),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  _isTeacherToStudent
                      ? 'Teacher speaks in $_sourceLang → Student hears in $_targetLang'
                      : 'Student speaks in $_sourceLang → Teacher hears in $_targetLang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _isTeacherToStudent ? primaryPurple : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Language Cards with Tap-to-Change
          Row(
            children: [
              // Left (Source) Language
              Expanded(
                child: InkWell(
                  onTap: () => _showLanguageSelector(isTeacher: _isTeacherToStudent),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sourceLang,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF261080),
                                ),
                              ),
                              Text(
                                '${_isTeacherToStudent ? "Teacher" : "Student"} speaks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6F62AB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFEA580C)),
                      ],
                    ),
                  ),
                ),
              ),

              // Swap Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: _swapLanguages,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE8FB),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDD8F0)),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, color: primaryPurple, size: 22),
                  ),
                ),
              ),

              // Right (Target) Language
              Expanded(
                child: InkWell(
                  onTap: () => _showLanguageSelector(isTeacher: !_isTeacherToStudent),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.hearing_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _targetLang,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF261080),
                                ),
                              ),
                              Text(
                                '${_isTeacherToStudent ? "Student" : "Teacher"} hears',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6F62AB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF10B981)),
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

  // 2. Microphone & Input Section
  Widget _buildMicAndInputSection(Color primaryPurple, {required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E0F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF261080).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live Microphone Button
          GestureDetector(
            onTap: _toggleRecording,
            child: ScaleTransition(
              scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isRecording
                        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                        : [const Color(0xFF7C3AED), const Color(0xFF5C27D8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : primaryPurple).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _isRecording ? 'Listening in $_sourceLang... Tap to finish' : 'Tap Mic or Type below to translate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isRecording ? const Color(0xFFDC2626) : const Color(0xFF6F62AB),
            ),
          ),

          const SizedBox(height: 14),

          // Role-Aware Input Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTeacherToStudent ? '👩‍🏫 Teacher Input' : '🎓 Student Voice & Request',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF261080),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Source: $_sourceLang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Editable Speech Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    maxLines: 2,
                    minLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF261080),
                    ),
                    decoration: InputDecoration(
                      hintText: _isTeacherToStudent
                          ? 'Type teacher instruction in $_sourceLang...'
                          : 'Type or speak student phrase in $_sourceLang...',
                      hintStyle: const TextStyle(color: Color(0xFF9B91C2), fontSize: 13.5),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) => _runTranslation(val),
                  ),
                ),
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF8B81B8), size: 18),
                    onPressed: () {
                      _inputController.clear();
                      setState(() {
                        _currentSourceText = '';
                        _currentTranslatedText = '';
                        _currentPhonetic = '';
                      });
                    },
                  ),
                ElevatedButton(
                  onPressed: () => _runTranslation(_inputController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Translate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Translation Result & Phonetic Pronunciation Card
  Widget _buildTranslationResultCard(Color primaryPurple) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isTeacherToStudent ? const Color(0xFFE5E0F5) : const Color(0xFFA7F3D0),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF261080).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Mode Tag & Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isTeacherToStudent ? const Color(0xFFECE8FB) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTeacherToStudent ? Icons.record_voice_over_rounded : Icons.hearing_rounded,
                          size: 14,
                          color: _isTeacherToStudent ? primaryPurple : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isTeacherToStudent
                              ? 'Student Hears ($_targetLang)'
                              : 'Teacher Hears ($_targetLang)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isTeacherToStudent ? primaryPurple : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isTranslating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5C27D8)),
                    ),
                ],
              ),
              Row(
                children: [
                  // Slow Speech Speed Toggle (0.75x)
                  InkWell(
                    onTap: () {
                      setState(() => _isSlowSpeech = !_isSlowSpeech);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isSlowSpeech ? primaryPurple : const Color(0xFFF3F0FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isSlowSpeech ? '0.75x' : '1.0x',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isSlowSpeech ? Colors.white : const Color(0xFF6F62AB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Copy Translation',
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF6F62AB), size: 18),
                    onPressed: () => _copyToClipboard(_currentTranslatedText, '$_targetLang translation'),
                  ),
                ],
              ),
            ],
          ),

          // If Student-to-Teacher, show what the student said in tribal language first
          if (!_isTeacherToStudent && _currentSourceText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        'Student spoke in $_sourceLang:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _currentSourceText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Primary Native Script Output
          SelectableText(
            _currentTranslatedText.isNotEmpty ? _currentTranslatedText : 'Translation will appear here...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF261080),
              height: 1.4,
            ),
          ),

          if (_currentPhonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F4FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE9E5F7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_outlined, color: Color(0xFF5C27D8), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pronunciation: $_currentPhonetic',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B2D8C),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Primary Play Audio Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _playTranslationAudio,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTeacherToStudent ? primaryPurple : const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlayingTranslation ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isPlayingTranslation
                        ? 'Playing Voice...'
                        : 'Play Translation Voice ($_targetLang)',
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

          // Secondary Action Buttons for Student Mode: Hear Student & Reply
          if (!_isTeacherToStudent && _currentTranslatedText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (_currentSourceText.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _playSourceAudio,
                      icon: const Icon(Icons.volume_up_outlined, size: 16, color: Color(0xFF5C27D8)),
                      label: Text(
                        'Hear Student Voice',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF5C27D8)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDD8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if (_currentSourceText.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _replyToStudent,
                    icon: const Icon(Icons.reply_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Reply to Student',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. Quick Classroom Categories & Phrase Chips
  Widget _buildClassroomQuickChips(Color primaryPurple) {
    final phraseList = _isTeacherToStudent
        ? TranslationService.phrasebook
        : TranslationService.studentPhrasebook;

    final phrases = _selectedCategory == 'All'
        ? phraseList
        : phraseList.where((p) => p.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isTeacherToStudent
                  ? 'Teacher Classroom Quick Phrases'
                  : '🎓 Student Live Requests & Quick Phrases',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF261080),
              ),
            ),
            Text(
              _isTeacherToStudent ? 'Teacher speaks' : 'Tap to simulate student',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF8B81B8)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _currentCategories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                  },
                  selectedColor: _isTeacherToStudent ? primaryPurple : const Color(0xFF059669),
                  backgroundColor: const Color(0xFFF3F0FA),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? Colors.white : (_isTeacherToStudent ? const Color(0xFF5C27D8) : const Color(0xFF047857)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Quick Phrase Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: phrases.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = phrases[index];

            if (_isTeacherToStudent) {
              // Teacher mode: show Hindi/English phrase
              final textToUse = _sourceLang == 'English' ? p.english : p.hindi;

              return InkWell(
                onTap: () {
                  _inputController.text = textToUse;
                  _runTranslation(textToUse);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECE8FB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECE8FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF5C27D8), size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          textToUse,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF261080),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9B91C2), size: 12),
                    ],
                  ),
                ),
              );
            } else {
              // Student mode: show authentic Tribal phrase + phonetic + teacher translation
              final tribalText = p.translations[_sourceLang] ?? p.hindi;
              final phonetic = p.phonetics[_sourceLang] ?? '';
              final teacherMeaning = _targetLang == 'English' ? p.english : p.hindi;

              return InkWell(
                onTap: () {
                  _inputController.text = tribalText;
                  _runTranslation(tribalText);
                  // Auto-speak translation so the teacher hears the student request immediately
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _playTranslationAudio();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_outlined, color: Color(0xFF059669), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tribalText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                            if (phonetic.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phonetic,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF059669),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              'Meaning: $teacherMeaning',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B2D8C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Speak',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // 5. Real-Time Session Translation History
  Widget _buildSessionHistorySection(Color primaryPurple) {
    final history = TranslationService.instance.history;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Session Translation History',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF261080),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => TranslationService.instance.clearHistory());
              },
              child: Text(
                'Clear',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 5 ? 5 : history.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final rec = history[index];
            final isFav = _favoriteIds.contains(rec.id);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E0F5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${rec.sourceLanguage} → ${rec.targetLanguage}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rec.category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: const Color(0xFF8B81B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.sourceText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B2D8C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.translatedText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF261080),
                          ),
                        ),
                        if (rec.phoneticGuide.isNotEmpty)
                          Text(
                            rec.phoneticGuide,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF6F62AB),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFav ? const Color(0xFFEAB308) : const Color(0xFF9B91C2),
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(rec.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6F62AB), size: 18),
                    onPressed: () {
                      _inputController.text = rec.sourceText;
                      _runTranslation(rec.sourceText);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDirectionTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFECE8FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6F62AB),
          ),
        ),
      ),
    );
  }
}
