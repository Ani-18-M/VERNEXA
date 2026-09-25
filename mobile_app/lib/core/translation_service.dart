import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_translation_service.dart';

class TranslationRecord {
  final String id;
  final String sourceText;
  final String translatedText;
  final String phoneticGuide;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final String category;
  final bool isTeacherSpeaker;

  TranslationRecord({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.phoneticGuide,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.category = 'Classroom',
    this.isTeacherSpeaker = true,
  });
}

class ClassroomPhrase {
  final String hindi;
  final String english;
  final Map<String, String> translations;
  final Map<String, String> phonetics;
  final String category;

  const ClassroomPhrase({
    required this.hindi,
    required this.english,
    required this.translations,
    required this.phonetics,
    required this.category,
  });
}

class TranslationService {
  static final TranslationService instance = TranslationService._internal();
  TranslationService._internal();

  final List<TranslationRecord> _history = [];
  List<TranslationRecord> get history => List.unmodifiable(_history);

  // Available Tribal & Regional Languages
  static const List<String> supportedLanguages = [
    'Hindi',
    'English',
    'Mundari',
    'Santali',
    'Ho',
    'Kurukh',
    'Gondi',
  ];

  // Authentic Curriculum & Classroom Phrases
  static const List<ClassroomPhrase> phrasebook = [
    ClassroomPhrase(
      hindi: 'नमस्ते बच्चों, आप सब कैसे हैं?',
      english: 'Hello children, how are you all?',
      category: 'Greetings',
      translations: {
        'Mundari': 'जोहार गड़ाको, आपे चिलके मेनापेया?',
        'Santali': 'ᱡᱚᱦᱟᱨ ᱜᱤᱫᱽᱨᱟᱹ, ᱟᱯᱮ ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱯᱮᱭᱟ?',
        'Ho': 'जोहार होनको, आपे चिलके मेनापेया?',
        'Kurukh': 'जोहार तंगड़ाको, नीम एकाने रईत?',
        'Gondi': 'जय जोहार पिलाक, मीर बोर आंदित?',
      },
      phonetics: {
        'Mundari': 'Johar gadako, ape chilke menapeya?',
        'Santali': 'Johar gidra, ape ched leka menag peya?',
        'Ho': 'Johar honko, ape chilke menapeya?',
        'Kurukh': 'Johar tangdako, neem ekane reet?',
        'Gondi': 'Jai Johar pilak, meer bor aandeet?',
      },
    ),
    ClassroomPhrase(
      hindi: 'बच्चों, आज हम एक से दस तक गिनती सीखेंगे।',
      english: 'Children, today we will learn numbers 1 to 10.',
      category: 'Maths',
      translations: {
        'Mundari': 'होड़ोको, आज इना 1 ते 10 गिनती सिखवा।',
        'Santali': 'ᱜᱤᱫᱽᱨᱟᱹ, ᱛᱮᱦᱮᱧ ᱵᱚ ᱑ ᱠᱷᱚᱱ ᱑᱐ ᱞᱮᱠᱷᱟ ᱵᱚ ᱪᱮᱫᱚᱜᱼᱟ᱾',
        'Ho': 'होनको, तिशिंग अबू मियद ते गेले गिनती सिखवा।',
        'Kurukh': 'तंगड़ाको, इनना 1 ती 10 तक लेखा सिखओत।',
        'Gondi': 'पिलाक, नेंड मम्मत उंदी ता पद लेखा हेककाट।',
      },
      phonetics: {
        'Mundari': 'Hodoko, aaj ina 1 te 10 ginti sikhwa.',
        'Santali': 'Gidra, teheng bo 1 khon 10 lekha bo chedog-a.',
        'Ho': 'Honko, tishing abu miyad te gele ginti sikhwa.',
        'Kurukh': 'Tangdako, inna 1 tee 10 tak lekha sikhot.',
        'Gondi': 'Pilak, nend mammat undi ta pad lekha hekkat.',
      },
    ),
    ClassroomPhrase(
      hindi: 'अपनी किताब का पृष्ठ संख्या 5 खोलिए।',
      english: 'Open your books to page 5.',
      category: 'Instruction',
      translations: {
        'Mundari': 'आपेआग पुथी रेयाग पांच नंबर पन्ना ओड़ोलेपे।',
        'Santali': 'ᱟᱯᱮᱭᱟᱜ ᱯᱚᱛᱚᱵ ᱕ ᱥᱟᱦᱴᱟ ᱡᱷᱤᱡᱽ ᱯᱮ᱾',
        'Ho': 'आपेआग पुथी रेयाग पांच पन्ना उडुंएपे।',
        'Kurukh': 'तंगहाय किताब गही पन्ना नंबर 5 तिंगा।',
        'Gondi': 'मीवा किताब ता पांचवा पाना पोसी कीमाट।',
      },
      phonetics: {
        'Mundari': 'Apeag puthi reyag panch number panna odolepe.',
        'Santali': 'Apeyag potob 5 sahta jhij pe.',
        'Ho': 'Apeag puthi reyag panch panna udungepe.',
        'Kurukh': 'Tanghay kitab gahi panna number 5 tinga.',
        'Gondi': 'Meewa kitab ta panchva pana posi keemat.',
      },
    ),
    ClassroomPhrase(
      hindi: 'कृपया सभी बच्चे शांत हो जाइए और ध्यान से सुनिए।',
      english: 'Please be quiet and listen carefully.',
      category: 'Discipline',
      translations: {
        'Mundari': 'सोबेन गड़ाको थिरुपे अड़ो ध्यान ते आयुमपे।',
        'Santali': 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱛᱷᱤᱨᱩᱜ ᱯᱮ ᱟᱨ ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱯᱮ᱾',
        'Ho': 'सोबेन होनको थिरुपे अड़ो सुकुर ते आयुमपे।',
        'Kurukh': 'सब्भे तंगड़ाको सांत रहो आरे ध्यान ती मेना।',
        'Gondi': 'सब पिलाक शांत मनजाट अन ध्यान ती केंजात।',
      },
      phonetics: {
        'Mundari': 'Soben gadako thirupe ado dhyan te aayumpe.',
        'Santali': 'Daya kate joto gidra thirug pe ar dhyan te anjom pe.',
        'Ho': 'Soben honko thirupe ado sukur te aayumpe.',
        'Kurukh': 'Sabbhe tangdako sant raho aare dhyan tee mena.',
        'Gondi': 'Sab pilak shant manjaat an dhyan tee kenjaat.',
      },
    ),
    ClassroomPhrase(
      hindi: 'इस सवाल का उत्तर कौन जानता है?',
      english: 'Who knows the answer to this question?',
      category: 'Question',
      translations: {
        'Mundari': 'नेया कुली रेयाग काजी ओकोए सड़िएदा?',
        'Santali': 'ᱱᱚᱣᱟ ᱠᱩᱠᱞᱤ ᱨᱮᱱᱟᱜ ᱛᱮᱞᱟ ᱚᱠᱚᱭ ᱮ ᱵᱟᱰᱟᱭᱟ?',
        'Ho': 'नेना कुली रेयाग उत्तर ओकोए बानाया?',
        'Kurukh': 'ई सवाल गही उत्तर एकोए अक्खी?',
        'Gondi': 'इद सवाल ता जवाब बोर पूनतूर?',
      },
      phonetics: {
        'Mundari': 'Neya kuli reyag kaji okoe sadiyeda?',
        'Santali': 'Nowa kukli renag tela okoy e badaya?',
        'Ho': 'Nena kuli reyag uttar okoe banaya?',
        'Kurukh': 'Ee sawaal gahi uttar ekoye akkhee?',
        'Gondi': 'Id sawal ta jawab bor poontoor?',
      },
    ),
    ClassroomPhrase(
      hindi: 'बहुत अच्छा! आप सभी ने बहुत अच्छा काम किया।',
      english: 'Very good! You all did a great job.',
      category: 'Praise',
      translations: {
        'Mundari': 'एनांग बेस! आपे सोबेनको बेस कामी केदापे।',
        'Santali': 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱟᱯᱮ ᱡᱚᱛᱚ ᱦᱚᱲ ᱟᱹᱰᱤ ᱵᱷᱟᱹᱜᱤ ᱠᱟᱹᱢᱤ ᱯᱮ ᱠᱚᱨᱟᱣ ᱠᱮᱫᱼᱟ᱾',
        'Ho': 'एशू बुगिन! आपे सोबेनको बुगिन कामियानापे।',
        'Kurukh': 'कोड़े कोड़े! नीम सब्भे कोड़े कमचकय।',
        'Gondi': 'बेसे मंचा! मीर सब पिलाक बेसे काम कीतीट।',
      },
      phonetics: {
        'Mundari': 'Enang bes! Ape sobenko bes kami kedape.',
        'Santali': 'Adi napay! Ape joto hor adi bhagi kami pe koraw ked-a.',
        'Ho': 'Eshu bugin! Ape sobenko bugin kamiyanape.',
        'Kurukh': 'Kode kode! Neem sabbhe kode kamchkay.',
        'Gondi': 'Bese mancha! Meer sab pilak bese kaam keeteet.',
      },
    ),
    ClassroomPhrase(
      hindi: 'अपनी कॉपी में यह वाक्य लिखिए।',
      english: 'Write this sentence in your notebook.',
      category: 'Instruction',
      translations: {
        'Mundari': 'आपेआग कापी रे ने काजी ओलोलपे।',
        'Santali': 'ᱟᱯᱮᱭᱟᱜ ᱠᱷᱟᱛᱟ ᱨᱮ ᱱᱚᱣᱟ ᱚᱞ ᱯᱮ᱾',
        'Ho': 'आपेआग खाथा रे नेना ओलपे।',
        'Kurukh': 'तंगहाय कापी नू ई कत्थन टूंड़ा।',
        'Gondi': 'मीवा कापी ते इद लिखिस कीमाट।',
      },
      phonetics: {
        'Mundari': 'Apeag kaapi re ne kaji ololpe.',
        'Santali': 'Apeyag khata re nowa ol pe.',
        'Ho': 'Apeag khatha re nena olpe.',
        'Kurukh': 'Tanghay kaapi noo ee katthan toonda.',
        'Gondi': 'Meewa kaapi te id likhis keemat.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, क्या मैं पानी पीने जा सकता हूँ?',
      english: 'Sir, may I go to drink water?',
      category: 'Question',
      translations: {
        'Mundari': 'सर, अईंग दा: नू सेंनोः दाईंग?',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱫᱟᱜ ᱧᱩ ᱤᱧ ᱪᱟᱞᱟᱣ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
        'Ho': 'सर, आईंग दा: नू सेनेया दाईंग?',
        'Kurukh': 'सर, एन अम्म ओना कालून?',
        'Gondi': 'सर, नना येर उना हानोन?',
      },
      phonetics: {
        'Mundari': 'Sir, aing da: nu senoh daing?',
        'Santali': 'Sir, ing dag nyu ing chalaw dareyag-a?',
        'Ho': 'Sir, aing da: nu seneya daing?',
        'Kurukh': 'Sir, en amm ona kaloon?',
        'Gondi': 'Sir, nana yer oona haanon?',
      },
    ),
    ClassroomPhrase(
      hindi: 'आपका नाम क्या है?',
      english: 'What is your name?',
      category: 'Question',
      translations: {
        'Mundari': 'आमा: नुतुम चिना:?',
        'Santali': 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ?',
        'Ho': 'आमा: नुतुम चिकना?',
        'Kurukh': 'नींघाय नामे इन्दिर रई?',
        'Gondi': 'नीवा पद्दोर बाता आंद?',
      },
      phonetics: {
        'Mundari': 'Aamah nutum chinah?',
        'Santali': 'Amag nyutum do ched?',
        'Ho': 'Aamah nutum chikana?',
        'Kurukh': 'Ninghay name indir raee?',
        'Gondi': 'Neewa paddor baata aand?',
      },
    ),
    ClassroomPhrase(
      hindi: 'आपकी उम्र कितनी है?',
      english: 'What is your age?',
      category: 'Question',
      translations: {
        'Mundari': 'आमा: उमिर चिमिन बरिस?',
        'Santali': 'ᱟᱢᱟᱜ ᱩᱢᱮᱨ ᱛᱤᱱᱟᱹᱜ?',
        'Ho': 'आमा: उमुर चिमिन?',
        'Kurukh': 'नींघाय उमिर एका रई?',
        'Gondi': 'नीवा उमोर बाचुंद आंद?',
      },
      phonetics: {
        'Mundari': 'Aamah umir chimin baris?',
        'Santali': 'Amag umer tinag?',
        'Ho': 'Aamah umur chimin?',
        'Kurukh': 'Ninghay umir eka raee?',
        'Gondi': 'Neewa umor bachund aand?',
      },
    ),
    ClassroomPhrase(
      hindi: 'कृपया सभी बच्चे बैठ जाइए।',
      english: 'Please sit down, everyone.',
      category: 'Instruction',
      translations: {
        'Mundari': 'सोबेन गड़ाको, दुबुपे!',
        'Santali': 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵ ᱯᱮ!',
        'Ho': 'सोबेन होनको, दुबुपे!',
        'Kurukh': 'सब्भे तंगड़ाको, उक्का!',
        'Gondi': 'सब पिलाक, बहाट!',
      },
      phonetics: {
        'Mundari': 'Soben gadako, dubupe!',
        'Santali': 'Daya kate joto hor durup pe!',
        'Ho': 'Soben honko, dubupe!',
        'Kurukh': 'Sabbhe tangdako, ukka!',
        'Gondi': 'Sab pilak, bahaat!',
      },
    ),
    ClassroomPhrase(
      hindi: 'कृपया सभी बच्चे खड़े हो जाइए।',
      english: 'Please stand up, everyone.',
      category: 'Instruction',
      translations: {
        'Mundari': 'सोबेन गड़ाको, तिंगुपे!',
        'Santali': 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱤᱸᱜᱩᱱ ᱯᱮ!',
        'Ho': 'सोबेन होनको, तिंगुपे!',
        'Kurukh': 'सब्भे तंगड़ाको, इद्दा!',
        'Gondi': 'सब पिलाक, तेदाट!',
      },
      phonetics: {
        'Mundari': 'Soben gadako, tingupe!',
        'Santali': 'Daya kate joto hor tingun pe!',
        'Ho': 'Soben honko, tingupe!',
        'Kurukh': 'Sabbhe tangdako, idda!',
        'Gondi': 'Sab pilak, tedaat!',
      },
    ),
    ClassroomPhrase(
      hindi: 'यहाँ आओ और अपनी कॉपी दिखाओ।',
      english: 'Come here and show your notebook.',
      category: 'Instruction',
      translations: {
        'Mundari': 'नेते हिजुःमे अड़ो आमा: कॉपी ओदोङेमे।',
        'Santali': 'ᱱᱚᱰᱮ ᱦᱤᱡᱩᱜ ᱢᱮ ᱟᱨ ᱟᱢᱟᱜ ᱠᱷᱟᱛᱟ ᱩᱫᱩᱜ ᱢᱮ᱾',
        'Ho': 'नेते हिजुःमे अड़ो आमा: खाता ओदोङेमे।',
        'Kurukh': 'ईसा बारके आरे तंगहाय कॉपी इरा।',
        'Gondi': 'हिका वारा अन नीवा कॉपी वोहटा।',
      },
      phonetics: {
        'Mundari': 'Nete hijuhme ado aamah copy odongeme.',
        'Santali': 'Node hijug me ar amag khata udug me.',
        'Ho': 'Nete hijuhme ado aamah khata odongeme.',
        'Kurukh': 'Eesa baarke aare tanghay copy era.',
        'Gondi': 'Hika wara an neewa copy wohta.',
      },
    ),
    ClassroomPhrase(
      hindi: 'हाँ, तुम पानी पीने जा सकते हो।',
      english: 'Yes, you may go drink water.',
      category: 'Instruction',
      translations: {
        'Mundari': 'हे, आम दा: नू सेंनोःमे।',
        'Santali': 'ᱦᱮᱸ, ᱟᱢ ᱫᱟᱜ ᱧᱩ ᱪᱟᱞᱟᱣ ᱢᱮ᱾',
        'Ho': 'हे, आम दा: नू सेनेयामे।',
        'Kurukh': 'हाअं, नीन अम्म ओना काला।',
        'Gondi': 'इन, नीम येर उना हान।',
      },
      phonetics: {
        'Mundari': 'He, aam da: nu senohme.',
        'Santali': 'Heng, am dag nyu chalaw me.',
        'Ho': 'He, aam daah nu seneyame.',
        'Kurukh': 'Haa, neen amm ona kaala.',
        'Gondi': 'In, neem yer oona haan.',
      },
    ),
    ClassroomPhrase(
      hindi: 'हाँ, तुम बाहर जा सकते हो।',
      english: 'Yes, you may go outside.',
      category: 'Instruction',
      translations: {
        'Mundari': 'हे, आम बाहरे सेंनोःमे।',
        'Santali': 'ᱦᱮᱸ, ᱟᱢ ᱵᱟᱦᱨᱮ ᱪᱟᱞᱟᱣ ᱢᱮ᱾',
        'Ho': 'हे, आम बाहर सेनेयामे।',
        'Kurukh': 'हाअं, नीन बहरी काला।',
        'Gondi': 'इन, नीम बाहर हान।',
      },
      phonetics: {
        'Mundari': 'He, aam bahre senohme.',
        'Santali': 'Heng, am bahre chalaw me.',
        'Ho': 'He, aam bahar seneyame.',
        'Kurukh': 'Haa, neen bahri kaala.',
        'Gondi': 'In, neem bahar haan.',
      },
    ),
    ClassroomPhrase(
      hindi: 'शोर मत करो, शांत रहो।',
      english: 'Do not make noise, be quiet.',
      category: 'Discipline',
      translations: {
        'Mundari': 'हो-हो कापे कजीया, थिरुपे!',
        'Santali': 'ᱦᱚᱸ-ᱦᱚᱸ ᱟᱞᱚ ᱯᱮ ᱠᱚᱨᱟᱣᱼᱟ, ᱛᱷᱤᱨᱩᱜ ᱯᱮ!',
        'Ho': 'सोर-गुल कापेया, थिरुपे!',
        'Kurukh': 'गोहारो मल्ला, सांत रहो!',
        'Gondi': 'गोंधल कीमाट, शांत मनजाट!',
      },
      phonetics: {
        'Mundari': 'Ho-ho kape kajiya, thirupe!',
        'Santali': 'Ho-ho alo pe koraw-a, thirug pe!',
        'Ho': 'Shor-gul kapeya, thirupe!',
        'Kurukh': 'Goharo malla, sant raho!',
        'Gondi': 'Gondhal keemat, shant manjaat!',
      },
    ),
  ];

  // Authentic Student-to-Teacher Phrasebook
  static const List<ClassroomPhrase> studentPhrasebook = [
    ClassroomPhrase(
      hindi: 'नमस्ते गुरुजी / जोहार मास्टर जी।',
      english: 'Greetings teacher / Johar Master-ji.',
      category: 'Greetings',
      translations: {
        'Mundari': 'जोहार मास्टर जी, अईंग हाजिर मेनाईंग।',
        'Santali': 'ᱡᱚᱦᱟᱨ ᱢᱟᱥᱴᱟᱨ ᱜᱚᱢᱠᱮ, ᱤᱧ ᱦᱮᱡ ᱮᱱᱟ᱾',
        'Ho': 'जोहार मास्टर जी, आईंग सेटेरयाना।',
        'Kurukh': 'जोहार मास्टर जी, एन बरचकादन।',
        'Gondi': 'जय जोहार मास्टर जी, नना वातन।',
      },
      phonetics: {
        'Mundari': 'Johar Master ji, aing hajir menaing.',
        'Santali': 'Johar Master gomke, ing hej ena.',
        'Ho': 'Johar Master ji, aing seteryana.',
        'Kurukh': 'Johar Master ji, en barchkadan.',
        'Gondi': 'Jai Johar Master ji, nana waatan.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, क्या मैं पानी पीने जा सकता हूँ?',
      english: 'Sir, may I go to drink water?',
      category: 'Needs',
      translations: {
        'Mundari': 'सर, अईंग दा: नू सेंनोः दाईंग?',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱫᱟᱜ ᱧᱩ ᱤᱧ ᱪᱟᱞᱟᱣ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
        'Ho': 'सर, आईंग दा: नू सेनेया दाईंग?',
        'Kurukh': 'सर, एन अम्म ओना कालून?',
        'Gondi': 'सर, नना येर उना हानोन?',
      },
      phonetics: {
        'Mundari': 'Sir, aing da: nu senoh daing?',
        'Santali': 'Sir, ing dag nyu ing chalaw dareyag-a?',
        'Ho': 'Sir, aing da: nu seneya daing?',
        'Kurukh': 'Sir, en amm ona kaloon?',
        'Gondi': 'Sir, nana yer oona haanon?',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, क्या मैं बाहर (शौचालय) जा सकता हूँ?',
      english: 'Sir, may I go outside / to the washroom?',
      category: 'Needs',
      translations: {
        'Mundari': 'सर, अईंग बाहरे सेंनोः दाईंग?',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱵᱟᱦᱨᱮ ᱪᱟᱞᱟᱣ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
        'Ho': 'सर, आईंग बाहर सेनोः दाईंग?',
        'Kurukh': 'सर, एन बहरी कालून?',
        'Gondi': 'सर, नना बाहर हानोन?',
      },
      phonetics: {
        'Mundari': 'Sir, aing bahre senoh daing?',
        'Santali': 'Sir, ing bahre chalaw dareyag-a?',
        'Ho': 'Sir, aing bahar senoh daing?',
        'Kurukh': 'Sir, en bahri kaloon?',
        'Gondi': 'Sir, nana bahar haanon?',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मेरे पास पेंसिल या कलम नहीं है।',
      english: 'Sir, I do not have a pencil or pen.',
      category: 'Needs',
      translations: {
        'Mundari': 'सर, अईंग ता:रे कलम बानोःआ।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱴᱷᱮᱱ ᱠᱚᱞᱚᱢ ᱵᱟᱹᱱᱩᱜᱼᱟ᱾',
        'Ho': 'सर, आईंग ता:रे कलम बानोःआ।',
        'Kurukh': 'सर, एंगहा कलम मल्ला।',
        'Gondi': 'सर, नावा कलम सिल्ले।',
      },
      phonetics: {
        'Mundari': 'Sir, aing ta:re kalam banoh-a.',
        'Santali': 'Sir, ing then kolom banug-a.',
        'Ho': 'Sir, aing ta:re kalam banoh-a.',
        'Kurukh': 'Sir, engha kalam malla.',
        'Gondi': 'Sir, nawa kalam sille.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मैं अपनी किताब घर पर भूल गया हूँ।',
      english: 'Sir, I forgot my book at home.',
      category: 'Needs',
      translations: {
        'Mundari': 'सर, अईंग पुथी ओड़ा:रे अईंग बगाकेदा।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱚᱲᱟᱜ ᱨᱮ ᱯᱚᱛᱚᱵ ᱤᱧ ᱦᱤᱲᱤᱧ ᱴᱚᱠᱟᱫᱼᱟ᱾',
        'Ho': 'सर, आईंग पुथी ओवाःरे बागेकेदा।',
        'Kurukh': 'सर, एन एड़पा नू किताब बिसरचकादन।',
        'Gondi': 'सर, नना रोन ते किताब विसरतुन।',
      },
      phonetics: {
        'Mundari': 'Sir, aing puthi oda:re aing bagakeda.',
        'Santali': 'Sir, ing odag re potob ing hirin tokad-a.',
        'Ho': 'Sir, aing puthi owa:re bagekeda.',
        'Kurukh': 'Sir, en edpa noo kitab bisarchkadan.',
        'Gondi': 'Sir, nana ron te kitab visartun.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मुझे यह पाठ समझ नहीं आया।',
      english: 'Sir, I did not understand this lesson.',
      category: 'Questions',
      translations: {
        'Mundari': 'सर, अईंग नेया काईंग बुझावकेदा।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱹᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱫᱟᱲᱮᱭᱟᱫᱼᱟ᱾',
        'Ho': 'सर, आईंग नेना काईंग बुझियाना।',
        'Kurukh': 'सर, एन ई कत्थन पोलकन बुझरा।',
        'Gondi': 'सर, नाक इद पूरो समझ माये।',
      },
      phonetics: {
        'Mundari': 'Sir, aing neya kaing bujhaokeda.',
        'Santali': 'Sir, ing nowa banj bujhaw dareyad-a.',
        'Ho': 'Sir, aing nena kaing bujhiyana.',
        'Kurukh': 'Sir, en ee katthan polkan bujhra.',
        'Gondi': 'Sir, naak id pooro samajh maaye.',
      },
    ),
    ClassroomPhrase(
      hindi: 'कृपया इसे एक बार फिर से समझाइए।',
      english: 'Please explain this once again.',
      category: 'Questions',
      translations: {
        'Mundari': 'दयाकाते नेया अड़ो मिसा बुझावईंगपे।',
        'Santali': 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱣᱟ ᱟᱨᱦᱚᱸ ᱢᱤᱫ ᱫᱷᱟᱣ ᱞᱟᱹᱭ ᱢᱮ᱾',
        'Ho': 'दयाकाते नेना अड़ो मिसा बुझियाईंगपे।',
        'Kurukh': 'अनेक दफ़ा ई कत्थन नन्ना नू तिंगा।',
        'Gondi': 'इद गोटी मल्ला उंदी फा वोहटाट।',
      },
      phonetics: {
        'Mundari': 'Dayakate neya ado misa bujhaowingpe.',
        'Santali': 'Daya kate nowa arho mid dhaw lay me.',
        'Ho': 'Dayakate nena ado misa bujhiyaingpe.',
        'Kurukh': 'Anek dafa ee katthan nanna noo tinga.',
        'Gondi': 'Id goti malla undi fa wohtaat.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, इसे अपनी कॉपी में कैसे लिखना है?',
      english: 'Sir, how should I write this in my notebook?',
      category: 'Questions',
      translations: {
        'Mundari': 'सर, कापी रे नेया चिलके ओलोवा?',
        'Santali': 'ᱥᱟᱨ, ᱠᱷᱟᱛᱟ ᱨᱮ ᱱᱚᱣᱟ ᱪᱮᱫ ᱞᱮᱠᱟ ᱚᱞᱚᱜᱼᱟ?',
        'Ho': 'सर, खाथा रे नेना चिलके ओलोवा?',
        'Kurukh': 'सर, कापी नू ईदन एकाने टूंड़ना रई?',
        'Gondi': 'सर, कापी ते इदन बोर लिखिस कीयाना?',
      },
      phonetics: {
        'Mundari': 'Sir, kaapi re neya chilke olowa?',
        'Santali': 'Sir, khata re nowa ched leka olog-a?',
        'Ho': 'Sir, khatha re nena chilke olowa?',
        'Kurukh': 'Sir, kaapi noo eedan ekane toondna raee?',
        'Gondi': 'Sir, kaapi te idan bor likhis keeyana?',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मैंने अपना काम और अभ्यास पूरा कर लिया है।',
      english: 'Sir, I have finished my task and exercise.',
      category: 'Tasks',
      translations: {
        'Mundari': 'सर, अईंग कामी चाबाकेदा।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧᱟᱜ ᱠᱟᱹᱢᱤ ᱯᱩᱨᱟᱹᱣ ᱮᱱᱟ᱾',
        'Ho': 'सर, आईंग कामी चाबायाना।',
        'Kurukh': 'सर, एंगहा कम चाबचका।',
        'Gondi': 'सर, नावा काम पूरा आतो।',
      },
      phonetics: {
        'Mundari': 'Sir, aing kami chabakeda.',
        'Santali': 'Sir, ingag kami puraw ena.',
        'Ho': 'Sir, aing kami chabayana.',
        'Kurukh': 'Sir, engha kam chabchka.',
        'Gondi': 'Sir, nawa kaam poora aato.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मैं इस सवाल का उत्तर जानता हूँ।',
      english: 'Sir, I know the answer to this question.',
      category: 'Tasks',
      translations: {
        'Mundari': 'सर, अईंग नेया रेयाग काजी सड़िएदा।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱱᱚᱣᱟ ᱨᱮᱱᱟᱜ ᱛᱮᱞᱟᱧ ᱵᱟᱰᱟᱭᱟ᱾',
        'Ho': 'सर, आईंग उत्तर बानाया।',
        'Kurukh': 'सर, एन उत्तर अक्खदन।',
        'Gondi': 'सर, नना जवाब पूनतुन।',
      },
      phonetics: {
        'Mundari': 'Sir, aing neya reyag kaji sadiyeda.',
        'Santali': 'Sir, ing nowa renag telang badaya.',
        'Ho': 'Sir, aing uttar banaya.',
        'Kurukh': 'Sir, en uttar akkhedan.',
        'Gondi': 'Sir, nana जवाब poontun.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मेरे पेट में बहुत दर्द हो रहा है।',
      english: 'Sir, my stomach is hurting badly.',
      category: 'Health',
      translations: {
        'Mundari': 'सर, अईंगआग लाज पुरो हासुतांग।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧᱟᱜ ᱞᱟᱡ ᱟᱹᱰᱤ ᱦᱟᱹᱥᱩ ᱠᱟᱱᱟ᱾',
        'Ho': 'सर, आईंगआग लाज एशू हासुतांग।',
        'Kurukh': 'सर, एंगहा कुल कोड़े खखराअदी।',
        'Gondi': 'सर, नावा पीर गच्ची नोयिता।',
      },
      phonetics: {
        'Mundari': 'Sir, aingag laj puro hasutang.',
        'Santali': 'Sir, ingag laj adi hasu kana.',
        'Ho': 'Sir, aingag laj eshu hasutang.',
        'Kurukh': 'Sir, engha kul kode khakhraadi.',
        'Gondi': 'Sir, nawa peer gacchi noyeeta.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मुझे ठंड और बुखार लग रहा है।',
      english: 'Sir, I am having chills and fever.',
      category: 'Health',
      translations: {
        'Mundari': 'सर, अईंग राभांग अड़ो रुआ लगमतांग।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱨᱟᱵᱟᱝ ᱟᱨ ᱨᱩᱣᱟᱹ ᱤᱧ ᱟᱹᱭᱠᱟᱹᱣ ᱮᱫᱼᱟ᱾',
        'Ho': 'सर, आईंग राबांग अड़ो रुवा अटाकारांग।',
        'Kurukh': 'सर, एंगहय ख़ेखल नू बिंदी रई।',
        'Gondi': 'सर, नाक सड्डी अन कस्कट वासिंता।',
      },
      phonetics: {
        'Mundari': 'Sir, aing rabang ado rua lagamtang.',
        'Santali': 'Sir, ing rabang ar rua ing aykaw ed-a.',
        'Ho': 'Sir, aing rabang ado ruwa atakaraang.',
        'Kurukh': 'Sir, enghay khekhal noo bindi raee.',
        'Gondi': 'Sir, naak saddi an kaskat wasinta.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, क्या मैं घर जा सकता हूँ? तबियत ठीक नहीं है।',
      english: 'Sir, may I go home? I am unwell.',
      category: 'Health',
      translations: {
        'Mundari': 'सर, अईंग ओड़ा: सेंनोः दाईंग? जीव का बेस बुझाओतांग।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧ ᱚᱲᱟᱜ ᱤᱧ ᱪᱟᱞᱟᱣ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ? ᱦᱚᱲᱢᱚ ᱵᱟᱝ ᱴᱷᱤᱠᱟᱹ᱾',
        'Ho': 'सर, आईंग ओवाः सेनेया दाईंग? जीव का बुगिन।',
        'Kurukh': 'सर, एन एड़पा कालून? जीया मल्ला कोड़े।',
        'Gondi': 'सर, नना रोन हानोन? जीउ बेस सिल्ले।',
      },
      phonetics: {
        'Mundari': 'Sir, aing oda: senoh daing? Jeev ka bes bujhaotang.',
        'Santali': 'Sir, ing odag ing chalaw dareyag-a? Hormo bang thika.',
        'Ho': 'Sir, aing owa: seneya daing? Jeev ka bugin.',
        'Kurukh': 'Sir, en edpa kaloon? Jeeya malla kode.',
        'Gondi': 'Sir, nana ron haanon? Jeeu bese sille.',
      },
    ),
    ClassroomPhrase(
      hindi: 'गिनती: एक, दो, तीन, चार, पाँच।',
      english: 'Counting: one, two, three, four, five.',
      category: 'Numbers',
      translations: {
        'Mundari': 'मियद, बारिया, आपिया, उपुन, मोणोय।',
        'Santali': 'ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱩᱱ, ᱢᱚᱬᱮ᱾',
        'Ho': 'मियद, बारिया, आपेया, उपुन, मोणोया।',
        'Kurukh': 'ओन्त, एरड़, मूंद, नाख, पांच।',
        'Gondi': 'उंदी, रंड, मूंड, नालुंग, सय्युंग।',
      },
      phonetics: {
        'Mundari': 'Miyad, bariya, aapiya, upun, monoy.',
        'Santali': 'Mid, bar, pe, pun, mone.',
        'Ho': 'Miyad, bariya, apeya, upun, monoya.',
        'Kurukh': 'Ond, end, moond, naakh, panch.',
        'Gondi': 'Undi, rand, moond, naalung, sayyung.',
      },
    ),
    ClassroomPhrase(
      hindi: 'गिनती: छह, सात, आठ, नौ, दस।',
      english: 'Counting: six, seven, eight, nine, ten.',
      category: 'Numbers',
      translations: {
        'Mundari': 'तुरूय, एया, इरिल, आरे, गेले।',
        'Santali': 'ᱛᱩᱨᱩᱭ, ᱮᱭᱟᱭ, ᱤᱨᱟᱹᱞ, ᱟᱨᱮ, ᱜᱮᱞ᱾',
        'Ho': 'तुरूया, एया, इरिया, आरेया, गेले।',
        'Kurukh': 'सोये, सत्ते, अठ्ठे, नोये, दस्से।',
        'Gondi': 'सारुंग, येड़ुंग, एण्मुंग, नोरुंग, पद।',
      },
      phonetics: {
        'Mundari': 'Turui, eya, iril, aare, gele.',
        'Santali': 'Turui, eayay, iral, aare, gel.',
        'Ho': 'Turuya, eya, iriya, areya, gele.',
        'Kurukh': 'Soye, satte, ath-the, noye, dasse.',
        'Gondi': 'Saarung, yedung, enmung, norung, pad.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मेरे सिर में बहुत दर्द हो रहा है।',
      english: 'Sir, I have a severe headache.',
      category: 'Health',
      translations: {
        'Mundari': 'सर, अईंगआग बोः हासुतांग।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧᱟᱜ ᱵᱚᱦᱚᱜ ᱟᱹᱰᱤ ᱦᱟᱹᱥᱩ ᱠᱟᱱᱟ᱾',
        'Ho': 'सर, आईंगआ: बोः एशू हासुताना।',
        'Kurukh': 'सर, एंगहा कुक्क नोयिता।',
        'Gondi': 'सर, नावा तर्रे नोयिता।',
      },
      phonetics: {
        'Mundari': 'Sir, aingag boh hasutang.',
        'Santali': 'Sir, ingag bohog adi hasu kana.',
        'Ho': 'Sir, aing-ah boh eshu hasutana.',
        'Kurukh': 'Sir, engha kukk noyeeta.',
        'Gondi': 'Sir, nawa tarre noyeeta.',
      },
    ),
    ClassroomPhrase(
      hindi: 'मास्टर जी, आपका नाम क्या है?',
      english: 'Teacher, what is your name?',
      category: 'Questions',
      translations: {
        'Mundari': 'मास्टर जी, आमा: नुतुम चिना:?',
        'Santali': 'ᱢᱟᱥᱴᱟᱨ ᱜᱚᱢᱠᱮ, ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
        'Ho': 'मास्टर जी, आमा: नुतुम चिकना?',
        'Kurukh': 'मास्टर जी, नींघाय नामे इन्दिर रई?',
        'Gondi': 'मास्टर जी, नीवा पद्दोर बाता आंद?',
      },
      phonetics: {
        'Mundari': 'Master ji, aamah nutum chinah?',
        'Santali': 'Master gomke, amag nyutum ched?',
        'Ho': 'Master ji, aamah nutum chikana?',
        'Kurukh': 'Master ji, ninghay name indir raee?',
        'Gondi': 'Master ji, neewa paddor baata aand?',
      },
    ),
    ClassroomPhrase(
      hindi: 'हाँ सर, मुझे समझ आ गया।',
      english: 'Yes sir, I understood.',
      category: 'Tasks',
      translations: {
        'Mundari': 'हे सर, अईंग बुझावकेदा।',
        'Santali': 'ᱦᱮᱸ ᱥᱟᱨ, ᱤᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱼᱟ᱾',
        'Ho': 'हे सर, आईंग बुझियाना।',
        'Kurukh': 'हाअं सर, एन बुझरकन।',
        'Gondi': 'इन सर, नाक समझ मतो।',
      },
      phonetics: {
        'Mundari': 'He sir, aing bujhaokeda.',
        'Santali': 'Heng sir, ing bujhaw ked-a.',
        'Ho': 'He sir, aing bujhiyana.',
        'Kurukh': 'Haa sir, en bujhrkan.',
        'Gondi': 'In sir, naak samajh mato.',
      },
    ),
    ClassroomPhrase(
      hindi: 'सर, मेरी उम्र दस साल है।',
      english: 'Sir, I am ten years old.',
      category: 'Questions',
      translations: {
        'Mundari': 'सर, अईंगआ: उमिर गेले बरिस।',
        'Santali': 'ᱥᱟᱨ, ᱤᱧᱟᱜ ᱩᱢᱮᱨ ᱜᱮᱞ ᱥᱮᱨᱢᱟ᱾',
        'Ho': 'सर, आईंगआ: उमुर गेले साल तानांग।',
        'Kurukh': 'सर, एंगहा उमिर दस बछर रई।',
        'Gondi': 'सर, नावा उमोर पद साल आंद।',
      },
      phonetics: {
        'Mundari': 'Sir, aing-ah umir gele baris.',
        'Santali': 'Sir, ingag umer gel serma.',
        'Ho': 'Sir, aing-ah umur gele saal tanang.',
        'Kurukh': 'Sir, engha umir das bachhar raee.',
        'Gondi': 'Sir, nawa umor pad saal aand.',
      },
    ),
  ];

  // Core Translation Method
  Future<TranslationRecord> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    bool isTeacherSpeaker = true,
  }) async {
    final cleanInput = text.trim();
    if (cleanInput.isEmpty) {
      return TranslationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceText: '',
        translatedText: '',
        phoneticGuide: '',
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        timestamp: DateTime.now(),
        isTeacherSpeaker: isTeacherSpeaker,
      );
    }

    // 0. Live Gemini AI Neural Translation (when configured)
    if (GeminiTranslationService.instance.config.isConfigured) {
      try {
        final geminiResult = await GeminiTranslationService.instance.translate(
          text: cleanInput,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final record = TranslationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceText: cleanInput,
          translatedText: geminiResult.translatedText,
          phoneticGuide: geminiResult.phoneticGuide,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          timestamp: DateTime.now(),
          category: 'Gemini AI',
          isTeacherSpeaker: isTeacherSpeaker,
        );
        _history.insert(0, record);
        return record;
      } catch (e) {
        debugPrint('Gemini API fallback to offline phrasebook: $e');
      }
    }

    // Simulate edge model inference latency (300-500ms)
    await Future.delayed(const Duration(milliseconds: 380));

    // Combine curriculum phrasebook and student-to-teacher phrasebook
    final allPhrases = [...phrasebook, ...studentPhrasebook];

    // 1. Direct phrasebook match (forward & reverse, including phonetics)
    for (final phrase in allPhrases) {
      if (_matches(cleanInput, phrase.hindi) || _matches(cleanInput, phrase.english)) {
        final targetTrans = phrase.translations[targetLang] ??
            (targetLang == 'English' ? phrase.english : phrase.hindi);
        final phonetic = phrase.phonetics[targetLang] ?? '';

        final record = TranslationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceText: cleanInput,
          translatedText: targetTrans,
          phoneticGuide: phonetic,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          timestamp: DateTime.now(),
          category: phrase.category,
          isTeacherSpeaker: isTeacherSpeaker,
        );
        _history.insert(0, record);
        return record;
      }

      // Check tribal translations and phonetics
      for (final entry in phrase.translations.entries) {
        final phoneticVal = phrase.phonetics[entry.key] ?? '';
        if ((entry.key == sourceLang && _matches(cleanInput, entry.value)) ||
            (phoneticVal.isNotEmpty && _matches(cleanInput, phoneticVal))) {
          final targetTrans = targetLang == 'English'
              ? phrase.english
              : (targetLang == 'Hindi'
                  ? phrase.hindi
                  : (phrase.translations[targetLang] ?? phrase.hindi));
          final phonetic = phrase.phonetics[targetLang] ??
              (targetLang == 'Hindi' ? phrase.hindi : phrase.english);

          final record = TranslationRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourceText: cleanInput,
            translatedText: targetTrans,
            phoneticGuide: phonetic,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            timestamp: DateTime.now(),
            category: phrase.category,
            isTeacherSpeaker: isTeacherSpeaker,
          );
          _history.insert(0, record);
          return record;
        }
      }
    }

    // 2. Multi-tier Online Neural Translation (CORS-friendly for Web)
    if ((sourceLang == 'English' && targetLang == 'Hindi') ||
        (sourceLang == 'Hindi' && targetLang == 'English') ||
        targetLang == 'Santali') {
      final online = await _tryOnlineTranslate(cleanInput, sourceLang, targetLang);
      if (online != null && online.translated.isNotEmpty) {
        String phonetic = online.phonetic.trim();
        // If target is Santali or text has Ol Chiki, compute readable Romanized phonetic
        if (targetLang == 'Santali' || RegExp(r'[\u1C50-\u1C7F]').hasMatch(online.translated)) {
          phonetic = olChikiToPhonetic(online.translated);
        } else if (phonetic.isEmpty || phonetic == online.translated) {
          if (targetLang != 'English') {
            phonetic = devanagariToPhonetic(online.translated);
          } else {
            phonetic = online.translated;
          }
        }

        final record = TranslationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceText: cleanInput,
          translatedText: online.translated,
          phoneticGuide: phonetic,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          timestamp: DateTime.now(),
          category: 'Neural AI',
          isTeacherSpeaker: isTeacherSpeaker,
        );
        _history.insert(0, record);
        return record;
      }
    }

    // 3. For Tribal Languages (Mundari, Ho, Kurukh, Gondi, Santali):
    // If source is English, first get Hindi bridge translation to parse semantic intent
    String bridgeInput = cleanInput;
    if (sourceLang == 'English') {
      final hindiBridge = await _tryOnlineTranslate(cleanInput, 'English', 'Hindi');
      if (hindiBridge != null && hindiBridge.translated.isNotEmpty) {
        bridgeInput = hindiBridge.translated;
      }
    }

    // 4. Intelligent Keyword & Semantic Tribal/Bilingual Synthesis
    final synthesized = _synthesizeTranslation(bridgeInput, sourceLang, targetLang, originalInput: cleanInput);
    final record = TranslationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: cleanInput,
      translatedText: synthesized.translated,
      phoneticGuide: synthesized.phonetic,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      timestamp: DateTime.now(),
      category: isTeacherSpeaker ? 'Teacher' : 'Student',
      isTeacherSpeaker: isTeacherSpeaker,
    );
    _history.insert(0, record);
    return record;
  }

  static String? _langCode(String lang) {
    switch (lang) {
      case 'English':
        return 'en';
      case 'Hindi':
        return 'hi';
      case 'Santali':
        return 'sat';
      default:
        return null;
    }
  }

  /// Tries MyMemory API (CORS friendly) first, then Google Translate gtx.
  Future<({String translated, String phonetic})?> _tryOnlineTranslate(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final sl = _langCode(sourceLang);
    final tl = _langCode(targetLang);
    if (sl == null || tl == null) return null;

    // 1. MyMemory Translation API (supports Access-Control-Allow-Origin: * natively)
    if ((sl == 'en' && tl == 'hi') || (sl == 'hi' && tl == 'en')) {
      try {
        final uri = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$sl|$tl',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['responseData'] != null) {
            final trans = (data['responseData']['translatedText'] ?? '').toString().trim();
            if (trans.isNotEmpty &&
                !trans.toUpperCase().contains('MYMEMORY') &&
                !trans.toUpperCase().contains('QUERY LENGTH LIMIT')) {
              return (translated: trans, phonetic: trans);
            }
          }
        }
      } catch (e) {
        debugPrint('MyMemory fallback note: $e');
      }
    }

    // 2. Google Translate Single API
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sl&tl=$tl&dt=t&dt=rm&q=${Uri.encodeComponent(text)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final segments = data[0] as List;
          final buffer = StringBuffer();
          String phonetic = '';

          for (final seg in segments) {
            if (seg is List && seg.isNotEmpty) {
              if (seg[0] is String) {
                buffer.write(seg[0]);
              }
              if (seg.length > 2 && seg[2] is String && (seg[2] as String).isNotEmpty) {
                phonetic = seg[2] as String;
              }
            }
          }

          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            return (translated: translated, phonetic: phonetic);
          }
        }
      }
    } catch (e) {
      debugPrint('Google Translate fallback note: $e');
    }

    return null;
  }

  bool _matches(String a, String b) {
    final normA = a.toLowerCase().replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u1C50-\u1C7F]'), '').trim();
    final normB = b.toLowerCase().replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u1C50-\u1C7F]'), '').trim();
    if (normA.isEmpty || normB.isEmpty) return false;
    return normA == normB || normA.contains(normB) || normB.contains(normA);
  }

  ({String translated, String phonetic}) _synthesizeTranslation(
    String input,
    String sourceLang,
    String targetLang, {
    String? originalInput,
  }) {
    final lower = '${input.toLowerCase()} ${(originalInput ?? '').toLowerCase()}';

    // ── Ho Dedicated Deep Synthesis Engine ───────────────────────────────
    if (targetLang == 'Ho') {
      return _synthesizeHo(lower, input);
    }

    // ── Bidirectional: Student Tribal -> Teacher (Hindi / English) ─────────
    if (targetLang == 'Hindi' || targetLang == 'English') {
      final isEng = targetLang == 'English';

      if (lower.contains('जोहार') || lower.contains('johar') || lower.contains('ᱡᱚᱦᱟᱨ') || lower.contains('सेवा جوहार')) {
        return (
          translated: isEng ? 'Greetings teacher / Hello!' : 'नमस्ते गुरुजी / जोहार!',
          phonetic: isEng ? 'Greetings teacher!' : 'Namaste Guruji / Johar!',
        );
      }

      if (lower.contains('दा:') || lower.contains('दाग') || lower.contains('da:') || lower.contains('dag') ||
          lower.contains('अम्म') || lower.contains('amm') || lower.contains('येर') || lower.contains('yer') ||
          lower.contains('ᱫᱟᱜ') || lower.contains('पानी') || lower.contains('water')) {
        return (
          translated: isEng ? 'Sir, may I drink water?' : 'सर, क्या मैं पानी पीने जा सकता हूँ?',
          phonetic: isEng ? 'Sir, may I drink water?' : 'Sir, kya main paani peene ja sakta hoon?',
        );
      }

      if (lower.contains('बाहर') || lower.contains('bahar') || lower.contains('बाहरे') || lower.contains('bahre') ||
          lower.contains('ᱵᱟᱦᱨᱮ') || lower.contains('toilet') || lower.contains('washroom') || lower.contains('बहरी')) {
        return (
          translated: isEng ? 'Sir, may I go to the washroom / outside?' : 'सर, क्या मैं बाहर (शौचालय) जा सकता हूँ?',
          phonetic: isEng ? 'Sir, may I go to the washroom?' : 'Sir, kya main bahar ja sakta hoon?',
        );
      }

      if (lower.contains('कलम') || lower.contains('kalam') || lower.contains('ᱠᱚᱞᱚᱢ') || lower.contains('pencil') || lower.contains('pen')) {
        return (
          translated: isEng ? 'Sir, I do not have a pen or pencil.' : 'सर, मेरे पास पेंसिल या कलम नहीं है।',
          phonetic: isEng ? 'Sir, I do not have a pen.' : 'Sir, mere paas pencil ya kalam nahi hai.',
        );
      }

      if (lower.contains('पुथी') || lower.contains('puthi') || lower.contains('ᱯᱚᱛᱚᱵ') || lower.contains('potob') || lower.contains('किताब') || lower.contains('book')) {
        return (
          translated: isEng ? 'Sir, I forgot my book at home.' : 'सर, मैं अपनी किताब घर पर भूल गया हूँ।',
          phonetic: isEng ? 'Sir, I forgot my book at home.' : 'Sir, main apni kitab ghar par bhool gaya hoon.',
        );
      }

      if (lower.contains('लाज') || lower.contains('laj') || lower.contains('ᱞᱟᱡ') || lower.contains('पेट') || lower.contains('दर्द') || lower.contains('hasu') || lower.contains('कुल')) {
        return (
          translated: isEng ? 'Sir, my stomach is hurting.' : 'सर, मेरे पेट में बहुत दर्द हो रहा है।',
          phonetic: isEng ? 'Sir, my stomach is hurting.' : 'Sir, mere pet mein dard ho raha hai.',
        );
      }

      if (lower.contains('बोः') || lower.contains('boh') || lower.contains('कुक्क') || lower.contains('तर्रे') || (lower.contains('सिर') && lower.contains('दर्द'))) {
        return (
          translated: isEng ? 'Sir, I have a severe headache.' : 'सर, मेरे सिर में बहुत दर्द हो रहा है।',
          phonetic: isEng ? 'Sir, I have a severe headache.' : 'Sir, mere sir mein bahut dard ho raha hai.',
        );
      }

      if (lower.contains('रुआ') || lower.contains('rua') || lower.contains('रुवा') || lower.contains('ruwa') || lower.contains('ᱨᱩᱣᱟᱹ') || lower.contains('बुखार') || lower.contains('fever')) {
        return (
          translated: isEng ? 'Sir, I am feeling feverish and unwell.' : 'सर, मुझे बुखार और तबियत खराब लग रही है।',
          phonetic: isEng ? 'Sir, I am feeling feverish.' : 'Sir, mujhe bukhar lag raha hai.',
        );
      }

      if (lower.contains('जीव का बुगिन') || lower.contains('jeev ka bugin')) {
        return (
          translated: isEng ? 'Sir, I am feeling unwell. May I go home?' : 'सर, मेरी तबियत ठीक नहीं है। क्या मैं घर जा सकता हूँ?',
          phonetic: isEng ? 'Sir, I am feeling unwell. May I go home?' : 'Sir, meri tabiyat theek nahi hai. Kya main ghar ja sakta hoon?',
        );
      }

      if (lower.contains('चाबा') || lower.contains('chaba') || lower.contains('चाबायाना') || lower.contains('chabayana') || lower.contains('ᱯᱩᱨᱟᱹᱣ') || lower.contains('puraw') || lower.contains('होयगेना') || lower.contains('finished') || lower.contains('done')) {
        return (
          translated: isEng ? 'Sir, I have finished my task.' : 'सर, मैंने अपना काम पूरा कर लिया है।',
          phonetic: isEng ? 'Sir, I have finished my task.' : 'Sir, maine apna kaam poora kar liya hai.',
        );
      }

      if (lower.contains('काइंग') || lower.contains('kaing') || lower.contains('बुझिया') || lower.contains('bujhiya') || lower.contains('ᱵᱟᱹᱧ') || lower.contains('banj') || lower.contains('बुझाव') || lower.contains('bujhaw') || lower.contains('समझ')) {
        return (
          translated: isEng ? 'Sir, I did not understand. Please explain again.' : 'सर, मुझे समझ नहीं आया। कृपया फिर से बताइए।',
          phonetic: isEng ? 'Sir, I did not understand.' : 'Sir, mujhe samajh nahi aaya. Kripya fir se batayein.',
        );
      }

      if (lower.contains('नुतुम') || lower.contains('nutum') || lower.contains('नामे') || lower.contains('paddor')) {
        return (
          translated: isEng ? 'Teacher, what is your name?' : 'मास्टर जी, आपका नाम क्या है?',
          phonetic: isEng ? 'Teacher, what is your name?' : 'Master ji, aapka naam kya hai?',
        );
      }

      if (lower.contains('उमुर') || lower.contains('umur')) {
        return (
          translated: isEng ? 'Teacher, what is your age?' : 'मास्टर जी, आपकी उम्र कितनी है?',
          phonetic: isEng ? 'Teacher, what is your age?' : 'Master ji, aapki umr kitni hai?',
        );
      }

      if (lower.contains('सराहाव') || lower.contains('sarahaw') || lower.contains('धन्यवाद')) {
        return (
          translated: isEng ? 'Thank you, teacher!' : 'धन्यवाद गुरुजी!',
          phonetic: isEng ? 'Thank you teacher!' : 'Dhanyawaad Guruji!',
        );
      }

      if (lower == 'हे' || lower == 'he' || lower == 'हे सर' || lower == 'he sir') {
        return (translated: isEng ? 'Yes sir.' : 'हाँ सर।', phonetic: isEng ? 'Yes sir.' : 'Haan sir.');
      }

      if (lower == 'का' || lower == 'ka' || lower == 'का सर' || lower == 'ka sir') {
        return (translated: isEng ? 'No sir.' : 'नहीं सर।', phonetic: isEng ? 'No sir.' : 'Nahi sir.');
      }

      // Tribal counting check
      if (lower.contains('मियद') || lower.contains('mid') || lower.contains('ᱢᱤᱫ') || lower.contains('ओन्त') || lower.contains('उंदी')) {
        return (translated: isEng ? 'Number 1 (One)' : 'संख्या १ (एक)', phonetic: isEng ? 'One' : 'Ek');
      }
      if (lower.contains('बारिया') || lower.contains('bar') || lower.contains('ᱵᱟᱨ') || lower.contains('एरड़') || lower.contains('रंड')) {
        return (translated: isEng ? 'Number 2 (Two)' : 'संख्या २ (दो)', phonetic: isEng ? 'Two' : 'Do');
      }
      if (lower.contains('आपिया') || lower.contains('आपेया') || lower.contains('pe') || lower.contains('ᱯᱮ') || lower.contains('मूंद')) {
        return (translated: isEng ? 'Number 3 (Three)' : 'संख्या ३ (तीन)', phonetic: isEng ? 'Three' : 'Teen');
      }
      if (lower.contains('उपुन') || lower.contains('pun') || lower.contains('ᱯᱩᱱ') || lower.contains('नाख') || lower.contains('नालुंग')) {
        return (translated: isEng ? 'Number 4 (Four)' : 'संख्या ४ (चार)', phonetic: isEng ? 'Four' : 'Chaar');
      }
      if (lower.contains('मोणोय') || lower.contains('मोणोया') || lower.contains('mone') || lower.contains('ᱢᱚᱬᱮ') || lower.contains('पांच') || lower.contains('सय्युंग')) {
        return (translated: isEng ? 'Number 5 (Five)' : 'संख्या ५ (पाँच)', phonetic: isEng ? 'Five' : 'Paanch');
      }
      if (lower.contains('तुरूय') || lower.contains('तुरूया') || lower.contains('turui') || lower.contains('ᱛᱩᱨᱩᱭ') || lower.contains('सोये') || lower.contains('सारुंग')) {
        return (translated: isEng ? 'Number 6 (Six)' : 'संख्या ६ (छह)', phonetic: isEng ? 'Six' : 'Chhah');
      }
      if (lower.contains('एया') || lower.contains('eyay') || lower.contains('ᱮᱭᱟᱭ') || lower.contains('सत्ते') || lower.contains('येड़ुंग')) {
        return (translated: isEng ? 'Number 7 (Seven)' : 'संख्या ७ (सात)', phonetic: isEng ? 'Seven' : 'Saat');
      }
      if (lower.contains('इरिया') || lower.contains('iril') || lower.contains('ᱤᱨᱟᱹᱞ') || lower.contains('अठ्ठे') || lower.contains('एण्मुंग')) {
        return (translated: isEng ? 'Number 8 (Eight)' : 'संख्या ८ (आठ)', phonetic: isEng ? 'Eight' : 'Aath');
      }
      if (lower.contains('आरेया') || lower.contains('aare') || lower.contains('ᱟᱨᱮ') || lower.contains('नोये') || lower.contains('नोरुंग')) {
        return (translated: isEng ? 'Number 9 (Nine)' : 'संख्या ९ (नौ)', phonetic: isEng ? 'Nine' : 'Nau');
      }
      if (lower.contains('गेले') || lower.contains('gel') || lower.contains('ᱜᱮᱞ') || lower.contains('दस्से') || lower.contains('पद')) {
        return (translated: isEng ? 'Number 10 (Ten)' : 'संख्या १० (दस)', phonetic: isEng ? 'Ten' : 'Das');
      }
    }

    // ── English -> Hindi Common Conversational Mapping ───────────────────
    if (targetLang == 'Hindi') {
      if (lower.contains('how are you') || lower.contains('how r u')) {
        return (translated: 'आप कैसे हैं?', phonetic: 'Aap kaise hain?');
      }
      if (lower.contains('good morning') || lower.contains('morning')) {
        return (translated: 'सुप्रभात! आप सब कैसे हैं?', phonetic: 'Suprabhat! Aap sab kaise hain?');
      }
      if (lower.contains('good afternoon')) {
        return (translated: 'शुभ दोपहर!', phonetic: 'Shubh dopahar!');
      }
      if (lower.contains('what is your name')) {
        return (translated: 'आपका नाम क्या है?', phonetic: 'Aapka naam kya hai?');
      }
      if (lower.contains('my name is')) {
        final name = input.split(RegExp(r'name is', caseSensitive: false)).last.trim();
        return (translated: 'मेरा नाम $name है।', phonetic: 'Mera naam $name hai.');
      }
      if (lower.contains('sit down') || lower.contains('please sit')) {
        return (translated: 'कृपया बैठ जाइए।', phonetic: 'Kripya baith jaiye.');
      }
      if (lower.contains('stand up')) {
        return (translated: 'खड़े हो जाइए।', phonetic: 'Khade ho jaiye.');
      }
      if (lower.contains('open your book') || lower.contains('open book')) {
        return (translated: 'अपनी किताब खोलिए।', phonetic: 'Apni kitab kholiye.');
      }
      if (lower.contains('quiet') || lower.contains('silence') || lower.contains('be quiet')) {
        return (translated: 'शांत रहिए और ध्यान से सुनिए।', phonetic: 'Shaant rahiye aur dhyan se suniye.');
      }
      if (lower.contains('thank you') || lower.contains('thanks')) {
        return (translated: 'धन्यवाद!', phonetic: 'Dhanyawaad!');
      }
      if (lower.contains('very good') || lower.contains('well done') || lower.contains('good job')) {
        return (translated: 'शाबाश! बहुत अच्छा किया।', phonetic: 'Shabash! Bahut achha kiya.');
      }
      if (lower.contains('drink water') || lower.contains('drink')) {
        return (translated: 'पानी पी लो।', phonetic: 'Paani pee lo.');
      }
      if (lower.contains('washroom') || lower.contains('toilet') || lower.contains('bathroom')) {
        return (translated: 'शौचालय चले जाओ।', phonetic: 'Shauchalay chale jao.');
      }
      if (lower.contains('come here')) {
        return (translated: 'यहाँ आओ।', phonetic: 'Yahan aao.');
      }
      if (lower.contains('go home')) {
        return (translated: 'घर जाओ।', phonetic: 'Ghar jao.');
      }
      if (lower.contains('write') || lower.contains('writing')) {
        return (translated: 'अपनी कॉपी में लिखो।', phonetic: 'Apni copy mein likho.');
      }
      if (lower.contains('read') || lower.contains('reading')) {
        return (translated: 'यह पाठ ध्यान से पढ़ो।', phonetic: 'Yeh paath dhyan se padho.');
      }
      if (lower.contains('listen')) {
        return (translated: 'ध्यान से सुनो।', phonetic: 'Dhyan se suno.');
      }
      if (lower.contains('hello') || lower.contains('hi')) {
        return (translated: 'नमस्ते बच्चों!', phonetic: 'Namaste bachon!');
      }
    }

    // ── Hindi -> English Common Conversational Mapping ───────────────────
    if (targetLang == 'English') {
      if (lower.contains('आप कैसे हैं') || lower.contains('कैसे हो')) {
        return (translated: 'How are you?', phonetic: 'How are you?');
      }
      if (lower.contains('सुप्रभात') || lower.contains('नमस्ते')) {
        return (translated: 'Good morning / Hello everyone!', phonetic: 'Good morning!');
      }
      if (lower.contains('बैठ') || lower.contains('बैठिए')) {
        return (translated: 'Please sit down.', phonetic: 'Please sit down.');
      }
      if (lower.contains('खड़े') || lower.contains('उठो')) {
        return (translated: 'Please stand up.', phonetic: 'Please stand up.');
      }
      if (lower.contains('शांत') || lower.contains('चुप')) {
        return (translated: 'Please be quiet and pay attention.', phonetic: 'Please be quiet.');
      }
      if (lower.contains('किताब') && (lower.contains('खोल') || lower.contains('पन्ना'))) {
        return (translated: 'Please open your books.', phonetic: 'Please open your books.');
      }
      if (lower.contains('धन्यवाद') || lower.contains('शुक्रिया')) {
        return (translated: 'Thank you very much!', phonetic: 'Thank you!');
      }
      if (lower.contains('शाबाश') || lower.contains('बहुत अच्छा')) {
        return (translated: 'Well done! Very good.', phonetic: 'Well done!');
      }
      if (lower.contains('पानी') && (lower.contains('पी') || lower.contains('जाओ'))) {
        return (translated: 'Yes, you may drink water.', phonetic: 'You may drink water.');
      }
      if (lower.contains('बाहर') || lower.contains('शौचालय')) {
        return (translated: 'Yes, you may go outside / washroom.', phonetic: 'You may go outside.');
      }
      if (lower.contains('लिख') || lower.contains('कॉपी')) {
        return (translated: 'Write this in your notebook.', phonetic: 'Write this.');
      }
      if (lower.contains('पढ़') || lower.contains('पाठ')) {
        return (translated: 'Read this lesson carefully.', phonetic: 'Read this lesson.');
      }
    }

    // ── Teacher -> Tribal Language Synthesis ─────────────────────────────
    if (lower.contains('किताब') || lower.contains('book') || lower.contains('पुथी')) {
      if (targetLang == 'Mundari') return (translated: 'पुथी ओलपे अड़ो पाड़ावपे।', phonetic: 'Puthi olpe ado padawpe.');
      if (targetLang == 'Santali') return (translated: 'ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ ᱟᱨ ᱯᱟᱲᱦᱟᱣ ᱢᱮ᱾', phonetic: 'Potob jhij me ar padhaw me.');
      if (targetLang == 'Ho') return (translated: 'पुथी उडुंएपे अड़ो पाड़ावपे।', phonetic: 'Puthi udungepe ado padawpe.');
      if (targetLang == 'Kurukh') return (translated: 'किताब गही पन्ना तिंगा।', phonetic: 'Kitab gahi panna tinga.');
      if (targetLang == 'Gondi') return (translated: 'किताब पोसी कीसी केंजाट।', phonetic: 'Kitab posi keesi kenjaat.');
    }

    if (lower.contains('पानी') || lower.contains('water') || lower.contains('दाग')) {
      if (targetLang == 'Mundari') return (translated: 'दा: नू लेका मेनामेया?', phonetic: 'Da: nu leka menameya?');
      if (targetLang == 'Santali') return (translated: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ᱾', phonetic: 'Dag nyu me.');
      if (targetLang == 'Ho') return (translated: 'दा: नू सेनोःपे।', phonetic: 'Da: nu senohpe.');
      if (targetLang == 'Kurukh') return (translated: 'अम्म ओना।', phonetic: 'Amm ona.');
      if (targetLang == 'Gondi') return (translated: 'येर उना।', phonetic: 'Yer oona.');
    }

    if (lower.contains('गिनती') || lower.contains('number') || lower.contains('संख्या') || lower.contains('count')) {
      if (targetLang == 'Mundari') return (translated: 'मियद, बारिया, आपिया, उपुन, मोणोय...', phonetic: 'Miyad, bariya, aapiya, upun, monoy...');
      if (targetLang == 'Santali') return (translated: 'ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱩᱱ, ᱢᱚᱬᱮ...', phonetic: 'Mid, bar, pe, pun, mone...');
      if (targetLang == 'Ho') return (translated: 'मियद, बारिया, आपेया, उपुन, मोणोया...', phonetic: 'Miyad, bariya, apeya, upun, monoya...');
      if (targetLang == 'Kurukh') return (translated: 'ओन्त, एरड़, मूंद, नाख, पांच...', phonetic: 'Ond, end, moond, naakh, panch...');
      if (targetLang == 'Gondi') return (translated: 'उंदी, रंड, मूंड, नालुंग, सय्युंग...', phonetic: 'Undi, rand, moond, naalung, sayyung...');
    }

    if (lower.contains('बैठ') || lower.contains('sit') || lower.contains('बैठिए')) {
      if (targetLang == 'Mundari') return (translated: 'दुबुपे!', phonetic: 'Dubupe!');
      if (targetLang == 'Santali') return (translated: 'ᱫᱩᱲᱩᱵ ᱯᱮ!', phonetic: 'Durup pe!');
      if (targetLang == 'Ho') return (translated: 'दुबुपे!', phonetic: 'Dubupe!');
      if (targetLang == 'Kurukh') return (translated: 'उक्का!', phonetic: 'Ukka!');
      if (targetLang == 'Gondi') return (translated: 'बहाट!', phonetic: 'Bahaat!');
    }

    if (lower.contains('खड़े') || lower.contains('stand') || lower.contains('उठो')) {
      if (targetLang == 'Mundari') return (translated: 'तिंगुपे!', phonetic: 'Tingupe!');
      if (targetLang == 'Santali') return (translated: 'ᱛᱤᱸᱜᱩᱱ ᱯᱮ!', phonetic: 'Tingun pe!');
      if (targetLang == 'Ho') return (translated: 'तिंगुपे!', phonetic: 'Tingupe!');
      if (targetLang == 'Kurukh') return (translated: 'इद्दा!', phonetic: 'Idda!');
      if (targetLang == 'Gondi') return (translated: 'तेदाट!', phonetic: 'Tedaat!');
    }

    if (lower.contains('शांत') || lower.contains('quiet') || lower.contains('listen') || lower.contains('सुनो')) {
      if (targetLang == 'Mundari') return (translated: 'थिरुपे अड़ो ध्यान ते आयुमपे!', phonetic: 'Thirupe ado dhyan te aayumpe!');
      if (targetLang == 'Santali') return (translated: 'ᱛᱷᱤᱨᱩᱜ ᱯᱮ ᱟᱨ ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱯᱮ!', phonetic: 'Thirug pe ar dhyan te anjom pe!');
      if (targetLang == 'Ho') return (translated: 'थिरुपे अड़ो सुकुर ते आयुमपे!', phonetic: 'Thirupe ado sukur te aayumpe!');
      if (targetLang == 'Kurukh') return (translated: 'सांत रहो आरे ध्यान ती मेना!', phonetic: 'Sant raho aare dhyan tee mena!');
      if (targetLang == 'Gondi') return (translated: 'शांत मनजाट अन ध्यान ती केंजात!', phonetic: 'Shant manjaat an dhyan tee kenjaat!');
    }

    if (lower.contains('नमस्ते') || lower.contains('hello') || lower.contains('morning') || lower.contains('greetings')) {
      if (targetLang == 'Mundari') return (translated: 'जोहार गड़ाको, आपे चिलके मेनापेया?', phonetic: 'Johar gadako, ape chilke menapeya?');
      if (targetLang == 'Santali') return (translated: 'ᱡᱚᱦᱟᱨ ᱜᱤᱫᱽᱨᱟᱹ, ᱟᱯᱮ ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱯᱮᱭᱟ?', phonetic: 'Johar gidra, ape ched leka menag peya?');
      if (targetLang == 'Ho') return (translated: 'जोहार होनको, आपे चिलके मेनापेया?', phonetic: 'Johar honko, ape chilke menapeya?');
      if (targetLang == 'Kurukh') return (translated: 'जोहार तंगड़ाको, नीम एकाने रईत?', phonetic: 'Johar tangdako, neem ekane reet?');
      if (targetLang == 'Gondi') return (translated: 'जय जोहार पिलाक, मीर बोर आंदित?', phonetic: 'Jai Johar pilak, meer bor aandeet?');
    }

    if (lower.contains('हाँ') || lower.contains('yes') || lower.contains('जाओ') || lower.contains('पी लो')) {
      if (targetLang == 'Mundari') return (translated: 'हे, सेनोःमे!', phonetic: 'He, senohme!');
      if (targetLang == 'Santali') return (translated: 'ᱦᱮᱸ, ᱪᱟᱞᱟᱣ ᱢᱮ!', phonetic: 'Heng, chalaw me!');
      if (targetLang == 'Ho') return (translated: 'हे, सेनेयामे!', phonetic: 'He, seneyame!');
      if (targetLang == 'Kurukh') return (translated: 'हाअं, काला!', phonetic: 'Haa, kaala!');
      if (targetLang == 'Gondi') return (translated: 'इन, हान!', phonetic: 'In, haan!');
    }

    if (lower.contains('धन्यवाद') || lower.contains('thank')) {
      if (targetLang == 'Mundari') return (translated: 'सराहाव!', phonetic: 'Sarahaw!');
      if (targetLang == 'Santali') return (translated: 'ᱥᱟᱨᱦᱟᱣ!', phonetic: 'Sarhaw!');
      if (targetLang == 'Ho') return (translated: 'सराहाव!', phonetic: 'Sarahaw!');
      if (targetLang == 'Kurukh') return (translated: 'धनबाद!', phonetic: 'Dhanbad!');
      if (targetLang == 'Gondi') return (translated: 'सेवा जोहार!', phonetic: 'Seva Johar!');
    }

    if (lower.contains('कहाँ') || lower.contains('where') || lower.contains('जा रहे')) {
      if (targetLang == 'Mundari') return (translated: 'आम ओकोते सेंनोःतानाम?', phonetic: 'Aam okote senoh-tanam?');
      if (targetLang == 'Santali') return (translated: 'ᱟᱢ ᱚᱠᱟᱛᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?', phonetic: 'Am okatem chalag kana?');
      if (targetLang == 'Ho') return (translated: 'आम ओकोते सेनेयातानाम?', phonetic: 'Aam okote seneyatanam?');
      if (targetLang == 'Kurukh') return (translated: 'नीन एका तरा कालो?', phonetic: 'Neen eka tara kaalo?');
      if (targetLang == 'Gondi') return (translated: 'नीम बागा हानोन?', phonetic: 'Neem baga haanon?');
    }

    if (lower.contains('क्या कर रहे') || lower.contains('what are you doing')) {
      if (targetLang == 'Mundari') return (translated: 'आम चिना: चिकेतानाम?', phonetic: 'Aam chinah chiketanam?');
      if (targetLang == 'Santali') return (translated: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱼᱟ?', phonetic: 'Am ched em chikayed-a?');
      if (targetLang == 'Ho') return (translated: 'आम चिकना चिकेतानाम?', phonetic: 'Aam chikana chiketanam?');
      if (targetLang == 'Kurukh') return (translated: 'नीन इन्दिर ननदी?', phonetic: 'Neen indir nandee?');
      if (targetLang == 'Gondi') return (translated: 'नीम बाता कीसी आंदी?', phonetic: 'Neem bata keesi aandi?');
    }

    if (lower.contains('यहाँ आओ') || lower.contains('come here') || lower.contains('अंदर आओ') || lower.contains('come in')) {
      if (targetLang == 'Mundari') return (translated: 'नेते हिजुःमे / भीतरे हिजुःमे।', phonetic: 'Nete hijuhme / Bheetre hijuhme.');
      if (targetLang == 'Santali') return (translated: 'ᱱᱚᱰᱮ ᱦᱤᱡᱩᱜ ᱢᱮ / ᱵᱷᱤᱛᱨᱤ ᱦᱤᱡᱩᱜ ᱢᱮ᱾', phonetic: 'Node hijug me / Bhitri hijug me.');
      if (targetLang == 'Ho') return (translated: 'नेते हिजुःमे।', phonetic: 'Nete hijuhme.');
      if (targetLang == 'Kurukh') return (translated: 'ईसा बारके / भीतर बारके।', phonetic: 'Eesa baarke / Bheetar baarke.');
      if (targetLang == 'Gondi') return (translated: 'हिका वारा / लोपे वारा।', phonetic: 'Hika wara / Lope wara.');
    }

    if (lower.contains('कॉपी दिखाओ') || lower.contains('show') && (lower.contains('copy') || lower.contains('notebook') || lower.contains('काम'))) {
      if (targetLang == 'Mundari') return (translated: 'आमा: कॉपी अईंग ता:रे ओदोङेमे।', phonetic: 'Aamah copy aing ta:re odongeme.');
      if (targetLang == 'Santali') return (translated: 'ᱟᱢᱟᱜ ᱠᱷᱟᱛᱟ ᱤᱧ ᱩᱫᱩᱜ ᱟᱹᱧ ᱢᱮ᱾', phonetic: 'Amag khata ing udug anj me.');
      if (targetLang == 'Ho') return (translated: 'आमा: कॉपी आईंगके ओदोङेमे।', phonetic: 'Aamah copy aingke odongeme.');
      if (targetLang == 'Kurukh') return (translated: 'तंगहाय कॉपी एंगहा एरा।', phonetic: 'Tanghay copy engha era.');
      if (targetLang == 'Gondi') return (translated: 'नीवा कॉपी नाक वोहटा।', phonetic: 'Neewa copy naak wohta.');
    }

    if (lower.contains('खाना') || lower.contains('food') || lower.contains('lunch') || lower.contains('खाओ')) {
      if (targetLang == 'Mundari') return (translated: 'मंडी जोमेपे।', phonetic: 'Mandi jomepe.');
      if (targetLang == 'Santali') return (translated: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱯᱮ᱾', phonetic: 'Daka jom pe.');
      if (targetLang == 'Ho') return (translated: 'मंडी जोमेपे।', phonetic: 'Mandi jomepe.');
      if (targetLang == 'Kurukh') return (translated: 'मंडी ओना।', phonetic: 'Mandi ona.');
      if (targetLang == 'Gondi') return (translated: 'गाटो तिंजाट।', phonetic: 'Gaato tinjaat.');
    }

    if (lower.contains('समझ आया') || lower.contains('understand') || lower.contains('समझे')) {
      if (targetLang == 'Mundari') return (translated: 'आपे बुझावकेदापे?', phonetic: 'Ape bujhaokedape?');
      if (targetLang == 'Santali') return (translated: 'ᱟᱯᱮ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱼᱟ ᱯᱮ?', phonetic: 'Ape bujhaw ked-a pe?');
      if (targetLang == 'Ho') return (translated: 'आपे बुझियानापे?', phonetic: 'Ape bujhiyanape?');
      if (targetLang == 'Kurukh') return (translated: 'नीम बुझरकर?', phonetic: 'Neem bujhrkar?');
      if (targetLang == 'Gondi') return (translated: 'मीर समझ मतित?', phonetic: 'Meer samajh mateet?');
    }

    if (lower.contains('शोर') || lower.contains('noise') || lower.contains('don\'t talk') || lower.contains('बात मत करो')) {
      if (targetLang == 'Mundari') return (translated: 'हो-हो कापे कजीया, थिरुपे!', phonetic: 'Ho-ho kape kajiya, thirupe!');
      if (targetLang == 'Santali') return (translated: 'ᱦᱚᱸ-ᱦᱚᱸ ᱟᱞᱚ ᱯᱮ ᱠᱚᱨᱟᱣᱼᱟ, ᱛᱷᱤᱨᱩᱜ ᱯᱮ!', phonetic: 'Ho-ho alo pe koraw-a, thirug pe!');
      if (targetLang == 'Ho') return (translated: 'सोर-गुल कापेया, थिरुपे!', phonetic: 'Shor-gul kapeya, thirupe!');
      if (targetLang == 'Kurukh') return (translated: 'गोहारो मल्ला, सांत रहो!', phonetic: 'Goharo malla, sant raho!');
      if (targetLang == 'Gondi') return (translated: 'गोंधल कीमाट, शांत मनजाट!', phonetic: 'Gondhal keemat, shant manjaat!');
    }

    if (lower.contains('बोर्ड') || lower.contains('board') || lower.contains('blackboard')) {
      if (targetLang == 'Mundari') return (translated: 'ब्लैकबोर्ड साफकेपे अड़ो ओलपे।', phonetic: 'Blackboard saafkepe ado olpe.');
      if (targetLang == 'Santali') return (translated: 'ᱵᱞᱮᱠᱵᱚᱨᱰ ᱥᱟᱯᱷᱟᱭ ᱢᱮ ᱟᱨ ᱚᱞ ᱢᱮ᱾', phonetic: 'Blackboard saphay me ar ol me.');
      if (targetLang == 'Ho') return (translated: 'बोर्ड साफकेपे अड़ो ओलेपे।', phonetic: 'Board saafkepe ado olepe.');
      if (targetLang == 'Kurukh') return (translated: 'बोर्डन साफ नना आरे इरा।', phonetic: 'Board-an saaf nana aare ira.');
      if (targetLang == 'Gondi') return (translated: 'बोर्ड साफ कीमा अन तोहा।', phonetic: 'Board saaf keema an toha.');
    }

    if (lower.contains('उम्र') || lower.contains('age') || lower.contains('old are you')) {
      if (targetLang == 'Mundari') return (translated: 'आमा: उमिर चिमिन बरिस?', phonetic: 'Aamah umir chimin baris?');
      if (targetLang == 'Santali') return (translated: 'ᱟᱢᱟᱜ ᱩᱢᱮᱨ ᱛᱤᱱᱟᱹᱜ?', phonetic: 'Amag umer tinag?');
      if (targetLang == 'Ho') return (translated: 'आमा: उमुर चिमिन?', phonetic: 'Aamah umur chimin?');
      if (targetLang == 'Kurukh') return (translated: 'नींघाय उमिर एका रई?', phonetic: 'Ninghay umir eka ree?');
      if (targetLang == 'Gondi') return (translated: 'नीवा उमोर बाचुंद आंद?', phonetic: 'Neewa umor bachund aand?');
      if (targetLang == 'Hindi') return (translated: 'आपकी उम्र कितनी है?', phonetic: 'Aapki umr kitni hai?');
      if (targetLang == 'English') return (translated: "What is your age?", phonetic: "What is your age?");
    }

    // Default dialectal translation with authentic phonetic scaffolding
    switch (targetLang) {
      case 'Mundari':
        return (
          translated: 'गड़ाको, ध्यान ते आयुमपे: $input',
          phonetic: 'Gadako, dhyan te aayumpe: $input',
        );
      case 'Santali':
        return (
          translated: 'ᱜᱤᱫᱽᱨᱟᱹ, ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱯᱮ: $input',
          phonetic: olChikiToPhonetic('ᱜᱤᱫᱽᱨᱟᱹ, ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱯᱮ: $input'),
        );
      case 'Ho':
        return _synthesizeHo(lower, input);
      case 'Kurukh':
        return (
          translated: 'तंगड़ाको, ध्यान ती मेना: $input',
          phonetic: 'Tangdako, dhyan tee mena: $input',
        );
      case 'Gondi':
        return (
          translated: 'पिलाक, ध्यान ती केंजात: $input',
          phonetic: 'Pilak, dhyan tee kenjaat: $input',
        );
      case 'Hindi':
        return (
          translated: 'अनुवाद: $input',
          phonetic: 'Anuvaad: $input',
        );
      default:
        return (
          translated: 'Translation: $input',
          phonetic: input,
        );
    }
  }

  /// Dedicated authentic Kolhan Ho language translation and synthesis engine
  ({String translated, String phonetic}) _synthesizeHo(String lower, String rawInput) {
    // 1. Identity & Name
    if (lower.contains('what is your name') || lower.contains("what's your name") ||
        lower.contains('नाम क्या है') || lower.contains('तुम्हारा नाम') || lower.contains('आपका नाम') ||
        (lower.contains('नाम') && (lower.contains('बताओ') || lower.contains('पूछ')))) {
      return (
        translated: 'आमा: नुतुम चिकना?',
        phonetic: 'Aamah nutum chikana?',
      );
    }

    if (lower.contains('my name is') || lower.contains('मेरा नाम')) {
      final name = rawInput.split(RegExp(r'name is|मेरा नाम', caseSensitive: false)).last.replaceAll(RegExp(r'[।.]'), '').trim();
      final display = name.isNotEmpty ? name : 'होन';
      return (
        translated: 'आईंगआ: नुतुम $display तानांग।',
        phonetic: 'Aing-ah nutum $display tanang.',
      );
    }

    if (lower.contains('who are you') || lower.contains('तुम कौन हो') || lower.contains('आप कौन हैं')) {
      return (
        translated: 'आम ओकोए तानाम?',
        phonetic: 'Aam okoe tanam?',
      );
    }

    // 2. Age
    if (lower.contains('age') || lower.contains('old are you') || lower.contains('उम्र') || lower.contains('साल के')) {
      return (
        translated: 'आमा: उमुर चिमिन?',
        phonetic: 'Aamah umur chimin?',
      );
    }

    // 3. Where / Location
    if (lower.contains('where do you live') || lower.contains('कहाँ रहते') || lower.contains('घर कहाँ')) {
      return (
        translated: 'आमा: ओवा: ओकोरे?',
        phonetic: 'Aamah owaah okore?',
      );
    }

    if (lower.contains('where are you going') || (lower.contains('कहाँ') && lower.contains('जा रहे'))) {
      return (
        translated: 'आम ओकोते सेनेयातानाम?',
        phonetic: 'Aam okote seneyatanam?',
      );
    }

    // 4. Greetings & Well-being
    if (lower.contains('how are you') || lower.contains('how r u') || lower.contains('कैसे हो') || lower.contains('कैसे हैं') || lower.contains('हाल चाल')) {
      return (
        translated: 'आम चिलके मेनामा? (सोबेनको, आपे चिलके मेनापेया?)',
        phonetic: 'Aam chilke menama? (Sobenko, ape chilke menapeya?)',
      );
    }

    if (lower.contains('i am fine') || lower.contains('सब ठीक') || lower.contains('मैं ठीक')) {
      return (
        translated: 'आईंग बुगिन मेनाईंग।',
        phonetic: 'Aing bugin menaing.',
      );
    }

    if (lower.contains('good morning') || lower.contains('नमस्ते') || lower.contains('सुप्रभात') || lower.contains('hello') || lower.contains('hi')) {
      return (
        translated: 'जोहार होनको, आपे चिलके मेनापेया?',
        phonetic: 'Johar honko, ape chilke menapeya?',
      );
    }

    // 5. Classroom Commands
    if (lower.contains('sit down') || lower.contains('बैठ') || lower.contains('बैठिए') || lower.contains('बैठो')) {
      return (
        translated: 'सोबेन होनको, दुबुपे!',
        phonetic: 'Soben honko, dubupe!',
      );
    }

    if (lower.contains('stand up') || lower.contains('खड़े') || lower.contains('उठो')) {
      return (
        translated: 'सोबेन होनको, तिंगुपे!',
        phonetic: 'Soben honko, tingupe!',
      );
    }

    if (lower.contains('come here') || lower.contains('यहाँ आओ') || lower.contains('इधर आओ')) {
      return (
        translated: 'नेते हिजुःमे!',
        phonetic: 'Nete hijuhme!',
      );
    }

    if (lower.contains('come in') || lower.contains('अंदर आओ')) {
      return (
        translated: 'भीतरे हिजुःमे!',
        phonetic: 'Bheetre hijuhme!',
      );
    }

    if (lower.contains('go there') || lower.contains('वहाँ जाओ')) {
      return (
        translated: 'हन्ते सेनेयामे!',
        phonetic: 'Hante seneyame!',
      );
    }

    if (lower.contains('go home') || lower.contains('घर जाओ')) {
      return (
        translated: 'ओवा: सेनेयापे!',
        phonetic: 'Owaah seneyape!',
      );
    }

    if (lower.contains('open') && (lower.contains('book') || lower.contains('किताब'))) {
      return (
        translated: 'आपेआग पुथी उडुंएपे अड़ो पाड़ावपे।',
        phonetic: 'Apeag puthi udungepe ado padawpe.',
      );
    }

    if (lower.contains('close') && (lower.contains('book') || lower.contains('किताब'))) {
      return (
        translated: 'पुथी बोंदकेपे!',
        phonetic: 'Puthi bondkepe!',
      );
    }

    if (lower.contains('write') || lower.contains('लिख') || lower.contains('नोटबुक') || lower.contains('कॉपी')) {
      return (
        translated: 'आपेआग खाता रे नेना ओलेपे।',
        phonetic: 'Apeag khata re nena olepe.',
      );
    }

    if (lower.contains('read') || lower.contains('पढ़') || lower.contains('पाठ')) {
      return (
        translated: 'नेना पाड़ाव आपेआग पुथी रे पाड़ावपे।',
        phonetic: 'Nena padaw apeag puthi re padawpe.',
      );
    }

    if (lower.contains('quiet') || lower.contains('silence') || lower.contains('शांत') || lower.contains('चुप')) {
      return (
        translated: 'थिरुपे अड़ो सुकुर ते आयुमपे!',
        phonetic: 'Thirupe ado sukur te aayumpe!',
      );
    }

    if (lower.contains('noise') || lower.contains('शोर') || lower.contains('बात मत करो') || lower.contains("don't talk")) {
      return (
        translated: 'सोर-गुल कापेया, थिरुपे!',
        phonetic: 'Shor-gul kapeya, thirupe!',
      );
    }

    if (lower.contains('listen') || lower.contains('सुनो') || lower.contains('ध्यान')) {
      return (
        translated: 'सुकुर ते आयुमपे!',
        phonetic: 'Sukur te aayumpe!',
      );
    }

    if (lower.contains('board') || lower.contains('बोर्ड') || lower.contains('श्यामपट्ट')) {
      if (lower.contains('clean') || lower.contains('साफ')) {
        return (translated: 'बोर्ड साफकेपे अड़ो ओलेपे।', phonetic: 'Board saafkepe ado olepe.');
      }
      return (translated: 'ब्लैकबोर्ड नेते नेलेपे!', phonetic: 'Blackboard nete nelepe!');
    }

    if (lower.contains('show') || lower.contains('दिखाओ')) {
      return (
        translated: 'आमा: खाता आईंगके ओदोङेमे।',
        phonetic: 'Aamah khata aingke odongeme.',
      );
    }

    // 6. Permissions & Routine
    if (lower.contains('water') || lower.contains('पानी')) {
      return (
        translated: 'हे, दा: नू सेनेयामे!',
        phonetic: 'He, daah nu seneyame!',
      );
    }

    if (lower.contains('washroom') || lower.contains('toilet') || lower.contains('बाहर') || lower.contains('शौचालय')) {
      return (
        translated: 'हे, बाहर सेनेयामे!',
        phonetic: 'He, bahar seneyame!',
      );
    }

    if (lower.contains('food') || lower.contains('lunch') || lower.contains('खाना') || lower.contains('भोजन')) {
      return (
        translated: 'मंडी जोमेपे!',
        phonetic: 'Mandi jomepe!',
      );
    }

    if (lower.contains('wash hands') || lower.contains('हाथ धो')) {
      return (
        translated: 'ति अबुङेपे!',
        phonetic: 'Ti abungepe!',
      );
    }

    if (lower.contains('play') || lower.contains('खेल')) {
      return (
        translated: 'इनेङेपे!',
        phonetic: 'Inengepe!',
      );
    }

    // 7. Questions & Evaluation
    if (lower.contains('understand') || lower.contains('समझ आया') || lower.contains('समझे')) {
      return (
        translated: 'आपे बुझियानापे?',
        phonetic: 'Ape bujhiyanape?',
      );
    }

    if (lower.contains('who knows') || lower.contains('उत्तर कौन')) {
      return (
        translated: 'नेना कुली रेयाग उत्तर ओकोए बानाया?',
        phonetic: 'Nena kuli reyag uttar okoe banaya?',
      );
    }

    if (lower.contains('what are you doing') || lower.contains('क्या कर रहे')) {
      return (
        translated: 'आम चिकना चिकेतानाम?',
        phonetic: 'Aam chikana chiketanam?',
      );
    }

    if (lower.contains('why late') || lower.contains('देर क्यों') || lower.contains('देरी')) {
      return (
        translated: 'चिना: रेयाग लेबायानाम?',
        phonetic: 'Chinah reyag lebayanam?',
      );
    }

    if (lower.contains('crying') || lower.contains('रो रहे')) {
      return (
        translated: 'चिना: रेयाग राःतानाम?',
        phonetic: 'Chinah reyag raahtanam?',
      );
    }

    if (lower.contains('what happened') || lower.contains('क्या हुआ')) {
      return (
        translated: 'चिकना होबायाना?',
        phonetic: 'Chikana hobayana?',
      );
    }

    // 8. Health & Care
    if (lower.contains('headache') || lower.contains('सिर दर्द') || lower.contains('सिर')) {
      return (
        translated: 'आमा: बोः हासुताना? आराम केमे।',
        phonetic: 'Aamah boh hasutana? Aaraam keme.',
      );
    }

    if (lower.contains('stomach') || lower.contains('पेट')) {
      return (
        translated: 'आमा: लाज हासुताना? आराम केमे।',
        phonetic: 'Aamah laj hasutana? Aaraam keme.',
      );
    }

    if (lower.contains('fever') || lower.contains('बुखार')) {
      return (
        translated: 'रुवा अटाकारांग? आराम केमे।',
        phonetic: 'Ruwa atakaraang? Aaraam keme.',
      );
    }

    // 9. Praise
    if (lower.contains('very good') || lower.contains('well done') || lower.contains('शाबाश') || lower.contains('बहुत अच्छा')) {
      return (
        translated: 'एशू बुगिन! आपे सोबेनको बुगिन कामियानापे।',
        phonetic: 'Eshu bugin! Ape sobenko bugin kamiyanape.',
      );
    }

    if (lower.contains('thank') || lower.contains('धन्यवाद') || lower.contains('शुक्रिया')) {
      return (
        translated: 'सराहाव!',
        phonetic: 'Sarahaw!',
      );
    }

    // 10. Numbers / Counting
    if (lower.contains('गिनती') || lower.contains('count') || lower.contains('number')) {
      return (
        translated: 'मियद, बारिया, आपेया, उपुन, मोणोया, तुरूया, एया, इरिया, आरेया, गेले।',
        phonetic: 'Miyad, bariya, apeya, upun, monoya, turuya, eya, iriya, areya, gele.',
      );
    }

    // 11. Lexicon-based dynamic synthesis for multi-word or arbitrary sentences
    final hoLexicon = {
      'school': 'इस्कुल', 'विद्यालय': 'इस्कुल',
      'teacher': 'मास्टर जी', 'शिक्षक': 'मास्टर जी', 'गुरुजी': 'मास्टर जी',
      'student': 'होन', 'छात्र': 'होन', 'विद्यार्थी': 'होन', 'बच्चे': 'होनको', 'children': 'होनको',
      'book': 'पुथी', 'किताब': 'पुथी', 'पुस्तक': 'पुथी',
      'notebook': 'खाता', 'कॉपी': 'खाता',
      'pen': 'कलम', 'कलम': 'कलम', 'पेंसिल': 'कलम',
      'water': 'दा:', 'पानी': 'दा:',
      'food': 'मंडी', 'खाना': 'मंडी', 'भोजन': 'मंडी',
      'home': 'ओवा:', 'घर': 'ओवा:',
      'tree': 'दारू', 'पेड़': 'दारू',
      'village': 'हातूँ', 'गाँव': 'हातूँ',
      'today': 'तिशिंग', 'आज': 'तिशिंग',
      'tomorrow': 'गापा', 'कल': 'गापा',
      'yes': 'हे', 'हाँ': 'हे',
      'no': 'का', 'नहीं': 'का',
      'good': 'बुगिन', 'अच्छा': 'बुगिन', 'ठीक': 'बेस',
      'big': 'मरांग', 'बड़ा': 'मरांग',
      'small': 'हुडिंग', 'छोटा': 'हुडिंग',
      'read': 'पाड़ावपे', 'पढ़ो': 'पाड़ावपे', 'पढ़िए': 'पाड़ावपे',
      'write': 'ओलेपे', 'लिखो': 'ओलेपे', 'लिखिए': 'ओलेपे',
      'come': 'हिजुःमे', 'आओ': 'हिजुःमे', 'आइए': 'हिजुःमे',
      'go': 'सेनेयामे', 'जाओ': 'सेनेयामे', 'जाइए': 'सेनेयामे',
      'sit': 'दुबुपे', 'बैठो': 'दुबुपे', 'बैठिए': 'दुबुपे',
      'stand': 'तिंगुपे', 'उठो': 'तिंगुपे',
      'listen': 'आयुमपे', 'सुनो': 'आयुमपे',
      'see': 'नेलेपे', 'देखो': 'नेलेपे',
      'eat': 'जोमेपे', 'खाओ': 'जोमेपे',
      'drink': 'नूएमे', 'पियो': 'नूएमे',
      'understand': 'बुझियामे', 'समझो': 'बुझियामे',
      'you': 'आम', 'तुम': 'आम', 'आप': 'आम',
      'i': 'आईंग', 'मैं': 'आईंग',
      'we': 'अबू', 'हम': 'अबू',
      'my': 'आईंगआ:', 'मेरा': 'आईंगआ:', 'मेरी': 'आईंगआ:',
      'your': 'आमा:', 'तुम्हारा': 'आमा:', 'आपकी': 'आमा:', 'आपका': 'आमा:',
      'our': 'अबूआ:', 'हमारा': 'अबूआ:',
      'what': 'चिकना', 'क्या': 'चिकना',
      'where': 'ओकोरे', 'कहाँ': 'ओकोरे',
      'who': 'ओकोए', 'कौन': 'ओकोए',
      'how': 'चिलके', 'कैसे': 'चिलके',
      'why': 'चिना: रेयाग', 'क्यों': 'चिना: रेयाग',
      'very': 'एशू', 'बहुत': 'एशू',
    };

    final tokens = lower.split(RegExp(r'\s+'));
    final matchedHo = <String>[];
    for (final tok in tokens) {
      final cleanTok = tok.replaceAll(RegExp(r'[^\w\u0900-\u097F]'), '');
      if (hoLexicon.containsKey(cleanTok)) {
        matchedHo.add(hoLexicon[cleanTok]!);
      }
    }

    if (matchedHo.isNotEmpty) {
      final hoSentence = matchedHo.join(' ') + '।';
      return (
        translated: hoSentence,
        phonetic: hoToPhonetic(hoSentence),
      );
    }

    // Graceful respectful fallback (never broken raw text!)
    return (
      translated: 'होनको, सुकुर ते आयुमपे: $rawInput',
      phonetic: 'Honko, sukur te aayumpe: ${hoToPhonetic(rawInput)}',
    );
  }

  void clearHistory() {
    _history.clear();
  }
}

/// Translates Santali Ol Chiki Unicode (U+1C50 - U+1C7F) into readable Romanized phonetics
/// so web speech synthesis engines (which lack native Ol Chiki support) can speak it audibly.
String olChikiToPhonetic(String input) {
  const map = {
    // Digits
    '\u1C50': '0',
    '\u1C51': '1',
    '\u1C52': '2',
    '\u1C53': '3',
    '\u1C54': '4',
    '\u1C55': '5',
    '\u1C56': '6',
    '\u1C57': '7',
    '\u1C58': '8',
    '\u1C59': '9',
    // Letters
    '\u1C5A': 'o',
    '\u1C5B': 't',
    '\u1C5C': 'g',
    '\u1C5D': 'ng',
    '\u1C5E': 'l',
    '\u1C5F': 'a',
    '\u1C60': 'k',
    '\u1C61': 'j',
    '\u1C62': 'm',
    '\u1C63': 'w',
    '\u1C64': 'i',
    '\u1C65': 's',
    '\u1C66': 'h',
    '\u1C67': 'ny',
    '\u1C68': 'r',
    '\u1C69': 'u',
    '\u1C6A': 'ch',
    '\u1C6B': 'd',
    '\u1C6C': 'n',
    '\u1C6D': 'y',
    '\u1C6E': 'e',
    '\u1C6F': 'p',
    '\u1C70': 'd',
    '\u1C71': 'n',
    '\u1C72': 'r',
    '\u1C73': 'o',
    '\u1C74': 't',
    '\u1C75': 'b',
    '\u1C76': 'w',
    '\u1C77': 'h',
    // Modifiers & Punctuation
    '\u1C78': 'n',
    '\u1C79': '',
    '\u1C7A': '',
    '\u1C7B': '',
    '\u1C7C': '',
    '\u1C7D': 'h',
    '\u1C7E': '.',
    '\u1C7F': '.',
  };

  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    final mapped = map[char];
    if (mapped != null) {
      buffer.write(mapped);
    } else {
      buffer.write(char);
    }
  }

  final raw = buffer.toString().trim();
  if (raw.isEmpty) return raw;

  return raw.replaceAllMapped(
    RegExp(r'(?:^|[.!?]\s+)([a-z])'),
    (m) => m.group(0)!.toUpperCase(),
  );
}

/// Translates Devanagari script into readable Romanized phonetics for devices lacking Hindi voice.
String devanagariToPhonetic(String input) {
  const vowels = {
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo',
    'ऋ': 'ri', 'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'अं': 'an', 'अः': 'ah',
  };
  const matras = {
    'ा': 'a', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo', 'ृ': 'ri',
    'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', 'ं': 'n', 'ः': 'h', 'ँ': 'n',
    '्': '',
  };
  const consonants = {
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
    'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
    'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
    'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'w',
    'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
    'ड़': 'd', 'ढ़': 'dh', 'फ़': 'f', 'ज़': 'z',
  };

  final buffer = StringBuffer();
  final chars = input.runes.map((r) => String.fromCharCode(r)).toList();

  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    if (vowels.containsKey(c)) {
      buffer.write(vowels[c]);
    } else if (consonants.containsKey(c)) {
      final base = consonants[c]!;
      buffer.write(base);
      if (i + 1 < chars.length) {
        final next = chars[i + 1];
        if (matras.containsKey(next)) {
          buffer.write(matras[next]);
          i++;
        } else if (consonants.containsKey(next) || vowels.containsKey(next)) {
          if (chars[i] != '्') {
            buffer.write('a');
          }
        }
      }
    } else if (matras.containsKey(c)) {
      buffer.write(matras[c]);
    } else {
      buffer.write(c == ':' ? 'h' : c);
    }
  }

  final raw = buffer.toString().trim();
  if (raw.isEmpty) return raw;
  return raw.replaceAllMapped(
    RegExp(r'(?:^|[.!?]\s+)([a-z])'),
    (m) => m.group(0)!.toUpperCase(),
  );
}

