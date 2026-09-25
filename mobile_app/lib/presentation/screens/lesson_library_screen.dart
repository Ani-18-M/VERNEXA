import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class LessonLibraryScreen extends StatefulWidget {
  const LessonLibraryScreen({super.key});

  @override
  State<LessonLibraryScreen> createState() => _LessonLibraryScreenState();
}

class _LessonLibraryScreenState extends State<LessonLibraryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Numeracy',
    'Literacy',
    'Activities',
    'EVS'
  ];

  final List<Map<String, dynamic>> _allLessons = [
    {
      'title': 'Numbers 1-10',
      'gradeCategory': 'Grade 1',
      'category': 'Numeracy',
      'description': 'Introduction to basic counting and numbers from one to ten using local cultural references.',
      'badgeText': '1',
      'badgeIcon': Icons.numbers,
      'badgeBg': const Color(0xFFE8EAF6),
      'badgeColor': const Color(0xFF3F51B5),
      'isTextBadge': true,
      'durationMin': '30 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Numbers 11-20',
      'gradeCategory': 'Grade 1',
      'category': 'Numeracy',
      'description': 'Building on foundational counting, introducing the next set of numbers with visual aids.',
      'badgeText': '2',
      'badgeIcon': Icons.format_list_numbered,
      'badgeBg': const Color(0xFFE8EAF6),
      'badgeColor': const Color(0xFF3F51B5),
      'isTextBadge': true,
      'durationMin': '35 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.6,
    },
    {
      'title': 'Counting Objects',
      'gradeCategory': 'Grade 1',
      'category': 'Numeracy',
      'description': 'Hands-on practice counting everyday objects like leaves, pebbles, and local fruits.',
      'badgeText': 'C',
      'badgeIcon': Icons.calculate,
      'badgeBg': const Color(0xFFFFF8E1),
      'badgeColor': const Color(0xFFFFB300),
      'isTextBadge': false,
      'durationMin': '45 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'Addition Basics',
      'gradeCategory': 'Grade 2',
      'category': 'Numeracy',
      'description': 'Simple addition concepts explained through interactive storytelling and combining items.',
      'badgeText': '+',
      'badgeIcon': Icons.add,
      'badgeBg': const Color(0xFFE8F5E9),
      'badgeColor': const Color(0xFF4CAF50),
      'isTextBadge': true,
      'durationMin': '40 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'Shapes & Colors',
      'gradeCategory': 'Pre-K',
      'category': 'Numeracy',
      'description': 'Identifying basic geometric shapes and primary colors in the local tribal environment.',
      'badgeText': 'S',
      'badgeIcon': Icons.category,
      'badgeBg': const Color(0xFFFCE4EC),
      'badgeColor': const Color(0xFFE91E63),
      'isTextBadge': false,
      'durationMin': '25 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Measurement Basics',
      'gradeCategory': 'Grade 2',
      'category': 'Numeracy',
      'description': 'Understanding concepts of length and weight using non-standard units like handspans.',
      'badgeText': 'M',
      'badgeIcon': Icons.straighten,
      'badgeBg': const Color(0xFFE0F7FA),
      'badgeColor': const Color(0xFF00BCD4),
      'isTextBadge': false,
      'durationMin': '30 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'Alphabet & Sounds',
      'gradeCategory': 'Pre-K',
      'category': 'Literacy',
      'description': 'Phonics fundamentals teaching the sounds of local language alphabets alongside visual cues.',
      'badgeText': 'A',
      'badgeIcon': Icons.sort_by_alpha,
      'badgeBg': const Color(0xFFF3E5F5),
      'badgeColor': const Color(0xFF9C27B0),
      'isTextBadge': true,
      'durationMin': '40 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Simple Words',
      'gradeCategory': 'Grade 1',
      'category': 'Literacy',
      'description': 'Combining sounds to form basic vocabulary words commonly used in the local community.',
      'badgeText': 'W',
      'badgeIcon': Icons.abc,
      'badgeBg': const Color(0xFFFFF3E0),
      'badgeColor': const Color(0xFFFF9800),
      'isTextBadge': false,
      'durationMin': '35 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.8,
    },
    {
      'title': 'Story Time',
      'gradeCategory': 'Grade 1',
      'category': 'Literacy',
      'description': 'Engaging traditional folklore narrated in the native language to boost listening comprehension.',
      'badgeText': 'S',
      'badgeIcon': Icons.auto_stories,
      'badgeBg': const Color(0xFFEFEBE9),
      'badgeColor': const Color(0xFF795548),
      'isTextBadge': false,
      'durationMin': '20 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'My Family',
      'gradeCategory': 'Pre-K',
      'category': 'Literacy',
      'description': 'Learning vocabulary related to family members and kinship terms in the local language.',
      'badgeText': 'F',
      'badgeIcon': Icons.family_restroom,
      'badgeBg': const Color(0xFFFFEBEE),
      'badgeColor': const Color(0xFFF44336),
      'isTextBadge': false,
      'durationMin': '25 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Body Parts',
      'gradeCategory': 'Pre-K',
      'category': 'Literacy',
      'description': 'Interactive lesson identifying and naming different parts of the human body.',
      'badgeText': 'B',
      'badgeIcon': Icons.accessibility_new,
      'badgeBg': const Color(0xFFE8F5E9),
      'badgeColor': const Color(0xFF4CAF50),
      'isTextBadge': false,
      'durationMin': '30 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 0.5,
    },
    {
      'title': 'Animals & Nature',
      'gradeCategory': 'Grade 1',
      'category': 'Literacy',
      'description': 'Vocabulary building focused on local wildlife, domestic animals, and natural elements.',
      'badgeText': 'N',
      'badgeIcon': Icons.pets,
      'badgeBg': const Color(0xFFE0F2F1),
      'badgeColor': const Color(0xFF009688),
      'isTextBadge': false,
      'durationMin': '45 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'Outdoor Counting Game',
      'gradeCategory': 'Grade 1',
      'category': 'Activities',
      'description': 'An interactive physical activity where students find and count grouped objects outdoors.',
      'badgeText': 'O',
      'badgeIcon': Icons.nature_people,
      'badgeBg': const Color(0xFFF1F8E9),
      'badgeColor': const Color(0xFF8BC34A),
      'isTextBadge': false,
      'durationMin': '60 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'Singing Numbers',
      'gradeCategory': 'Pre-K',
      'category': 'Activities',
      'description': 'A musical lesson utilizing traditional melodies to help children memorize number sequences.',
      'badgeText': 'M',
      'badgeIcon': Icons.music_note,
      'badgeBg': const Color(0xFFFFFDE7),
      'badgeColor': const Color(0xFFFBC02D),
      'isTextBadge': false,
      'durationMin': '25 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Clay Counting',
      'gradeCategory': 'Grade 1',
      'category': 'Activities',
      'description': 'Artistic activity using local clay to model numbers and create countable groupings.',
      'badgeText': 'C',
      'badgeIcon': Icons.brush,
      'badgeBg': const Color(0xFFFBE9E7),
      'badgeColor': const Color(0xFFFF5722),
      'isTextBadge': false,
      'durationMin': '50 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.0,
    },
    {
      'title': 'My School',
      'gradeCategory': 'Grade 1',
      'category': 'EVS',
      'description': 'Exploring the school environment, understanding roles of teachers, and school hygiene.',
      'badgeText': 'S',
      'badgeIcon': Icons.school,
      'badgeBg': const Color(0xFFE3F2FD),
      'badgeColor': const Color(0xFF2196F3),
      'isTextBadge': false,
      'durationMin': '35 min',
      'difficulty': 'Beginner',
      'route': '/lesson_content',
      'progress': 1.0,
    },
    {
      'title': 'Plants & Trees',
      'gradeCategory': 'Grade 2',
      'category': 'EVS',
      'description': 'Identifying local flora, understanding their uses, and the importance of conservation.',
      'badgeText': 'P',
      'badgeIcon': Icons.park,
      'badgeBg': const Color(0xFFE8F5E9),
      'badgeColor': const Color(0xFF388E3C),
      'isTextBadge': false,
      'durationMin': '45 min',
      'difficulty': 'Intermediate',
      'route': '/lesson_content',
      'progress': 0.2,
    },
  ];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _animationController.reset();
    _animationController.forward();
  }

  List<Map<String, dynamic>> get _filteredLessons {
    return _allLessons.where((lesson) {
      final matchesSearch = lesson['title'].toString().toLowerCase().contains(_searchQuery) ||
          lesson['description'].toString().toLowerCase().contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'All' || lesson['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _navigateToLesson(Map<String, dynamic> lesson) {
    AppState.instance.updateClassroomSetup(lesson: lesson['title']);
    Navigator.pushNamed(context, lesson['route']);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    
    final appState = AppState.instance;
    final String grade = 'Grade ${appState.selectedGrade}';
    final String language = appState.studentLanguage.isNotEmpty ? appState.studentLanguage : 'Mundari';

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderBanner(grade, language),
        const SizedBox(height: 16),
        if (_searchQuery.isEmpty && _selectedCategory == 'All')
          _buildRecommendedCard(),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildCategoryChips(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildLessonList(),
        ),
      ],
    );

    Widget screenBody = isDesktop
        ? Row(
            children: [
              const VernexaDesktopSidebar(currentIndex: 1),
              Expanded(
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: const Color(0xFFF8F6FD),
                  appBar: AppBar(
                    backgroundColor: const Color(0xFFF8F6FD),
                    elevation: 0,
                    title: Text(
                      'Lesson Library',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF28127D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: content,
                  ),
                ),
              ),
            ],
          )
        : Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: const Color(0xFFF8F6FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF5C27D8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
              ),
              title: Text(
                'Lesson Library',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
            bottomNavigationBar: const VernexaBottomNav(currentIndex: 1),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      },
      child: screenBody,
    );
  }

  Widget _buildHeaderBanner(String grade, String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.library_books, color: Color(0xFF5C27D8), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_allLessons.length} lessons available • $grade • Student Language: $language',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF28127D),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard() {
    final Map<String, dynamic> recommended = _allLessons.firstWhere((l) => l['progress'] > 0.0 && l['progress'] < 1.0, orElse: () => _allLessons.firstWhere((l) => l['progress'] == 0.0));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C27D8), Color(0xFF28127D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C27D8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Up Next for You',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommended['title'],
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommended['description'],
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    recommended['durationMin'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.trending_up, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    recommended['difficulty'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _navigateToLesson(recommended),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF28127D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Start Lesson',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(),
        decoration: InputDecoration(
          hintText: 'Search lessons, topics, or descriptions...',
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5C27D8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onCategorySelected(category);
              },
              selectedColor: const Color(0xFF5C27D8),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : const Color(0xFF28127D),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5C27D8) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLessonList() {
    final filtered = _filteredLessons;
    
    if (filtered.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No lessons found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF28127D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search query.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final lesson = filtered[index];
          final progress = lesson['progress'] as double;
          
          return VernexaFloatable(
            onTap: () => _navigateToLesson(lesson),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: lesson['badgeBg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: lesson['isTextBadge']
                          ? Text(
                              lesson['badgeText'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                color: lesson['badgeColor'] as Color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Icon(
                              lesson['badgeIcon'] as IconData,
                              color: lesson['badgeColor'] as Color,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lesson['title'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF28127D),
                                ),
                              ),
                            ),
                            if (progress == 1.0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Completed',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${lesson['gradeCategory']} • ${lesson['category']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5C27D8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson['description'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              lesson['durationMin'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.trending_up, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              lesson['difficulty'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (progress > 0.0 && progress < 1.0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5C27D8)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5C27D8),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
