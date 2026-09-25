import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';

class WorksheetsScreen extends StatefulWidget {
  const WorksheetsScreen({Key? key}) : super(key: key);

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  String _selectedGrade = 'Grade 2';
  String _selectedSubject = 'Numeracy';
  String _selectedLesson = 'Numbers 1–10';
  String _selectedLanguage = 'Hindi + Mundari';
  String _selectedType = 'Counting';
  
  bool _worksheetGenerated = false;
  bool _isGenerating = false;

  final Map<String, List<String>> _lessonsBySubject = {
    'Numeracy': [
      'Numbers 1–10',
      'Numbers 11–20',
      'Addition Basics',
      'Shapes & Colors',
      'Counting Objects'
    ],
    'Literacy': [
      'Alphabet & Sounds',
      'Simple Words',
      'My Family',
      'Body Parts'
    ],
    'EVS': ['My School', 'Plants Around Us', 'Water and Food'],
    'Activities': ['Drawing Numbers', 'Match the Objects', 'Sorting Activity'],
  };

  final List<String> _grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'];
  final List<String> _subjects = ['Numeracy', 'Literacy', 'EVS', 'Activities'];
  final List<String> _languages = [
    'Hindi + Mundari',
    'Hindi + Santali',
    'Hindi + Ho',
    'Hindi + Kurukh',
    'Hindi + Gondi',
    'Hindi Only'
  ];
  final List<String> _worksheetTypes = [
    'Counting',
    'Fill Blanks',
    'Match Items',
    'Draw & Write'
  ];

  final List<Map<String, String>> _savedWorksheets = [
    {
      'title': 'Numbers 1–10 • Grade 2',
      'subtitle': 'Numeracy • Hindi + Mundari',
      'date': 'Sep 23',
      'type': 'Counting'
    },
    {
      'title': 'Alphabet Sounds • Grade 1',
      'subtitle': 'Literacy • Hindi + Santali',
      'date': 'Sep 22',
      'type': 'Fill Blanks'
    },
    {
      'title': 'My Family • Grade 1',
      'subtitle': 'Literacy • Hindi + Ho',
      'date': 'Sep 20',
      'type': 'Draw & Write'
    },
    {
      'title': 'Shapes & Colors • Grade 2',
      'subtitle': 'Numeracy • Hindi + Kurukh',
      'date': 'Sep 18',
      'type': 'Match Items'
    },
    {
      'title': 'Plants Around Us • Grade 3',
      'subtitle': 'EVS • Hindi + Gondi',
      'date': 'Sep 15',
      'type': 'Fill Blanks'
    },
  ];

