import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';

class ClassroomSetupScreen extends StatefulWidget {
  final int initialStep;
  const ClassroomSetupScreen({super.key, this.initialStep = 1});

  @override
  State<ClassroomSetupScreen> createState() => _ClassroomSetupScreenState();
}

class _ClassroomSetupScreenState extends State<ClassroomSetupScreen> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  // Step 1 State: Class & Student Count (No default selections)
  int? _selectedGrade;
  int _studentCount = 0;

  // Step 2 State: Languages (No default selections)
  String? _teacherLanguage;
  String? _studentLanguage;

  final List<String> _teacherLanguages = [
    'Hindi (हिंदी)',
    'English',
    'Odia (ଓଡ଼ିଆ)',
    'Bengali (বাংলা)',
  ];

  final List<Map<String, String>> _tribalLanguages = [
    {'name': 'Ho (हो)', 'script': 'Warang Citi / Devanagari'},
    {'name': 'Mundari (मुंडारी)', 'script': 'Mundari Bani / Devanagari'},
    {'name': 'Santhali (संथाली)', 'script': 'Ol Chiki / Devanagari'},
    {'name': 'Kui (कुई)', 'script': 'Odia / Devanagari'},
    {'name': 'Gondi (गोंडी)', 'script': 'Gunjala Gondi / Devanagari'},
    {'name': 'Kurukh (कुरुख)', 'script': 'Tolang Siki / Devanagari'},
  ];

  // Step 3 State: Lesson Selection (No default selections)
  String? _selectedCategory;
  String? _selectedLesson;

  final List<String> _categories = ['Numeracy', 'Literacy', 'Activities'];

  final Map<String, List<Map<String, dynamic>>> _lessonsByCategory = {
    'Numeracy': [
      {
        'title': 'Numbers 1 to 10',
        'icon': Icons.menu_book_rounded,
        'iconColor': Color(0xFF6366F1),
        'iconBg': Color(0xFFEEF2FF),
      },
      {
        'title': 'Alphabet and Sounds',
        'icon': Icons.shield_rounded,
        'iconColor': Color(0xFFEC4899),
        'iconBg': Color(0xFFFDF2F8),
      },
      {
        'title': 'Counting Objects',
        'icon': Icons.radio_button_checked_rounded,
        'iconColor': Color(0xFFF97316),
        'iconBg': Color(0xFFFFF7ED),
      },
      {
        'title': 'Simple Words',
        'icon': Icons.grid_view_rounded,
        'iconColor': Color(0xFF8B5CF6),
        'iconBg': Color(0xFFF5F3FF),
      },
      {
        'title': 'Shapes and Colours',
        'icon': Icons.change_history_rounded,
        'iconColor': Color(0xFF10B981),
        'iconBg': Color(0xFFECFDF5),
      },
    ],
    'Literacy': [
      {
        'title': 'Letters & Phonics (वर्ण और ध्वनियाँ)',
        'icon': Icons.spellcheck_rounded,
        'iconColor': Color(0xFF6366F1),
        'iconBg': Color(0xFFEEF2FF),
      },
      {
        'title': 'Rhymes & Folk Songs (गीत और कविता)',
        'icon': Icons.music_note_rounded,
        'iconColor': Color(0xFFEC4899),
        'iconBg': Color(0xFFFDF2F8),
      },
      {
        'title': 'Daily Classroom Objects (कक्षा की वस्तुएं)',
        'icon': Icons.category_rounded,
        'iconColor': Color(0xFFF97316),
        'iconBg': Color(0xFFFFF7ED),
      },
      {
        'title': 'Family & Animals (परिवार और पशु)',
        'icon': Icons.pets_rounded,
        'iconColor': Color(0xFF10B981),
        'iconBg': Color(0xFFECFDF5),
      },
    ],
    'Activities': [
      {
        'title': 'Picture Storytelling (चित्र कथा)',
        'icon': Icons.auto_stories_rounded,
        'iconColor': Color(0xFF8B5CF6),
        'iconBg': Color(0xFFF5F3FF),
      },
      {
        'title': 'Interactive Roleplay (संवाद और अभिनय)',
        'icon': Icons.record_voice_over_rounded,
        'iconColor': Color(0xFFEC4899),
        'iconBg': Color(0xFFFDF2F8),
      },
      {
        'title': 'Math Games with Pebbles (गिट्टी और खेल)',
        'icon': Icons.casino_rounded,
        'iconColor': Color(0xFFF97316),
        'iconBg': Color(0xFFFFF7ED),
      },
    ],
  };

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedGrade == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please select a grade to continue',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      if (_studentCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please specify the number of students (at least 1)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_teacherLanguage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please select the teacher language',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      if (_studentLanguage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please select the student vernacular language',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please select a subject category',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      if (_selectedLesson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Please choose a lesson to begin with',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
        return;
      }
      _startClassSession();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _startClassSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Classroom Configured',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF261080),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starting Grade ${_selectedGrade ?? 1} session:',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildDialogRow('Students:', '$_studentCount'),
            _buildDialogRow('Teacher Language:', _teacherLanguage ?? 'Not Selected'),
            _buildDialogRow('Student Language:', _studentLanguage ?? 'Not Selected'),
            _buildDialogRow('Category:', _selectedCategory ?? 'Not Selected'),
            _buildDialogRow('Lesson:', _selectedLesson ?? 'Not Selected'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Modify Setup',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6F62AB),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppState.instance.updateClassroomSetup(
                grade: _selectedGrade,
                count: _studentCount,
                tLang: _teacherLanguage,
                sLang: _studentLanguage,
                lesson: _selectedLesson,
              );
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C27D8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Launch Assistant',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6F62AB), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF261080),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF5C27D8);
    const bgColor = Color(0xFFF8F6FD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          onPressed: _previousStep,
        ),
        title: Text(
          'Set Up Your Classroom',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 800;
            final isTablet = screenWidth >= 600 && screenWidth < 800;

            final double cardWidth = isDesktop ? 680 : (isTablet ? 560 : double.infinity);
            final EdgeInsets pagePadding = EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0),
              vertical: isDesktop ? 24.0 : 16.0,
            );

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Top 3-Step Progress Indicator
                            _buildProgressStepper(),
                            const SizedBox(height: 20),

                            // 2. Active Step Content
                            if (_currentStep == 1)
                              _buildStep1ClassSelection()
                            else if (_currentStep == 2)
                              _buildStep2LanguageSelection()
                            else
                              _buildStep3LessonSelection(),
                          ],
                        ),
                      ),
                    ),

                    // 3. Bottom Sticky Action Navigation Bar
                    _buildBottomNavigation(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // PROGRESS STEPPER WIDGET
  // ==========================================
  Widget _buildProgressStepper() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, isActive: _currentStep == 1, isCompleted: _currentStep > 1),
            _buildStepConnector(isCompleted: _currentStep > 1),
            _buildStepCircle(2, isActive: _currentStep == 2, isCompleted: _currentStep > 2),
            _buildStepConnector(isCompleted: _currentStep > 2),
            _buildStepCircle(3, isActive: _currentStep == 3, isCompleted: false),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, {required bool isActive, required bool isCompleted}) {
    const activeColor = Color(0xFF5C27D8);
    final isDone = isCompleted || isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : (isCompleted ? const Color(0xFFECE8FB) : const Color(0xFFF1EEFA)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? activeColor : const Color(0xFFD4CDE8),
          width: isActive ? 0 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: activeColor, size: 18)
            : Text(
                '$step',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : const Color(0xFF6F62AB),
                ),
              ),
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isCompleted ? const Color(0xFF5C27D8) : const Color(0xFFD4CDE8),
      ),
    );
  }

  // ==========================================
  // SCREEN 2: CLASSROOM SETUP (1/3)
  // ==========================================
  Widget _buildStep1ClassSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Class',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF261080),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the class you teach and number of students.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6F62AB),
          ),
        ),
        const SizedBox(height: 20),

        // Class section label
        Text(
          'Class',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF33206A),
          ),
        ),
        const SizedBox(height: 10),

        // Radio List for Grades 1 - 5
        ...List.generate(5, (index) {
          final grade = index + 1;
          final isSelected = _selectedGrade == grade;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedGrade = grade),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFECE8FB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFE5E0F5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5C27D8).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    _buildRadioIcon(isSelected),
                    const SizedBox(width: 14),
                    Text(
                      'Grade $grade',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF261080) : const Color(0xFF422A76),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 18),

        // Number of Students Section
        Text(
          'Number of Students',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF33206A),
          ),
        ),
        const SizedBox(height: 10),

        // Stepper Counter: [ - ] 32 [ + ]
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E0F5), width: 1.2),
          ),
          child: Row(
            children: [
              // Decrement Button
              InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                onTap: _studentCount > 0 ? () => setState(() => _studentCount--) : null,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F6FD),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(13)),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: _studentCount > 0 ? const Color(0xFF5C27D8) : const Color(0xFFC4B8E2),
                    size: 24,
                  ),
                ),
              ),

              // Student Count Display
              Expanded(
                child: Center(
                  child: Text(
                    '$_studentCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _studentCount > 0 ? const Color(0xFF261080) : const Color(0xFF8B81B8),
                    ),
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(13)),
                onTap: () => setState(() => _studentCount++),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F6FD),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(13)),
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF5C27D8), size: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // SCREEN 3: CLASSROOM SETUP (2/3)
  // ==========================================
  Widget _buildStep2LanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Student Language',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF261080),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the mother tongue of your students.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6F62AB),
          ),
        ),
        const SizedBox(height: 20),

        // 1. Teacher Language Section
        Text(
          'Teacher Language',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF33206A),
          ),
        ),
        const SizedBox(height: 10),

        // Dropdown Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E0F5), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _teacherLanguage,
              hint: Text(
                'Select Teacher Language',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B81B8),
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5C27D8), size: 24),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF261080),
              ),
              onChanged: (String? val) {
                if (val != null) setState(() => _teacherLanguage = val);
              },
              items: _teacherLanguages.map((String lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // 2. Student Language Section
        Text(
          'Student Language',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF33206A),
          ),
        ),
        const SizedBox(height: 10),

        // Tribal vernacular languages radio list
        ..._tribalLanguages.map((langItem) {
          final langName = langItem['name']!;
          final isSelected = _studentLanguage == langName;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _studentLanguage = langName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFECE8FB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFE5E0F5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5C27D8).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    _buildRadioIcon(isSelected),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        langName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF261080) : const Color(0xFF422A76),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // SCREEN 4: CLASSROOM SETUP (3/3)
  // ==========================================
  Widget _buildStep3LessonSelection() {
    final activeLessons = _lessonsByCategory[_selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Today's Lesson",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF261080),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a lesson to begin with.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6F62AB),
          ),
        ),
        const SizedBox(height: 18),

        // Category Filter Chips: [Numeracy] [Literacy] [Activities]
        Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedLesson = null; // Don't preselect any lesson; teacher chooses explicitly
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFECE8FB) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFE5E0F5),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFF6F62AB),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        if (_selectedCategory == null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E0F5), width: 1.2),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECE8FB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app_outlined, size: 26, color: Color(0xFF5C27D8)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select a subject above to view lessons',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6F62AB),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose Numeracy, Literacy, or Activities to explore curriculum modules.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF8B81B8),
                  ),
                ),
              ],
            ),
          )
        else
          // Lesson Cards List
          ...activeLessons.map((lesson) {
          final title = lesson['title'] as String;
          final iconData = lesson['icon'] as IconData;
          final iconColor = lesson['iconColor'] as Color;
          final iconBg = lesson['iconBg'] as Color;
          final isSelected = _selectedLesson == title;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedLesson = title),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFECE8FB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFE5E0F5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5C27D8).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Thematic Category Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),

                    // Lesson Title
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF261080) : const Color(0xFF422A76),
                        ),
                      ),
                    ),

                    // Trailing Selection Indicator
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5C27D8),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.circle, color: Colors.white, size: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigation() {
    final bool isFirstStep = _currentStep == 1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: isFirstStep
          ? SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C27D8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD4CDE8), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5C27D8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C27D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Start Class' : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRadioIcon(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF5C27D8) : const Color(0xFFC4B8E2),
          width: isSelected ? 2 : 1.8,
        ),
      ),
      child: Center(
        child: isSelected
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF5C27D8),
                ),
              )
            : null,
      ),
    );
  }
}