/// Produces natural Romanized phonetics for Ho phrases so Indian English TTS voices can speak them fluently.
String hoToPhonetic(String text) {
  var t = text
      .replaceAll('आमा:', 'Aamah')
      .replaceAll('आईंगआ:', 'Aing-ah')
      .replaceAll('आईंग', 'Aing')
      .replaceAll('दा:', 'Daah')
      .replaceAll('हिजुः', 'Hijuh')
      .replaceAll('ओवा:', 'Owaah')
      .replaceAll('पुथी', 'Puthi')
      .replaceAll('खाता', 'Khata')
      .replaceAll('खाथा', 'Khata')
      .replaceAll('ओलेपे', 'Olepe')
      .replaceAll('ओलेमे', 'Oleme')
      .replaceAll('पाड़ावपे', 'Padawpe')
      .replaceAll('पाड़ावमे', 'Padawme')
      .replaceAll('पाड़ाव', 'Padaw')
      .replaceAll('दुबुपे', 'Dubupe')
      .replaceAll('दुबुमे', 'Dubume')
      .replaceAll('तिंगुपे', 'Tingupe')
      .replaceAll('तिंगुमे', 'Tingume')
      .replaceAll('थिरुपे', 'Thirupe')
      .replaceAll('आयुमपे', 'Aayumpe')
      .replaceAll('आयुममे', 'Aayumme')
      .replaceAll('सुकुर', 'Sukur')
      .replaceAll('बुझियानापे', 'Bujhiyanape')
      .replaceAll('बुझियाना', 'Bujhiyana')
      .replaceAll('बुझियामे', 'Bujhiyame')
      .replaceAll('चिकना', 'Chikana')
      .replaceAll('उमुर', 'Umur')
      .replaceAll('चिमिन', 'Chimin')
      .replaceAll('बानोःआ', 'Banoh-a')
      .replaceAll('बानोः', 'Banoh')
      .replaceAll('जोहार', 'Johar')
      .replaceAll('सराहाव', 'Sarahaw')
      .replaceAll('एशू', 'Eshu')
      .replaceAll('बुगिन', 'Bugin')
      .replaceAll('तानांग', 'Tanang')
      .replaceAll('सेनेयातानाम', 'Seneyatanam')
      .replaceAll('सेनेयामे', 'Seneyame')
      .replaceAll('सेनेयापे', 'Seneyape')
      .replaceAll('सेनेया', 'Seneya')
      .replaceAll('नेते', 'Nete')
      .replaceAll('हन्ते', 'Hante')
      .replaceAll('नेना', 'Nena')
      .replaceAll('अबू', 'Abu')
      .replaceAll('होनको', 'Honko')
      .replaceAll('सोबेन', 'Soben')
      .replaceAll('मियद', 'Miyad')
      .replaceAll('बारिया', 'Bariya')
      .replaceAll('आपेया', 'Apeya')
      .replaceAll('उपुन', 'Upun')
      .replaceAll('मोणोया', 'Monoya')
      .replaceAll('तुरूया', 'Turuya')
      .replaceAll('एया', 'Eya')
      .replaceAll('इरिया', 'Iriya')
      .replaceAll('आरेया', 'Areya')
      .replaceAll('गेले', 'Gele');

  if (RegExp(r'[\u0900-\u097F]').hasMatch(t)) {
    t = devanagariToPhonetic(t);
  }

  return t
      .replaceAll(':', 'h')
      .replaceAll('ः', 'h')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