  final List<Map<String, dynamic>> _templates = [
    {
      'name': 'Number Tracing 1–10',
      'category': 'Numeracy',
      'grade': 'Grade 1',
      'icon': Icons.format_list_numbered_rounded,
      'color': const Color(0xFF3B82F6)
    },
    {
      'name': 'Alphabet Match',
      'category': 'Literacy',
      'grade': 'Grade 1',
      'icon': Icons.text_fields_rounded,
      'color': const Color(0xFF8B5CF6)
    },
    {
      'name': 'Count & Color',
      'category': 'Numeracy',
      'grade': 'Grade 2',
      'icon': Icons.palette_rounded,
      'color': const Color(0xFF10B981)
    },
    {
      'name': 'My School Objects',
      'category': 'EVS',
      'grade': 'Grade 2',
      'icon': Icons.school_rounded,
      'color': const Color(0xFFF59E0B)
    },
    {
      'name': 'Word Family',
      'category': 'Literacy',
      'grade': 'Grade 2',
      'icon': Icons.book_rounded,
      'color': const Color(0xFFEF4444)
    },
    {
      'name': 'Odd & Even Numbers',
      'category': 'Numeracy',
      'grade': 'Grade 3',
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFF06B6D4)
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    try {
      final gradeStr = 'Grade ${AppState.instance.selectedGrade}';
      if (_grades.contains(gradeStr)) {
        _selectedGrade = gradeStr;
      }
      if (AppState.instance.studentLanguage.isNotEmpty) {
        String lang = 'Hindi + ${AppState.instance.studentLanguage}';
        if (_languages.contains(lang)) {
          _selectedLanguage = lang;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleGenerate() {
    setState(() {
      _isGenerating = true;
      _worksheetGenerated = false;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _worksheetGenerated = true;
        });
      }
    });
  }

  void _handleSaveWorksheet() {
    setState(() {
      _savedWorksheets.insert(0, {
        'title': '$_selectedLesson • $_selectedGrade',
        'subtitle': '$_selectedSubject • $_selectedLanguage',
        'date': 'Just now',
        'type': _selectedType,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Worksheet saved to your library!',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: const Color(0xFF28127D),
      ),
    );
  }

  void _handleSharePrint() {
    if (kIsWeb) {
      try {
        html.window.print();
      } catch (_) {}
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Worksheet formatted for print and classroom distribution.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF5C27D8),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Counting':
        return const Color(0xFF3B82F6);
      case 'Fill Blanks':
        return const Color(0xFF8B5CF6);
      case 'Match Items':
        return const Color(0xFF10B981);
      case 'Draw & Write':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF5C27D8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FD),
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: const Color(0xFF5C27D8),
                title: Text(
                  'Worksheets',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Generate'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Templates'),
                  ],
                ),
              ),
        body: Row(
          children: [
            if (isDesktop)
              const VernexaDesktopSidebar(currentIndex: 4),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop)
                    Container(
                      color: const Color(0xFF5C27D8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                            },
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Worksheets',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 300,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white70,
                              indicatorColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: const [
                                Tab(text: 'Generate'),
                                Tab(text: 'Saved'),
                                Tab(text: 'Templates'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGenerateTab(),
                        _buildSavedTab(),
                        _buildTemplatesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            isDesktop ? null : const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigurationForm(),
          const SizedBox(height: 24),
          if (_isGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF5C27D8),
                ),
              ),
            )
          else if (_worksheetGenerated)
            _buildWorksheetPreview(),
        ],
      ),
    );
  }

  Widget _buildConfigurationForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2D9F8)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worksheet Setup',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF28127D),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Grade',
                    _grades,
                    _selectedGrade,
                    (v) => setState(() => _selectedGrade = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Subject',
                    _subjects,
                    _selectedSubject,
                    (v) {
                      setState(() {
                        _selectedSubject = v!;
                        _selectedLesson =
                            _lessonsBySubject[_selectedSubject]!.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Lesson',
              _lessonsBySubject[_selectedSubject]!,
              _selectedLesson,
              (v) => setState(() => _selectedLesson = v!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Language',
              _languages,
              _selectedLanguage,
              (v) => setState(() => _selectedLanguage = v!),
            ),
            const SizedBox(height: 16),
            Text(
              'Worksheet Type',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _worksheetTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        type,
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.white : const Color(0xFF28127D),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF5C27D8),
                      backgroundColor: const Color(0xFFF8F6FD),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                            _worksheetGenerated = false;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C27D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Generate Worksheet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2D9F8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5C27D8)),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF28127D),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetPreview() {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'VERNEXA Bilingual Worksheet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_selectedGrade - $_selectedSubject - $_selectedLesson',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Name: _________________',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Date: _________________',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildWorksheetContent(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleSaveWorksheet,
                icon: const Icon(Icons.save_rounded, color: Color(0xFF5C27D8)),
                label: Text(
                  'Save Worksheet',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C27D8),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF5C27D8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleSharePrint,
                icon: const Icon(Icons.print_rounded, color: Color(0xFF28127D)),
                label: Text(
                  'Share / Print',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF28127D),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF28127D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorksheetContent() {
    if (_selectedType == 'Counting') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBilingualInstruction(
            'Q1: Count and write the number.',
            'गिनिए और संख्या लिखिए।',
          ),
          const SizedBox(height: 16),
          _buildCountingRow(3, Colors.red),
          const SizedBox(height: 16),
          _buildCountingRow(5, Colors.blue),
          const SizedBox(height: 16),
          _buildCountingRow(7, Colors.green),
          const SizedBox(height: 24),
          _buildBilingualInstruction(
            'Q2: Fill in the missing numbers.',
            'रिक्त स्थान भरिए।',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildNumberBox('1'),
              _buildEmptyBox(),
              _buildNumberBox('3'),
              _buildEmptyBox(),
              _buildNumberBox('5'),
              _buildEmptyBox(),
              _buildNumberBox('7'),
              _buildEmptyBox(),
              _buildNumberBox('9'),
              _buildEmptyBox(),
            ],
          ),
          const SizedBox(height: 24),
          _buildBilingualInstruction(
            'Q3: Write the language names.',
            'भाषाओं के नाम लिखिए।',
          ),
        ],
      );
    } else if (_selectedType == 'Fill Blanks') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBilingualInstruction(
            'Q1: Write the missing letter.',
            'खाली जगह भरिए।',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFillBlankWord('AT'),
              _buildFillBlankWord('OG'),
              _buildFillBlankWord('UN'),
              _buildFillBlankWord('OX'),
            ],
          ),
          const SizedBox(height: 24),
          _buildBilingualInstruction(
            'Q2: Match the word to the picture.',
            'चित्र को शब्द से मिलाइए।',
          ),
          const SizedBox(height: 16),
          _buildMatchRow(Icons.pets, 'Dog'),
          _buildMatchRow(Icons.wb_sunny, 'Sun'),
          _buildMatchRow(Icons.directions_car, 'Car'),
          _buildMatchRow(Icons.home, 'House'),
        ],
      );
    } else if (_selectedType == 'Match Items') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBilingualInstruction(
            'Q1: Draw a line to match.',
            'रेखा खींचकर मिलाइए।',
          ),
          const SizedBox(height: 16),
          _buildMatchItemRow('School', Icons.school),
          _buildMatchItemRow('Tree', Icons.park),
          _buildMatchItemRow('Water', Icons.water_drop),
          const SizedBox(height: 24),
          _buildBilingualInstruction(
            'Q2: Circle the correct answer.',
            'सही उत्तर पर गोला लगाइए।',
          ),
          const SizedBox(height: 16),
          _buildMultipleChoiceRow(Icons.apple, ['Apple', 'Banana', 'Orange']),
          _buildMultipleChoiceRow(Icons.pets, ['Cat', 'Dog', 'Bird']),
        ],
      );
    } else {
      // Draw & Write
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBilingualInstruction(
            'Q1: Draw and write the name in both languages.',
            'चित्र बनाइए और दोनों भाषाओं में नाम लिखिए।',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDrawBox('1'),
              _buildDrawBox('2'),
              _buildDrawBox('3'),
            ],
          ),
          const SizedBox(height: 24),
          _buildBilingualInstruction(
            'Q2: Trace the numbers.',
            'संख्याओं को अनुरेखित (ट्रेस) करें।',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberBox('1', dotted: true),
              _buildNumberBox('2', dotted: true),
              _buildNumberBox('3', dotted: true),
              _buildNumberBox('4', dotted: true),
              _buildNumberBox('5', dotted: true),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBilingualInstruction(String english, String hindi) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            english,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hindi,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5C27D8),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCountingRow(int count, Color color) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              count,
              (index) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberBox(String number, {bool dotted = false}) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54,
          style: dotted ? BorderStyle.none : BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: dotted
          ? Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                color: Colors.black26,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildEmptyBox() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildFillBlankWord(String ending) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black87)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          ending,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchRow(IconData icon, String word) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, size: 40, color: Colors.black54),
          const Icon(Icons.arrow_right_alt, size: 32, color: Colors.black26),
          Text(
            word,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItemRow(String word, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              word,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.compare_arrows, size: 32, color: Colors.black26),
          SizedBox(
            width: 100,
            child: Icon(icon, size: 40, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceRow(IconData icon, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.black54),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: options.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawBox(String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                color: Colors.black12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black54)),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedWorksheets.length,
      itemBuilder: (context, index) {
        final worksheet = _savedWorksheets[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2D9F8)),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor(worksheet['type']!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_rounded,
                color: _getTypeColor(worksheet['type']!),
              ),
            ),
            title: Text(
              worksheet['title']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF28127D),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  worksheet['subtitle']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        worksheet['type']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(worksheet['type']!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      worksheet['date']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _savedWorksheets.removeAt(index);
                    });
                  },
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C27D8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2D9F8)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: template['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    template['icon'],
                    color: template['color'],
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(
                    template['name'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF28127D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        template['category'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF5C27D8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        template['grade'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF4A4A4A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8F6FD),
                      foregroundColor: const Color(0xFF5C27D8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Use Template',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
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
  }
}
