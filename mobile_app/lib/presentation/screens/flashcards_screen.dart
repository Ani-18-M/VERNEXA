import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

import '../../core/app_state.dart';
import '../../core/translation_service.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class FlashcardItem {
  final String id;
  final String label; // English
  final String phoneticEn;
  final String imageAsset;
  final String webPath;
  final IconData fallbackIcon;
  final String category;
  final String hindi;
  final String phoneticHi;
  final Map<String, String> tribalTranslations;
  final Map<String, String> tribalPhonetics;
  final String exampleEn;
  final Map<String, String> exampleTribal;

  const FlashcardItem({
    required this.id,
    required this.label,
    required this.phoneticEn,
    required this.imageAsset,
    required this.webPath,
    required this.fallbackIcon,
    required this.category,
    required this.hindi,
    required this.phoneticHi,
    required this.tribalTranslations,
    required this.tribalPhonetics,
    required this.exampleEn,
    required this.exampleTribal,
  });
}

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  static const Color _purple = Color(0xFF5C27D8);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _bg = Color(0xFFF8F6FD);

  int _selectedCategoryIndex = 0;
  int _currentCardIndex = 0;
  late String _currentLanguage;
  bool _isAutoPlaying = false;
  bool _isGridView = false;
  Timer? _autoPlayTimer;
  String? _currentlySpeakingText;
  final Set<String> _bookmarkedIds = {};
  final FocusNode _keyboardFocusNode = FocusNode();

  final List<String> _categories = [
    'All',
    'Fruits',
    'Animals',
    'Numbers',
    'Classroom',
  ];

  static const List<String> _availableLanguages = [
    'Santali',
    'Ho',
    'Mundari',
    'Kurukh',
    'Gondi',
  ];

  // Master all-in-one 2D generated sheets for each category
  static const Map<String, String> _categorySheets = {
    'Fruits': 'flashcards/fruits_sheet.jpg',
    'Animals': 'flashcards/animals_sheet.jpg',
    'Numbers': 'flashcards/numbers_sheet.jpg',
    'Classroom': 'flashcards/classroom_sheet.jpg',
  };

  // 32 Precision-Connected 2D Educational Flashcards
  static const List<FlashcardItem> _allCards = [
    // ── Fruits (8 items cropped from fruits_sheet) ───────────────────────────
    FlashcardItem(
      id: 'f_apple',
      label: 'Apple',
      phoneticEn: 'ap-uhl',
      imageAsset: 'assets/images/flashcards/fruits/apple.png',
      webPath: 'flashcards/fruits/apple.png',
      fallbackIcon: Icons.apple,
      category: 'Fruits',
      hindi: 'सेब',
      phoneticHi: 'Seb',
      tribalTranslations: {
        'Santali': 'ᱥᱮᱣ',
        'Ho': 'सेब',
        'Mundari': 'सेब',
        'Kurukh': 'सेब',
        'Gondi': 'सेब',
      },
      tribalPhonetics: {
        'Santali': 'Sew',
        'Ho': 'Seb',
        'Mundari': 'Seb',
        'Kurukh': 'Seb',
        'Gondi': 'Seb',
      },
      exampleEn: 'This is a sweet red apple.',
      exampleTribal: {
        'Santali': 'ᱱᱚᱣᱟ ᱫᱚ ᱢᱤᱫᱴᱟᱝ ᱦᱮᱲᱮᱢ ᱟᱨᱟᱜ ᱥᱮᱣ ᱠᱟᱱᱟ᱾',
        'Ho': 'नेना मियद हेड़ेम सेब तानांग।',
        'Mundari': 'नेया मियद हेड़ेम सेब तानांग।',
        'Kurukh': 'ई ओन्त दाव सेब रई।',
        'Gondi': 'इद उंदी बेसे सेब आंद।',
      },
    ),
    FlashcardItem(
      id: 'f_banana',
      label: 'Banana',
      phoneticEn: 'buh-nan-uh',
      imageAsset: 'assets/images/flashcards/fruits/banana.png',
      webPath: 'flashcards/fruits/banana.png',
      fallbackIcon: Icons.eco_rounded,
      category: 'Fruits',
      hindi: 'केला',
      phoneticHi: 'Kela',
      tribalTranslations: {
        'Santali': 'ᱠᱟᱭᱨᱟ',
        'Ho': 'कएरा',
        'Mundari': 'कएरा',
        'Kurukh': 'केड़ा',
        'Gondi': 'केड़ा',
      },
      tribalPhonetics: {
        'Santali': 'Kayra',
        'Ho': 'Kaera',
        'Mundari': 'Kaera',
        'Kurukh': 'Keda',
        'Gondi': 'Keda',
      },
      exampleEn: 'Monkeys love eating ripe bananas.',
      exampleTribal: {
        'Santali': 'ᱜᱟᱹᱲᱤ ᱫᱚ ᱵᱤᱞᱤ ᱠᱟᱭᱨᱟ ᱡᱚᱢ ᱠᱚ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ᱾',
        'Ho': 'गाड़ीको बिला कएरा जोमे सुकुवा।',
        'Mundari': 'साड़ाको बिला कएरा जोमे सुकुवा।',
        'Kurukh': 'बंदर बिला केड़ा ओना चाखनर।',
        'Gondi': 'कोवे बिला केड़ा तिनजोर मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'f_mango',
      label: 'Mango',
      phoneticEn: 'mang-goh',
      imageAsset: 'assets/images/flashcards/fruits/mango.png',
      webPath: 'flashcards/fruits/mango.png',
      fallbackIcon: Icons.nature_rounded,
      category: 'Fruits',
      hindi: 'आम',
      phoneticHi: 'Aam',
      tribalTranslations: {
        'Santali': 'ᱩᱞ',
        'Ho': 'उल',
        'Mundari': 'उल',
        'Kurukh': 'ततख़ा',
        'Gondi': 'मड़का',
      },
      tribalPhonetics: {
        'Santali': 'Ool',
        'Ho': 'Ool',
        'Mundari': 'Ool',
        'Kurukh': 'Tatkha',
        'Gondi': 'Marka',
      },
      exampleEn: 'Mango is the king of fruits.',
      exampleTribal: {
        'Santali': 'ᱩᱞ ᱫᱚ ᱡᱚ ᱠᱚ ᱨᱤᱱᱤᱡ ᱨᱟᱡᱟ ᱠᱟᱱᱟᱭ᱾',
        'Ho': 'उल जोको रेयाग राजा तानांग।',
        'Mundari': 'उल जोकोआग राजा तानांग।',
        'Kurukh': 'ततख़ा सब्भे ख़ख़ा गही राजा रई।',
        'Gondi': 'मड़का सब फल ता राजा आंद।',
      },
    ),
    FlashcardItem(
      id: 'f_orange',
      label: 'Orange',
      phoneticEn: 'or-inj',
      imageAsset: 'assets/images/flashcards/fruits/orange.png',
      webPath: 'flashcards/fruits/orange.png',
      fallbackIcon: Icons.wb_sunny_rounded,
      category: 'Fruits',
      hindi: 'संतरा',
      phoneticHi: 'Santra',
      tribalTranslations: {
        'Santali': 'ᱥᱟᱱᱛᱨᱟ',
        'Ho': 'संतोला',
        'Mundari': 'संतोरा',
        'Kurukh': 'संतरा',
        'Gondi': 'नारंगी',
      },
      tribalPhonetics: {
        'Santali': 'Santra',
        'Ho': 'Santola',
        'Mundari': 'Santora',
        'Kurukh': 'Santra',
        'Gondi': 'Narangi',
      },
      exampleEn: 'Oranges are juicy and full of vitamins.',
      exampleTribal: {
        'Santali': 'ᱥᱟᱱᱛᱨᱟ ᱨᱮ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱜᱩᱱ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'संतोला रे एशू बुगिन गुन मेना:।',
        'Mundari': 'संतोरा रे बेस गुन मेना:।',
        'Kurukh': 'संतरा नू कोड़े गुन रई।',
        'Gondi': 'नारंगी ते मंचा गुन आंद।',
      },
    ),
    FlashcardItem(
      id: 'f_grapes',
      label: 'Grapes',
      phoneticEn: 'grayps',
      imageAsset: 'assets/images/flashcards/fruits/grapes.png',
      webPath: 'flashcards/fruits/grapes.png',
      fallbackIcon: Icons.bubble_chart_rounded,
      category: 'Fruits',
      hindi: 'अंगूर',
      phoneticHi: 'Angoor',
      tribalTranslations: {
        'Santali': 'ᱟᱝᱜᱩᱨ',
        'Ho': 'अंगुर',
        'Mundari': 'अंगुर',
        'Kurukh': 'अंगूर',
        'Gondi': 'अंगूर',
      },
      tribalPhonetics: {
        'Santali': 'Angur',
        'Ho': 'Angur',
        'Mundari': 'Angur',
        'Kurukh': 'Angoor',
        'Gondi': 'Angoor',
      },
      exampleEn: 'These purple grapes are very sweet.',
      exampleTribal: {
        'Santali': 'ᱱᱚᱣᱟ ᱟᱝᱜᱩᱨ ᱫᱚ ᱟᱹᱰᱤ ᱦᱮᱲᱮᱢᱟ᱾',
        'Ho': 'नेना अंगुर एशू हेड़ेमा तानांग।',
        'Mundari': 'नेया अंगुर पुरो हेड़ेमा।',
        'Kurukh': 'ई अंगूर कोड़े दाव रई।',
        'Gondi': 'इद अंगूर गच्ची बेसे आंद।',
      },
    ),
    FlashcardItem(
      id: 'f_papaya',
      label: 'Papaya',
      phoneticEn: 'puh-py-uh',
      imageAsset: 'assets/images/flashcards/fruits/papaya.png',
      webPath: 'flashcards/fruits/papaya.png',
      fallbackIcon: Icons.spa_rounded,
      category: 'Fruits',
      hindi: 'पपीता',
      phoneticHi: 'Papita',
      tribalTranslations: {
        'Santali': 'ᱯᱚᱯᱤᱛᱟ',
        'Ho': 'पपीता',
        'Mundari': 'पपीता',
        'Kurukh': 'एरंगडी',
        'Gondi': 'पपीता',
      },
      tribalPhonetics: {
        'Santali': 'Papita',
        'Ho': 'Papita',
        'Mundari': 'Papita',
        'Kurukh': 'Erangdi',
        'Gondi': 'Papita',
      },
      exampleEn: 'Ripe papaya is good for health.',
      exampleTribal: {
        'Santali': 'ᱵᱤᱞᱤ ᱯᱚᱯᱤᱛᱟ ᱦᱚᱲᱢᱚ ᱞᱟᱹᱜᱤᱫ ᱵᱷᱟᱹᱜᱤᱭᱟ᱾',
        'Ho': 'बिला पपीता जीव ल़गिड बुगिना।',
        'Mundari': 'बिला पपीता होड़मो ल़गिड बेसा।',
        'Kurukh': 'एरंगडी जीया गही कोड़े रई।',
        'Gondi': 'पपीता सेहत काजे बेसे आंद।',
      },
    ),
    FlashcardItem(
      id: 'f_guava',
      label: 'Guava',
      phoneticEn: 'gwah-vuh',
      imageAsset: 'assets/images/flashcards/fruits/guava.png',
      webPath: 'flashcards/fruits/guava.png',
      fallbackIcon: Icons.grass_rounded,
      category: 'Fruits',
      hindi: 'अमरूद',
      phoneticHi: 'Amrood',
      tribalTranslations: {
        'Santali': 'ᱟᱢᱨᱩᱫᱽ',
        'Ho': 'अमरुद',
        'Mundari': 'अमरुद',
        'Kurukh': 'अमरुद',
        'Gondi': 'जामा',
      },
      tribalPhonetics: {
        'Santali': 'Amrud',
        'Ho': 'Amrud',
        'Mundari': 'Amrud',
        'Kurukh': 'Amrud',
        'Gondi': 'Jama',
      },
      exampleEn: 'Guavas grow in our village orchard.',
      exampleTribal: {
        'Santali': 'ᱟᱢᱨᱩᱫᱽ ᱫᱚ ᱵᱟᱜᱟᱱ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'अमरुद बगान रे मेना:।',
        'Mundari': 'अमरुद बागीचा रे मेना:।',
        'Kurukh': 'अमरुद बागान नू रई।',
        'Gondi': 'जामा बारी ते मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'f_watermelon',
      label: 'Watermelon',
      phoneticEn: 'wah-ter-mel-un',
      imageAsset: 'assets/images/flashcards/fruits/watermelon.png',
      webPath: 'flashcards/fruits/watermelon.png',
      fallbackIcon: Icons.pie_chart_rounded,
      category: 'Fruits',
      hindi: 'तरबूज',
      phoneticHi: 'Tarbooz',
      tribalTranslations: {
        'Santali': 'ᱛᱟᱹᱨᱵᱩᱡᱽ',
        'Ho': 'तरबुज',
        'Mundari': 'तरबुज',
        'Kurukh': 'तरबूज',
        'Gondi': 'तरबूज',
      },
      tribalPhonetics: {
        'Santali': 'Tarbooj',
        'Ho': 'Tarbooj',
        'Mundari': 'Tarbooj',
        'Kurukh': 'Tarbooj',
        'Gondi': 'Tarbooj',
      },
      exampleEn: 'Watermelon is refreshing in summer.',
      exampleTribal: {
        'Santali': 'ᱥᱤᱛᱩᱝ ᱫᱤᱱ ᱛᱟᱹᱨᱵᱩᱡᱽ ᱡᱚᱢ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭᱟ᱾',
        'Ho': 'जेटे सिंगी तरबुज जोमे एशू बुगिना।',
        'Mundari': 'जेटे सिंगी तरबुज जोमे पुरो बेसा।',
        'Kurukh': 'गर्मी नू तरबूज ओना कोड़े रई।',
        'Gondi': 'धुपकाला ते तरबूज तिनजोर मन्ता।',
      },
    ),

    // ── Animals (8 items cropped from animals_sheet) ─────────────────────────
    FlashcardItem(
      id: 'a_elephant',
      label: 'Elephant',
      phoneticEn: 'el-uh-fuhnt',
      imageAsset: 'assets/images/flashcards/animals/elephant.png',
      webPath: 'flashcards/animals/elephant.png',
      fallbackIcon: Icons.pets_rounded,
      category: 'Animals',
      hindi: 'हाथी',
      phoneticHi: 'Haathi',
      tribalTranslations: {
        'Santali': 'ᱦᱟᱹᱛᱤ',
        'Ho': 'हाति',
        'Mundari': 'हाति',
        'Kurukh': 'हाथी',
        'Gondi': 'हाथी',
      },
      tribalPhonetics: {
        'Santali': 'Haati',
        'Ho': 'Hati',
        'Mundari': 'Hati',
        'Kurukh': 'Haathi',
        'Gondi': 'Haathi',
      },
      exampleEn: 'The elephant is a big animal in the forest.',
      exampleTribal: {
        'Santali': 'ᱦᱟᱹᱛᱤ ᱫᱚ ᱵᱤᱨ ᱨᱤᱱᱤᱡ ᱢᱟᱨᱟᱝ ᱡᱟᱱᱣᱟᱨ ᱠᱟᱱᱟᱭ᱾',
        'Ho': 'हाति बीर रेयाग मारांग जीव तानांग।',
        'Mundari': 'हाति बुरु रेयाग मारांग जीया तानांग।',
        'Kurukh': 'हाथी जंगल गही कोहा जीव रई।',
        'Gondi': 'हाथी काटो ता मोटो जानवर आंद।',
      },
    ),
    FlashcardItem(
      id: 'a_tiger',
      label: 'Tiger',
      phoneticEn: 'ty-ger',
      imageAsset: 'assets/images/flashcards/animals/tiger.png',
      webPath: 'flashcards/animals/tiger.png',
      fallbackIcon: Icons.flare_rounded,
      category: 'Animals',
      hindi: 'बाघ',
      phoneticHi: 'Baagh',
      tribalTranslations: {
        'Santali': 'ᱛᱟᱹᱨᱩᱵ',
        'Ho': 'कुल़ा',
        'Mundari': 'कुला',
        'Kurukh': 'लखरा',
        'Gondi': 'पुली',
      },
      tribalPhonetics: {
        'Santali': 'Tarub',
        'Ho': 'Kula',
        'Mundari': 'Kula',
        'Kurukh': 'Lakhra',
        'Gondi': 'Puli',
      },
      exampleEn: 'The Bengal tiger lives deep in the forest.',
      exampleTribal: {
        'Santali': 'ᱛᱟᱹᱨᱩᱵ ᱫᱚ ᱵᱤᱨ ᱨᱮ ᱛᱟᱦᱮᱸᱱᱟᱭ᱾',
        'Ho': 'कुला बीर रे तएना।',
        'Mundari': 'कुला बुरु रे तएना।',
        'Kurukh': 'लखरा जंगल नू रअई।',
        'Gondi': 'पुली काटो ते मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'a_cow',
      label: 'Cow',
      phoneticEn: 'kow',
      imageAsset: 'assets/images/flashcards/animals/cow.png',
      webPath: 'flashcards/animals/cow.png',
      fallbackIcon: Icons.agriculture_rounded,
      category: 'Animals',
      hindi: 'गाय',
      phoneticHi: 'Gaay',
      tribalTranslations: {
        'Santali': 'ᱜᱟᱹᱭ',
        'Ho': 'गायी',
        'Mundari': 'गायी',
        'Kurukh': 'ओई',
        'Gondi': 'मुर्रा',
      },
      tribalPhonetics: {
        'Santali': 'Gay',
        'Ho': 'Gayi',
        'Mundari': 'Gayi',
        'Kurukh': 'Oi',
        'Gondi': 'Murra',
      },
      exampleEn: 'The cow gives us sweet healthy milk.',
      exampleTribal: {
        'Santali': 'ᱜᱟᱹᱭ ᱫᱚ ᱛᱚᱣᱟᱭ ᱮᱢᱚᱜᱼᱟ᱾',
        'Ho': 'गायी तोआ एमा।',
        'Mundari': 'गायी तोआ एमा।',
        'Kurukh': 'ओई दूधी चीई।',
        'Gondi': 'मुर्रा पाल सीता।',
      },
    ),
    FlashcardItem(
      id: 'a_dog',
      label: 'Dog',
      phoneticEn: 'dawg',
      imageAsset: 'assets/images/flashcards/animals/dog.png',
      webPath: 'flashcards/animals/dog.png',
      fallbackIcon: Icons.pets_rounded,
      category: 'Animals',
      hindi: 'कुत्ता',
      phoneticHi: 'Kutta',
      tribalTranslations: {
        'Santali': 'ᱥᱮᱛᱟ',
        'Ho': 'सेता',
        'Mundari': 'सेता',
        'Kurukh': 'अल्ला',
        'Gondi': 'नइ',
      },
      tribalPhonetics: {
        'Santali': 'Seta',
        'Ho': 'Seta',
        'Mundari': 'Seta',
        'Kurukh': 'Alla',
        'Gondi': 'Nai',
      },
      exampleEn: 'The loyal dog guards the home.',
      exampleTribal: {
        'Santali': 'ᱥᱮᱛᱟ ᱫᱚ ᱵᱤᱥᱣᱟᱥᱤ ᱡᱟᱱᱣᱟᱨ ᱠᱟᱱᱟᱭ᱾',
        'Ho': 'सेता मियद बिसवासी जीव तानांग।',
        'Mundari': 'सेता बिसवासी जीया तानांग।',
        'Kurukh': 'अल्ला विश्वासी जीव रई।',
        'Gondi': 'नइ विश्वासी जानवर आंद।',
      },
    ),
    FlashcardItem(
      id: 'a_cat',
      label: 'Cat',
      phoneticEn: 'kat',
      imageAsset: 'assets/images/flashcards/animals/cat.png',
      webPath: 'flashcards/animals/cat.png',
      fallbackIcon: Icons.pest_control_rodent_rounded,
      category: 'Animals',
      hindi: 'बिल्ली',
      phoneticHi: 'Billi',
      tribalTranslations: {
        'Santali': 'ᱯᱩᱥᱤ',
        'Ho': 'पुसी',
        'Mundari': 'पुसी',
        'Kurukh': 'बरख़ा',
        'Gondi': 'वरकाल',
      },
      tribalPhonetics: {
        'Santali': 'Pusi',
        'Ho': 'Pusi',
        'Mundari': 'Pusi',
        'Kurukh': 'Barkha',
        'Gondi': 'Varkal',
      },
      exampleEn: 'The cat catches mice in the courtyard.',
      exampleTribal: {
        'Santali': 'ᱯᱩᱥᱤ ᱫᱚ ᱪᱩᱴᱤᱭᱟᱹᱭ ᱥᱟᱵ ᱠᱚᱣᱟ᱾',
        'Ho': 'पुसी चूटूकोके साबोवा।',
        'Mundari': 'पुसी चुटूके साबी।',
        'Kurukh': 'बरख़ा मूसा नू धरई।',
        'Gondi': 'वरकाल चुटी तुन पट्टा।',
      },
    ),
    FlashcardItem(
      id: 'a_bird',
      label: 'Bird',
      phoneticEn: 'burd',
      imageAsset: 'assets/images/flashcards/animals/bird.png',
      webPath: 'flashcards/animals/bird.png',
      fallbackIcon: Icons.flutter_dash_rounded,
      category: 'Animals',
      hindi: 'चिड़िया',
      phoneticHi: 'Chidiya',
      tribalTranslations: {
        'Santali': 'ᱪᱮᱬᱮ',
        'Ho': 'चेँड़े',
        'Mundari': 'चेँड़े',
        'Kurukh': 'ओड़ो',
        'Gondi': 'पिते',
      },
      tribalPhonetics: {
        'Santali': 'Chene',
        'Ho': 'Chende',
        'Mundari': 'Chende',
        'Kurukh': 'Odo',
        'Gondi': 'Pite',
      },
      exampleEn: 'The colorful bird flies across the blue sky.',
      exampleTribal: {
        'Santali': 'ᱪᱮᱬᱮ ᱫᱚ ᱥᱮᱨᱢᱟ ᱨᱮ ᱩᱰᱟᱹᱣᱜᱼᱟᱭ᱾',
        'Ho': 'चेँड़े सिरमा रे उड़ियवा।',
        'Mundari': 'चेँड़े सिरमा रे उड़िवा।',
        'Kurukh': 'ओड़ो आसमान नू उड़ारई।',
        'Gondi': 'पिते अकास ते उडियान्ता।',
      },
    ),
    FlashcardItem(
      id: 'a_fish',
      label: 'Fish',
      phoneticEn: 'fish',
      imageAsset: 'assets/images/flashcards/animals/fish.png',
      webPath: 'flashcards/animals/fish.png',
      fallbackIcon: Icons.water_rounded,
      category: 'Animals',
      hindi: 'मछली',
      phoneticHi: 'Machhli',
      tribalTranslations: {
        'Santali': 'ᱦᱟᱠᱳ',
        'Ho': 'हाकु',
        'Mundari': 'हाकु',
        'Kurukh': 'इंजो',
        'Gondi': 'मीन',
      },
      tribalPhonetics: {
        'Santali': 'Hako',
        'Ho': 'Haku',
        'Mundari': 'Haku',
        'Kurukh': 'Injo',
        'Gondi': 'Meen',
      },
      exampleEn: 'Fish swim gracefully in fresh water.',
      exampleTribal: {
        'Santali': 'ᱦᱟᱠᱳ ᱫᱚ ᱫᱟᱜ ᱨᱮ ᱠᱚ ᱛᱟᱦᱮᱸᱱᱟ᱾',
        'Ho': 'हाकु दा: रे तएना।',
        'Mundari': 'हाकु दा: रे तएना।',
        'Kurukh': 'इंजो अम नू रअई।',
        'Gondi': 'मीन येर ते मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'a_horse',
      label: 'Horse',
      phoneticEn: 'hors',
      imageAsset: 'assets/images/flashcards/animals/horse.png',
      webPath: 'flashcards/animals/horse.png',
      fallbackIcon: Icons.directions_run_rounded,
      category: 'Animals',
      hindi: 'घोड़ा',
      phoneticHi: 'Ghoda',
      tribalTranslations: {
        'Santali': 'ᱥᱟᱫᱚᱢ',
        'Ho': 'सादाम',
        'Mundari': 'सादाम',
        'Kurukh': 'घोड़ो',
        'Gondi': 'कोड़ा',
      },
      tribalPhonetics: {
        'Santali': 'Sadom',
        'Ho': 'Sadam',
        'Mundari': 'Sadam',
        'Kurukh': 'Ghodo',
        'Gondi': 'Koda',
      },
      exampleEn: 'The strong horse runs swiftly across fields.',
      exampleTribal: {
        'Santali': 'ᱥᱟᱫᱚᱢ ᱫᱚ ᱟᱹᱰᱤ ᱞᱚᱜᱚᱱ ᱮ ᱫᱟᱹᱲᱟ᱾',
        'Ho': 'सादाम एशू चाल़ाके निरवा।',
        'Mundari': 'सादाम पुरो चालाके निरवा।',
        'Kurukh': 'घोड़ो जोरे कुदरई।',
        'Gondi': 'कोड़ा जोरे विटता।',
      },
    ),

    // ── Numbers (8 items cropped from numbers_sheet) ─────────────────────────
    FlashcardItem(
      id: 'n_1',
      label: 'One (1)',
      phoneticEn: 'wun',
      imageAsset: 'assets/images/flashcards/numbers/1.png',
      webPath: 'flashcards/numbers/1.png',
      fallbackIcon: Icons.looks_one_rounded,
      category: 'Numbers',
      hindi: 'एक (१)',
      phoneticHi: 'Ek',
      tribalTranslations: {
        'Santali': 'ᱢᱤᱫ',
        'Ho': 'मियद',
        'Mundari': 'मियद',
        'Kurukh': 'ओन्त',
        'Gondi': 'उंदी',
      },
      tribalPhonetics: {
        'Santali': 'Mit\'',
        'Ho': 'Miyad',
        'Mundari': 'Miyad',
        'Kurukh': 'Ont',
        'Gondi': 'Undi',
      },
      exampleEn: 'I have one pen in my hand.',
      exampleTribal: {
        'Santali': 'ᱤᱧ ᱴᱷᱮᱱ ᱢᱤᱫᱴᱟᱝ ᱠᱚᱞᱚᱢ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'आईंग ता:रे मियद कलम मेना:।',
        'Mundari': 'ऐंग ता:रे मियद कलम मेना:।',
        'Kurukh': 'एंग्है गुसन ओन्त कलम रई।',
        'Gondi': 'नावा के उंदी कलम मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_2',
      label: 'Two (2)',
      phoneticEn: 'too',
      imageAsset: 'assets/images/flashcards/numbers/2.png',
      webPath: 'flashcards/numbers/2.png',
      fallbackIcon: Icons.looks_two_rounded,
      category: 'Numbers',
      hindi: 'दो (२)',
      phoneticHi: 'Do',
      tribalTranslations: {
        'Santali': 'ᱵᱟᱨ',
        'Ho': 'बारिया',
        'Mundari': 'बारिया',
        'Kurukh': 'एरंग',
        'Gondi': 'रंड',
      },
      tribalPhonetics: {
        'Santali': 'Bar',
        'Ho': 'Bariya',
        'Mundari': 'Bariya',
        'Kurukh': 'Erang',
        'Gondi': 'Rand',
      },
      exampleEn: 'Two birds are sitting together on a branch.',
      exampleTribal: {
        'Santali': 'ᱵᱟᱨᱭᱟ ᱪᱮᱬᱮ ᱫᱟᱨᱮ ᱨᱮ ᱢᱮᱱᱟᱜ ᱠᱤᱱᱟ᱾',
        'Ho': 'बारिया चेँड़े दारू रे मेना:किना।',
        'Mundari': 'बारिया चेँड़े दारू रे मेना:किना।',
        'Kurukh': 'एरंग ओड़ो मन नू रअनर।',
        'Gondi': 'रंड पिते मरा ते मन्तांग।',
      },
    ),
    FlashcardItem(
      id: 'n_3',
      label: 'Three (3)',
      phoneticEn: 'three',
      imageAsset: 'assets/images/flashcards/numbers/3.png',
      webPath: 'flashcards/numbers/3.png',
      fallbackIcon: Icons.looks_3_rounded,
      category: 'Numbers',
      hindi: 'तीन (३)',
      phoneticHi: 'Teen',
      tribalTranslations: {
        'Santali': 'ᱯᱮ',
        'Ho': 'आपिया',
        'Mundari': 'आपिया',
        'Kurukh': 'मूँद',
        'Gondi': 'मुंद',
      },
      tribalPhonetics: {
        'Santali': 'Pe',
        'Ho': 'Apiya',
        'Mundari': 'Apiya',
        'Kurukh': 'Moond',
        'Gondi': 'Mund',
      },
      exampleEn: 'There are three books on the table.',
      exampleTribal: {
        'Santali': 'ᱯᱮᱭᱟ ᱯᱚᱛᱚᱵ ᱢᱮᱡᱽ ᱪᱮᱛᱟᱱ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'आपिया पोतोब मेज चेतान रे मेना:।',
        'Mundari': 'आपिया पुथी मेज चोतोन रे मेना:।',
        'Kurukh': 'मूँद पोथी मेज मय्या रई।',
        'Gondi': 'मुंद किताब मेज परो मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_4',
      label: 'Four (4)',
      phoneticEn: 'for',
      imageAsset: 'assets/images/flashcards/numbers/4.png',
      webPath: 'flashcards/numbers/4.png',
      fallbackIcon: Icons.looks_4_rounded,
      category: 'Numbers',
      hindi: 'चार (४)',
      phoneticHi: 'Chaar',
      tribalTranslations: {
        'Santali': 'ᱯᱩᱱ',
        'Ho': 'उपून',
        'Mundari': 'उपून',
        'Kurukh': 'नाख़',
        'Gondi': 'नालुंग',
      },
      tribalPhonetics: {
        'Santali': 'Pun',
        'Ho': 'Upun',
        'Mundari': 'Upun',
        'Kurukh': 'Naakh',
        'Gondi': 'Nalung',
      },
      exampleEn: 'The vehicle has four wheels.',
      exampleTribal: {
        'Santali': 'ᱜᱟᱹᱰᱤ ᱨᱮᱭᱟᱜ ᱯᱩᱱᱭᱟᱹ ᱪᱟᱠᱟ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'गाड़ी रेयाग उपूनिया चका मेना:।',
        'Mundari': 'गाड़ी रेयाग उपून चका मेना:।',
        'Kurukh': 'गाड़ी गही नाख़ चक्का रई।',
        'Gondi': 'गाड़ी ता नालुंग चाका मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_5',
      label: 'Five (5)',
      phoneticEn: 'fyv',
      imageAsset: 'assets/images/flashcards/numbers/5.png',
      webPath: 'flashcards/numbers/5.png',
      fallbackIcon: Icons.looks_5_rounded,
      category: 'Numbers',
      hindi: 'पाँच (५)',
      phoneticHi: 'Paanch',
      tribalTranslations: {
        'Santali': 'ᱢᱚᱬᱮ',
        'Ho': 'मोड़े',
        'Mundari': 'मोड़े',
        'Kurukh': 'पंच',
        'Gondi': 'सैय्युंग',
      },
      tribalPhonetics: {
        'Santali': 'More',
        'Ho': 'Mode',
        'Mundari': 'Mode',
        'Kurukh': 'Panch',
        'Gondi': 'Sayyung',
      },
      exampleEn: 'We have five fingers on each hand.',
      exampleTribal: {
        'Santali': 'ᱢᱤᱫ ᱛᱤ ᱨᱮ ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱠᱟᱹᱴᱩᱵ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'मियद ती रे मोड़ेया कटूब मेना:।',
        'Mundari': 'मियद ती रे मोड़ेया कटुब मेना:।',
        'Kurukh': 'ओन्त खेत्रा नू पंच आंगुली रई।',
        'Gondi': 'उंदी कय ते सैय्युंग बोतांग मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_6',
      label: 'Six (6)',
      phoneticEn: 'siks',
      imageAsset: 'assets/images/flashcards/numbers/6.png',
      webPath: 'flashcards/numbers/6.png',
      fallbackIcon: Icons.looks_6_rounded,
      category: 'Numbers',
      hindi: 'छह (६)',
      phoneticHi: 'Chhah',
      tribalTranslations: {
        'Santali': 'ᱛᱩᱨᱩᱭ',
        'Ho': 'तुरूय',
        'Mundari': 'तुरूय',
        'Kurukh': 'सोय',
        'Gondi': 'सारुंग',
      },
      tribalPhonetics: {
        'Santali': 'Turuy',
        'Ho': 'Turuy',
        'Mundari': 'Turuy',
        'Kurukh': 'Soy',
        'Gondi': 'Sarung',
      },
      exampleEn: 'There are six bright colors in the drawing.',
      exampleTribal: {
        'Santali': 'ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱨᱚᱝ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'तुरूया रंग मेना:।',
        'Mundari': 'तुरूया रंग मेना:।',
        'Kurukh': 'सोय रंग गही रई।',
        'Gondi': 'सारुंग रंग मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_7',
      label: 'Seven (7)',
      phoneticEn: 'sev-uhn',
      imageAsset: 'assets/images/flashcards/numbers/7.png',
      webPath: 'flashcards/numbers/7.png',
      fallbackIcon: Icons.filter_7_rounded,
      category: 'Numbers',
      hindi: 'सात (७)',
      phoneticHi: 'Saat',
      tribalTranslations: {
        'Santali': 'ᱮᱭᱟᱭ',
        'Ho': 'एयाय',
        'Mundari': 'एयाय',
        'Kurukh': 'साते',
        'Gondi': 'येड़ुंग',
      },
      tribalPhonetics: {
        'Santali': 'Eyay',
        'Ho': 'Eyay',
        'Mundari': 'Eyay',
        'Kurukh': 'Saate',
        'Gondi': 'Yedung',
      },
      exampleEn: 'There are seven days in every week.',
      exampleTribal: {
        'Santali': 'ᱦᱟᱯᱛᱟ ᱨᱮ ᱮᱭᱟᱭ ᱢᱟᱦᱟᱸ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'हाफ्ता रे एयाय सिंगी मेना:।',
        'Mundari': 'हाफ्ता रे एयाय सिंगी मेना:।',
        'Kurukh': 'हफ्ता नू साते उल्ला रई।',
        'Gondi': 'हफ्ता ते येड़ुंग दिवस मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'n_8',
      label: 'Eight (8)',
      phoneticEn: 'ayt',
      imageAsset: 'assets/images/flashcards/numbers/8.png',
      webPath: 'flashcards/numbers/8.png',
      fallbackIcon: Icons.filter_8_rounded,
      category: 'Numbers',
      hindi: 'आठ (८)',
      phoneticHi: 'Aath',
      tribalTranslations: {
        'Santali': 'ᱤᱨᱟᱹᱞ',
        'Ho': 'इरल',
        'Mundari': 'इरल',
        'Kurukh': 'अट्ठे',
        'Gondi': 'अरुंग',
      },
      tribalPhonetics: {
        'Santali': 'Iral',
        'Ho': 'Iral',
        'Mundari': 'Iral',
        'Kurukh': 'Atthe',
        'Gondi': 'Arung',
      },
      exampleEn: 'Eight colored pencils are kept on the desk.',
      exampleTribal: {
        'Santali': 'ᱱᱚᱸᱰᱮ ᱤᱨᱟᱹᱞ ᱜᱚᱴᱟᱝ ᱯᱮᱱᱥᱤᱞ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        'Ho': 'नेनता:रे इरलाया पेंसिल मेना:।',
        'Mundari': 'नेनता:रे इरलाया पेंसिल मेना:।',
        'Kurukh': 'ईसन अट्ठे पेंसिल रई।',
        'Gondi': 'इगा अरुंग पेंसिल मन्ता।',
      },
    ),

    // ── Classroom (8 items cropped from classroom_sheet) ──────────────────────
    FlashcardItem(
      id: 'c_book',
      label: 'Book',
      phoneticEn: 'book',
      imageAsset: 'assets/images/flashcards/classroom/book.png',
      webPath: 'flashcards/classroom/book.png',
      fallbackIcon: Icons.menu_book_rounded,
      category: 'Classroom',
      hindi: 'किताब / पुस्तक',
      phoneticHi: 'Kitaab',
      tribalTranslations: {
        'Santali': 'ᱯᱚᱛᱚᱵ',
        'Ho': 'पोतोब',
        'Mundari': 'पुथी',
        'Kurukh': 'पोथी',
        'Gondi': 'किताब',
      },
      tribalPhonetics: {
        'Santali': 'Potob',
        'Ho': 'Potob',
        'Mundari': 'Puthi',
        'Kurukh': 'Pothi',
        'Gondi': 'Kitaab',
      },
      exampleEn: 'Open the book and read lesson one.',
      exampleTribal: {
        'Santali': 'ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ ᱟᱨ ᱯᱟᱲᱦᱟᱣ ᱢᱮ᱾',
        'Ho': 'पोतोब ओलोल मे ओड़ो पड़हाव मे।',
        'Mundari': 'पुथी ओल मे ओड़ो पड़हाव मे।',
        'Kurukh': 'पोथी उसिंगके ओंग पढ़आ।',
        'Gondi': 'किताब खोलो कीसी वाचामट।',
      },
    ),
    FlashcardItem(
      id: 'c_notebook',
      label: 'Notebook',
      phoneticEn: 'noht-book',
      imageAsset: 'assets/images/flashcards/classroom/notebook.png',
      webPath: 'flashcards/classroom/notebook.png',
      fallbackIcon: Icons.edit_note_rounded,
      category: 'Classroom',
      hindi: 'कॉपी / पुस्तिका',
      phoneticHi: 'Kopi',
      tribalTranslations: {
        'Santali': 'ᱚᱞ ᱯᱚᱛᱚᱵ',
        'Ho': 'ओल पोतोब',
        'Mundari': 'ओल पुथी',
        'Kurukh': 'टुडना पोथी',
        'Gondi': 'कापी',
      },
      tribalPhonetics: {
        'Santali': 'Ol Potob',
        'Ho': 'Ol Potob',
        'Mundari': 'Ol Puthi',
        'Kurukh': 'Tudna Pothi',
        'Gondi': 'Kapi',
      },
      exampleEn: 'Write your homework neatly in the notebook.',
      exampleTribal: {
        'Santali': 'ᱚᱞ ᱯᱚᱛᱚᱵ ᱨᱮ ᱚᱞ ᱢᱮ᱾',
        'Ho': 'ओल पोतोब रे ओल मे।',
        'Mundari': 'ओल पुथी रे ओल मे।',
        'Kurukh': 'टुडना पोथी नू टूड़ा।',
        'Gondi': 'कापी ते लीहा कीम।',
      },
    ),
    FlashcardItem(
      id: 'c_pen',
      label: 'Pen',
      phoneticEn: 'pen',
      imageAsset: 'assets/images/flashcards/classroom/pen.png',
      webPath: 'flashcards/classroom/pen.png',
      fallbackIcon: Icons.edit_rounded,
      category: 'Classroom',
      hindi: 'कलम',
      phoneticHi: 'Kalam',
      tribalTranslations: {
        'Santali': 'ᱠᱚᱞᱚᱢ',
        'Ho': 'कलम',
        'Mundari': 'कलम',
        'Kurukh': 'कलम',
        'Gondi': 'कलम',
      },
      tribalPhonetics: {
        'Santali': 'Kalom',
        'Ho': 'Kalam',
        'Mundari': 'Kalam',
        'Kurukh': 'Kalam',
        'Gondi': 'Kalam',
      },
      exampleEn: 'Use blue pen for writing notes.',
      exampleTribal: {
        'Santali': 'ᱱᱚᱣᱟ ᱠᱚᱞᱚᱢ ᱛᱮ ᱚᱞ ᱢᱮ᱾',
        'Ho': 'नेना कलम ते ओल मे।',
        'Mundari': 'नेया कलम ते ओल मे।',
        'Kurukh': 'ई कलम ती टूड़ा।',
        'Gondi': 'इद कलम ते लीहा कीम।',
      },
    ),
    FlashcardItem(
      id: 'c_pencil',
      label: 'Pencil',
      phoneticEn: 'pen-suhl',
      imageAsset: 'assets/images/flashcards/classroom/pencil.png',
      webPath: 'flashcards/classroom/pencil.png',
      fallbackIcon: Icons.create_rounded,
      category: 'Classroom',
      hindi: 'पेंसिल',
      phoneticHi: 'Pencil',
      tribalTranslations: {
        'Santali': 'ᱯᱮᱱᱥᱤᱞ',
        'Ho': 'पेंसिल',
        'Mundari': 'पेंसिल',
        'Kurukh': 'पेंसिल',
        'Gondi': 'पेंसिल',
      },
      tribalPhonetics: {
        'Santali': 'Pencil',
        'Ho': 'Pencil',
        'Mundari': 'Pencil',
        'Kurukh': 'Pencil',
        'Gondi': 'Pencil',
      },
      exampleEn: 'Draw clean shapes using a sharp pencil.',
      exampleTribal: {
        'Santali': 'ᱯᱮᱱᱥᱤᱞ ᱛᱮ ᱪᱤᱛᱟᱹᱨ ᱵᱮᱱᱟᱣ ᱢᱮ᱾',
        'Ho': 'पेंसिल ते चित्र बाई मे।',
        'Mundari': 'पेंसिल ते मूरत बाई मे।',
        'Kurukh': 'पेंसिल ती मूरत कमआ।',
        'Gondi': 'पेंसिल ते नक्शा कीम।',
      },
    ),
    FlashcardItem(
      id: 'c_blackboard',
      label: 'Blackboard',
      phoneticEn: 'blak-bawrd',
      imageAsset: 'assets/images/flashcards/classroom/blackboard.png',
      webPath: 'flashcards/classroom/blackboard.png',
      fallbackIcon: Icons.tablet_mac_rounded,
      category: 'Classroom',
      hindi: 'श्यामपट्ट / बोर्ड',
      phoneticHi: 'Board',
      tribalTranslations: {
        'Santali': 'ᱦᱮᱸᱫᱮ ᱵᱳᱨᱰ',
        'Ho': 'हेन्दे बोर्ड',
        'Mundari': 'हेंदो बोर्ड',
        'Kurukh': 'कारी बोर्ड',
        'Gondi': 'कड़िया बोर्ड',
      },
      tribalPhonetics: {
        'Santali': 'Hende Board',
        'Ho': 'Hende Board',
        'Mundari': 'Hendo Board',
        'Kurukh': 'Kari Board',
        'Gondi': 'Kariya Board',
      },
      exampleEn: 'The teacher writes lessons clearly on the blackboard.',
      exampleTribal: {
        'Santali': 'ᱢᱟᱪᱮᱛ ᱫᱚ ᱵᱳᱨᱰ ᱨᱮ ᱚᱞᱮᱫᱼᱟᱭ᱾',
        'Ho': 'गुरुजी बोर्ड रे ओले तानांग।',
        'Mundari': 'मास्टर बोर्ड रे ओले तानांग।',
        'Kurukh': 'मास्टर बोर्ड नू टूडरनर।',
        'Gondi': 'गुरुजी बोर्ड ते लीहिस मन्ता।',
      },
    ),
    FlashcardItem(
      id: 'c_bag',
      label: 'School Bag',
      phoneticEn: 'skool bag',
      imageAsset: 'assets/images/flashcards/classroom/bag.png',
      webPath: 'flashcards/classroom/bag.png',
      fallbackIcon: Icons.backpack_rounded,
      category: 'Classroom',
      hindi: 'बस्ता / स्कूल बैग',
      phoneticHi: 'Basta',
      tribalTranslations: {
        'Santali': 'ᱛᱷᱚᱞᱟ',
        'Ho': 'झोला',
        'Mundari': 'झोला',
        'Kurukh': 'झोला',
        'Gondi': 'थैली',
      },
      tribalPhonetics: {
        'Santali': 'Thola',
        'Ho': 'Jhola',
        'Mundari': 'Jhola',
        'Kurukh': 'Jhola',
        'Gondi': 'Thaili',
      },
      exampleEn: 'Keep all books safely inside your school bag.',
      exampleTribal: {
        'Santali': 'ᱯᱚᱛᱚᱵ ᱫᱚ ᱛᱷᱚᱞᱟ ᱨᱮ ᱫᱚᱦᱚᱭ ᱢᱮ᱾',
        'Ho': 'पोतोब झोला रे दोहोए मे।',
        'Mundari': 'पुथी झोला रे दोहोए मे।',
        'Kurukh': 'पोथी झोला नू इरा।',
        'Gondi': 'किताब थैली ते तासा कीम।',
      },
    ),
    FlashcardItem(
      id: 'c_desk',
      label: 'Desk',
      phoneticEn: 'desk',
      imageAsset: 'assets/images/flashcards/classroom/desk.png',
      webPath: 'flashcards/classroom/desk.png',
      fallbackIcon: Icons.table_restaurant_rounded,
      category: 'Classroom',
      hindi: 'मेज / डेस्क',
      phoneticHi: 'Mej',
      tribalTranslations: {
        'Santali': 'ᱢᱮᱡᱽ',
        'Ho': 'मेज',
        'Mundari': 'मेज',
        'Kurukh': 'मेज',
        'Gondi': 'मेज',
      },
      tribalPhonetics: {
        'Santali': 'Mej',
        'Ho': 'Mej',
        'Mundari': 'Mej',
        'Kurukh': 'Mej',
        'Gondi': 'Mej',
      },
      exampleEn: 'Sit comfortably at your classroom desk.',
      exampleTribal: {
        'Santali': 'ᱢᱮᱡᱽ ᱪᱮᱛᱟᱱ ᱨᱮ ᱫᱩᱲᱩᱵ ᱢᱮ᱾',
        'Ho': 'मेज चेतान रे दुब मे।',
        'Mundari': 'मेज चोतोन रे दुब मे।',
        'Kurukh': 'मेज मय्या उक्कआ।',
        'Gondi': 'मेज परो उदामट।',
      },
    ),
    FlashcardItem(
      id: 'c_bottle',
      label: 'Water Bottle',
      phoneticEn: 'wah-ter bot-uhl',
      imageAsset: 'assets/images/flashcards/classroom/bottle.png',
      webPath: 'flashcards/classroom/bottle.png',
      fallbackIcon: Icons.local_drink_rounded,
      category: 'Classroom',
      hindi: 'पानी की बोतल',
      phoneticHi: 'Paani ki Bottle',
      tribalTranslations: {
        'Santali': 'ᱫᱟᱜ ᱵᱚᱛᱚᱞ',
        'Ho': 'दा: बोतोल',
        'Mundari': 'दा: बोतोल',
        'Kurukh': 'अम बोतल',
        'Gondi': 'येर ता सीसी',
      },
      tribalPhonetics: {
        'Santali': 'Daak Botol',
        'Ho': 'Daa Botol',
        'Mundari': 'Daa Botol',
        'Kurukh': 'Am Bottle',
        'Gondi': 'Yer ta Seesi',
      },
      exampleEn: 'Drink clean drinking water from your water bottle.',
      exampleTribal: {
        'Santali': 'ᱯᱷᱟᱨᱪᱟ ᱫᱟᱜ ᱧᱩᱭ ᱢᱮ᱾',
        'Ho': 'बुगिन दा: नूई मे।',
        'Mundari': 'बेस दा: नूई मे।',
        'Kurukh': 'दाव अम ओना।',
        'Gondi': 'बेसे येर उनदामट।',
      },
    ),
  ];

  late List<FlashcardItem> _activeCards;

  @override
  void initState() {
    super.initState();
    _currentLanguage = AppState.instance.studentLanguage;
    if (!_availableLanguages.contains(_currentLanguage)) {
      _currentLanguage = 'Santali';
    }
    _activeCards = List.from(_allCards);
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  List<FlashcardItem> get _filteredCards {
    if (_selectedCategoryIndex == 0) return _activeCards;
    final cat = _categories[_selectedCategoryIndex];
    return _activeCards.where((c) => c.category == cat).toList();
  }

  FlashcardItem get _currentCard {
    final list = _filteredCards;
    if (_currentCardIndex >= list.length) {
      _currentCardIndex = 0;
    }
    return list[_currentCardIndex];
  }

  int get _totalCards => _filteredCards.length;

  void _goNext() {
    final list = _filteredCards;
    if (_currentCardIndex < list.length - 1) {
      setState(() => _currentCardIndex++);
    } else {
      // Loop back to start
      setState(() => _currentCardIndex = 0);
    }
  }

  void _goPrev() {
    if (_currentCardIndex > 0) {
      setState(() => _currentCardIndex--);
    } else {
      setState(() => _currentCardIndex = _filteredCards.length - 1);
    }
  }

  void _shuffleCards() {
    setState(() {
      _activeCards.shuffle();
      _currentCardIndex = 0;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cards shuffled randomly!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAutoPlay() {
    setState(() => _isAutoPlaying = !_isAutoPlaying);

    if (_isAutoPlaying) {
      _autoPlayTimer?.cancel();
      // Speak current card and advance every 4 seconds
      final card = _currentCard;
      _speak(text: card.label, lang: 'English', phonetic: card.phoneticEn);

      _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted || !_isAutoPlaying) {
          timer.cancel();
          return;
        }
        _goNext();
        final nextCard = _currentCard;
        _speak(text: nextCard.label, lang: 'English', phonetic: nextCard.phoneticEn);
      });
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _currentCardIndex = 0;
    });
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: _purple, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select Tribal Language for Flashcards',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._availableLanguages.map((lang) {
                  final isSelected = _currentLanguage == lang;
                  String nativeSubtitle = '';
                  if (lang == 'Santali') nativeSubtitle = 'ᱥᱟᱱᱛᱟᱲᱤ (Ol Chiki Script)';
                  if (lang == 'Ho') nativeSubtitle = 'ᱦᱳ / हो (Kolhan & Mayurbhanj)';
                  if (lang == 'Mundari') nativeSubtitle = 'मुण्डारी (होड़ो काजी)';
                  if (lang == 'Kurukh') nativeSubtitle = 'कुड़ुख़ (उरांव संवाद)';
                  if (lang == 'Gondi') nativeSubtitle = 'गोंडी (गोंडी गोटी)';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _purple.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _purple : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _currentLanguage = lang;
                        });
                        AppState.instance.updateClassroomSetup(sLang: lang);
                        Navigator.pop(ctx);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? _purple : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.translate_rounded,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          size: 18,
                        ),
                      ),
                      title: Text(
                        lang,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _purple : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        nativeSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isSelected ? _purple.withOpacity(0.8) : Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: _purple)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show dialog displaying the complete 2D All-in-One master sheet
  void _showCategorySheetDialog() {
    final cat = _selectedCategoryIndex == 0 ? 'Fruits' : _categories[_selectedCategoryIndex];
    final sheetPath = _categorySheets[cat] ?? 'flashcards/fruits_sheet.jpg';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view_rounded, color: _purple, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All-in-One 2D Sheet ($cat)',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _deepPurple,
                            ),
                          ),
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
              const SizedBox(height: 8),
              Text(
                'Each flashcard item in "$cat" is cropped from this master 2D educational sheet.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      sheetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Master Sheet: $sheetPath',
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Real-time Web Speech Synthesis with Indian phoneme routing
  void _speak({
    required String text,
    required String lang,
    String phonetic = '',
  }) {
    if (!kIsWeb) return;

    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;

      synth.cancel();
      synth.resume();

      final hasOlChiki = RegExp(r'[\u1C50-\u1C7F]').hasMatch(text);
      final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
      final voices = synth.getVoices();
      final hasHindiVoice = voices.any((v) =>
          (v.lang ?? '').toLowerCase().startsWith('hi') ||
          (v.name ?? '').toLowerCase().contains('hindi') ||
          (v.name ?? '').toLowerCase().contains('lekha'));

      String toSpeak = text;
      String targetSpeechLang = 'en-US';

      if (lang == 'English') {
        toSpeak = text;
        targetSpeechLang = 'en-US';
      } else if (lang == 'Hindi') {
        toSpeak = text;
        targetSpeechLang = 'hi-IN';
      } else if (hasOlChiki || lang == 'Santali') {
        toSpeak = phonetic.isNotEmpty ? phonetic : olChikiToPhonetic(text);
        targetSpeechLang = 'en-IN';
      } else {
        if (hasHindiVoice && hasDevanagari) {
          toSpeak = text.replaceAll(':', 'ह').replaceAll('ः', 'ह');
          targetSpeechLang = 'hi-IN';
        } else if (phonetic.isNotEmpty) {
          toSpeak = phonetic;
          targetSpeechLang = 'en-IN';
        } else if (lang == 'Ho') {
          toSpeak = hoToPhonetic(text);
          targetSpeechLang = 'en-IN';
        } else if (hasDevanagari) {
          toSpeak = devanagariToPhonetic(text);
          targetSpeechLang = 'en-IN';
        }
      }

      toSpeak = toSpeak
          .replaceAll(':', 'h')
          .replaceAll('ः', 'h')
          .replaceAll(RegExp(r'[।॥|]'), '.')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (toSpeak.isEmpty) return;

      final utterance = html.SpeechSynthesisUtterance(toSpeak);
      utterance.rate = 0.9;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
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

      setState(() => _currentlySpeakingText = text);
      utterance.onEnd.listen((_) {
        if (mounted) setState(() => _currentlySpeakingText = null);
      });
      utterance.onError.listen((_) {
        if (mounted) setState(() => _currentlySpeakingText = null);
      });

      synth.speak(utterance);
    } catch (e) {
      debugPrint('Speech synthesis error: $e');
    }
  }

  // ── UI Components ─────────────────────────────────────────────────────────

  Widget _buildTopControls() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language Selector Chip
          InkWell(
            onTap: _showLanguageSelector,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _purple.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, color: _purple, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    _currentLanguage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _deepPurple,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // View Full Category Sheet button
          VernexaFloatable(
            child: TextButton.icon(
              onPressed: _showCategorySheetDialog,
              icon: const Icon(Icons.photo_library_rounded, size: 15),
              label: Text(
                '2D Sheet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _purple,
                backgroundColor: _purple.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: _purple.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Toggle Grid View / Card View
          VernexaFloatable(
            child: IconButton(
              onPressed: () => setState(() => _isGridView = !_isGridView),
              icon: Icon(
                _isGridView ? Icons.view_carousel_rounded : Icons.grid_view_rounded,
                color: _deepPurple,
                size: 18,
              ),
              tooltip: _isGridView ? 'Switch to Card View' : 'Switch to Grid View',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Shuffle Button
          VernexaFloatable(
            child: IconButton(
              onPressed: _shuffleCards,
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              color: _deepPurple,
              tooltip: 'Shuffle Cards',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Auto-Play Slideshow Button
          VernexaFloatable(
            child: IconButton(
              onPressed: _toggleAutoPlay,
              icon: Icon(
                _isAutoPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: _isAutoPlaying ? const Color(0xFFDC2626) : _purple,
                size: 18,
              ),
              tooltip: _isAutoPlaying ? 'Pause Slideshow' : 'Auto Play',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                backgroundColor: _isAutoPlaying ? Colors.red.shade50 : _purple.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _isAutoPlaying ? Colors.red.shade300 : _purple.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (i) {
          final bool isSelected = _selectedCategoryIndex == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _categories.length - 1 ? 10 : 0),
            child: VernexaFloatable(
              child: GestureDetector(
                onTap: () => _selectCategory(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isSelected ? _purple : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _purple.withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    _categories[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Robust 2D Image loader: tries asset first, falls back to web path, then icon
  Widget _build2DImage(FlashcardItem card, {double height = 210}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.network(
            card.webPath,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_purple.withOpacity(0.6)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Try asset image if network fails
              return Image.asset(
                card.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card.fallbackIcon, size: 64, color: _purple.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text(
                          card.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: _deepPurple,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Normal, Clean, Unified Flashcard View (No flipping animation!)
  Widget _buildNormalFlashCard(FlashcardItem card) {
    final isBookmarked = _bookmarkedIds.contains(card.id);
    final isSpeakingEn = _currentlySpeakingText == card.label;
    final tribalWord = card.tribalTranslations[_currentLanguage] ?? card.tribalTranslations['Santali'] ?? '';
    final tribalPhonetic = card.tribalPhonetics[_currentLanguage] ?? card.tribalPhonetics['Santali'] ?? '';
    final exampleSentence = card.exampleTribal[_currentLanguage] ?? card.exampleTribal['Santali'] ?? '';
    final isSpeakingTribal = _currentlySpeakingText == tribalWord;
    final isSpeakingHindi = _currentlySpeakingText == card.hindi;
    final isSpeakingExample = _currentlySpeakingText == exampleSentence;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: _purple.withOpacity(0.12), width: 1.5),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Header Row ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(card.fallbackIcon, size: 14, color: _purple),
                    const SizedBox(width: 6),
                    Text(
                      card.category.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: _purple,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentCardIndex + 1} / $_totalCards',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _toggleBookmark(card.id),
                    icon: Icon(
                      isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isBookmarked ? Colors.amber : Colors.grey.shade400,
                      size: 24,
                    ),
                    tooltip: 'Bookmark',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 2D Cropped Image ──────────────────────────────────────────────
          _build2DImage(card, height: 210),
          const SizedBox(height: 18),

          // ── English Word & Pronunciation Section ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _deepPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/${card.phoneticEn}/',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // English audio playback button
              VernexaFloatable(
                child: ElevatedButton.icon(
                  onPressed: () => _speak(
                    text: card.label,
                    lang: 'English',
                    phonetic: card.phoneticEn,
                  ),
                  icon: Icon(
                    isSpeakingEn ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                    size: 18,
                    color: isSpeakingEn ? Colors.greenAccent : Colors.white,
                  ),
                  label: Text(
                    'English',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Tribal Translation Box (Coordinated & Dynamic) ─────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _purple.withOpacity(0.06),
                  _purple.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purple.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language banner row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _purple.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_rounded, color: _purple, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_currentLanguage Translation'.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _purple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick change language trigger
                    InkWell(
                      onTap: _showLanguageSelector,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Switch',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _purple,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: _purple, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Native Script Word & Audio Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            tribalWord,
                            style: GoogleFonts.notoSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: _deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phonetic: [$tribalPhonetic]',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tribal speech synthesis button
                    VernexaFloatable(
                      child: ElevatedButton.icon(
                        onPressed: () => _speak(
                          text: tribalWord,
                          lang: _currentLanguage,
                          phonetic: tribalPhonetic,
                        ),
                        icon: Icon(
                          isSpeakingTribal ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                          size: 18,
                          color: isSpeakingTribal ? Colors.greenAccent : Colors.white,
                        ),
                        label: Text(
                          'Listen',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Hindi Meaning & Sentence Box ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Text(
                  '🇮🇳 हिन्दी: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                Text(
                  '${card.hindi} (${card.phoneticHi})',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _speak(
                    text: card.hindi,
                    lang: 'Hindi',
                    phonetic: card.phoneticHi,
                  ),
                  icon: Icon(
                    isSpeakingHindi ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                    size: 18,
                    color: isSpeakingHindi ? Colors.green : Colors.amber.shade900,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Listen in Hindi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Classroom Context Example
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLASSROOM USAGE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exampleSentence,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _deepPurple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.exampleEn,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _speak(
                    text: exampleSentence,
                    lang: _currentLanguage,
                    phonetic: '',
                  ),
                  icon: Icon(
                    isSpeakingExample ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                    size: 18,
                    color: isSpeakingExample ? Colors.green : _purple,
                  ),
                  tooltip: 'Read example sentence',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid View of 2D Cards (Convenient Overview Mode) ──────────────────────
  Widget _buildGridView() {
    final list = _filteredCards;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.76,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final card = list[index];
        final isSelected = index == _currentCardIndex;
        final tribalWord = card.tribalTranslations[_currentLanguage] ?? '';

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentCardIndex = index;
              _isGridView = false; // open focused view
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? _purple : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? _purple.withOpacity(0.16) : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      card.webPath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => Image.asset(
                        card.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Icon(card.fallbackIcon, size: 40, color: _purple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _deepPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tribalWord,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF16A34A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Navigation Bar ────────────────────────────────────────────────────────
  Widget _buildNavRow() {
    return Row(
      children: [
        // Previous Button
        Expanded(
          child: VernexaFloatable(
            child: OutlinedButton.icon(
              onPressed: _goPrev,
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: Text(
                'Previous',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Next Button
        Expanded(
          child: VernexaFloatable(
            child: ElevatedButton.icon(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: Text(
                'Next Card',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalCards, (i) {
          final bool isActive = i == _currentCardIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentCardIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? _purple : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScrollBody() {
    final card = _currentCard;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _goNext();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goPrev();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top controls: Language Selector, Full Sheet, Grid/Card view, Shuffle, Auto-play
            _buildTopControls(),
            const SizedBox(height: 14),

            // Category Pills
            _buildCategoryPills(),
            const SizedBox(height: 18),

            // Main Flashcard (Normal 2D View) or Grid View
            if (_isGridView) ...[
              _buildGridView(),
            ] else ...[
              _buildNormalFlashCard(card),
              const SizedBox(height: 18),
              _buildNavRow(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Card ${_currentCardIndex + 1} of $_totalCards • Use Left/Right keys or tap Next',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildProgressDots(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800;

    if (isDesktop) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
        child: Scaffold(
          backgroundColor: _bg,
          body: Row(
            children: [
              const VernexaDesktopSidebar(currentIndex: 4),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 820),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '2D Visual Flashcards',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: _deepPurple,
                                    ),
                                  ),
                                  Text(
                                    'Precision 2D illustrations, instant tribal speech & coordinated learning',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Back to Home'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _purple,
                                side: const BorderSide(color: _purple),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(child: _buildScrollBody()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: VernexaFloatable(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            ),
          ),
          title: Text(
            '2D Visual Flashcards',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _showCategorySheetDialog,
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'View All-in-One 2D Sheet',
          ),
          IconButton(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.translate_rounded),
            tooltip: 'Select Language',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _buildScrollBody(),
      ),
      bottomNavigationBar: const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }
}
