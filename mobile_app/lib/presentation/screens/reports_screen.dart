import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class _StudentRecord {
  final String name;
  final int understood;   // out of 10
  final int practiceNeeded;
  final String lastActive;
  final String trend;     // 'up', 'down', 'stable'

  const _StudentRecord({
    required this.name,
    required this.understood,
    required this.practiceNeeded,
    required this.lastActive,
    required this.trend,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _statAnimCtrl;
  late Animation<double> _statAnim;

  static const Color _primary = Color(0xFF5C27D8);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _bg = Color(0xFFF8F6FD);

  String _selectedPeriod = 'This Term';
  final List<String> _periods = ['This Week', 'This Month', 'This Term', 'All Time'];

  // ── Student Records ──────────────────────────────────────────────────────
  final List<_StudentRecord> _students = const [
    _StudentRecord(name: 'Riya Murmu',       understood: 9, practiceNeeded: 1, lastActive: 'Today',      trend: 'up'),
    _StudentRecord(name: 'Arjun Hembrom',    understood: 7, practiceNeeded: 3, lastActive: 'Today',      trend: 'up'),
    _StudentRecord(name: 'Sita Soren',       understood: 8, practiceNeeded: 2, lastActive: 'Yesterday',  trend: 'stable'),
    _StudentRecord(name: 'Karan Munda',      understood: 5, practiceNeeded: 5, lastActive: 'Yesterday',  trend: 'down'),
    _StudentRecord(name: 'Geeta Tudu',       understood: 9, practiceNeeded: 1, lastActive: 'Today',      trend: 'up'),
    _StudentRecord(name: 'Rohit Baski',      understood: 4, practiceNeeded: 6, lastActive: '2 days ago', trend: 'down'),
    _StudentRecord(name: 'Priya Hansa',      understood: 8, practiceNeeded: 2, lastActive: 'Today',      trend: 'stable'),
    _StudentRecord(name: 'Suresh Oraon',     understood: 6, practiceNeeded: 4, lastActive: 'Yesterday',  trend: 'stable'),
  ];

  // ── Lesson Data ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _lessons = const [
    {'name': 'Numbers 1–10',        'grade': 'Grade 2', 'pct': 0.92, 'sessions': 4, 'category': 'Numeracy'},
    {'name': 'Alphabet & Sounds',   'grade': 'Grade 1', 'pct': 0.78, 'sessions': 3, 'category': 'Literacy'},
    {'name': 'Counting Objects',    'grade': 'Grade 2', 'pct': 0.65, 'sessions': 2, 'category': 'Numeracy'},
    {'name': 'Simple Words',        'grade': 'Grade 1', 'pct': 0.55, 'sessions': 2, 'category': 'Literacy'},
    {'name': 'Shapes & Colors',     'grade': 'Grade 1', 'pct': 0.88, 'sessions': 3, 'category': 'Numeracy'},
    {'name': 'Numbers 11–20',       'grade': 'Grade 2', 'pct': 0.40, 'sessions': 1, 'category': 'Numeracy'},
    {'name': 'My Family',           'grade': 'Grade 1', 'pct': 0.95, 'sessions': 5, 'category': 'Literacy'},
    {'name': 'Plants Around Us',    'grade': 'Grade 3', 'pct': 0.70, 'sessions': 2, 'category': 'EVS'},
    {'name': 'My School',           'grade': 'Grade 2', 'pct': 0.82, 'sessions': 3, 'category': 'EVS'},
  ];

  // ── Concept Mastery Data ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _concepts = const [
    {'label': 'Number Recognition',  'score': 0.88, 'students': 28},
    {'label': 'Counting Aloud',       'score': 0.72, 'students': 23},
    {'label': 'Written Numerals',     'score': 0.60, 'students': 19},
    {'label': 'Word Problems',        'score': 0.44, 'students': 14},
    {'label': 'Ordering Numbers',     'score': 0.80, 'students': 26},
    {'label': 'Letter Recognition',   'score': 0.85, 'students': 27},
    {'label': 'Phonics & Sounds',     'score': 0.68, 'students': 22},
  ];

  // ── Lesson filter ────────────────────────────────────────────────────────
  String _lessonCategoryFilter = 'All';
  String _sortStudentBy = 'Score';
  bool _showAllStudents = false;

  // ── Weekly trend data ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _weeklyTrend = const [
    {'week': 'W1', 'pct': 0.58},
    {'week': 'W2', 'pct': 0.63},
    {'week': 'W3', 'pct': 0.70},
    {'week': 'W4', 'pct': 0.75},
    {'week': 'W5', 'pct': 0.82},
    {'week': 'W6', 'pct': 0.86},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _statAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _statAnim = CurvedAnimation(parent: _statAnimCtrl, curve: Curves.easeOut);
    _statAnimCtrl.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statAnimCtrl.dispose();
    super.dispose();
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _primary,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Report exported — check your Downloads folder.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Builders ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final totalStudents = AppState.instance.studentCount;
    final understood = (totalStudents * 0.82).round();
    final needsPractice = (totalStudents * 0.12).round();
    final needsReteach = totalStudents - understood - needsPractice;
    final displayStudents = _showAllStudents ? _students : _students.take(5).toList();

    final sorted = [...displayStudents]..sort((a, b) {
        if (_sortStudentBy == 'Score') return b.understood.compareTo(a.understood);
        return a.name.compareTo(b.name);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _deepPurple,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: Colors.white,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: _deepPurple),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 16),
                  items: _periods.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: _deepPurple)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Hero stat cards ──
          AnimatedBuilder(
            animation: _statAnim,
            builder: (_, __) => Row(
              children: [
                Expanded(child: _buildAnimatedStatCard(
                  value: '${(82 * _statAnim.value).round()}%',
                  label: 'Class Score',
                  icon: Icons.insights_rounded,
                  color: _primary,
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildAnimatedStatCard(
                  value: '${(9 * _statAnim.value).round()}',
                  label: 'Lessons Done',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF10B981),
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildAnimatedStatCard(
                  value: '${(5 * _statAnim.value).round()}',
                  label: 'Day Streak',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFF97316),
                )),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Class donut overview ──
          _buildDonutCard(
            title: 'Class Understanding',
            subtitle: 'Numbers 1–10 • ${AppState.instance.studentLanguage} class',
            progress: 0.82,
            label1: understood.toString(), label1Desc: 'Well Understood',
            label2: needsPractice.toString(), label2Desc: 'Need Practice',
            label3: needsReteach.toString(), label3Desc: 'Re-teach',
          ),
          const SizedBox(height: 16),

          // ── Progress trend ──
          _buildTrendCard(),
          const SizedBox(height: 16),

          // ── Student breakdown table ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Breakdown',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _deepPurple),
                      ),
                      // Sort toggle
                      GestureDetector(
                        onTap: () => setState(() => _sortStudentBy = _sortStudentBy == 'Score' ? 'Name' : 'Score'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort_rounded, size: 13, color: _primary),
                              const SizedBox(width: 4),
                              Text(
                                'Sort: $_sortStudentBy',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Column headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Student', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500))),
                      Expanded(flex: 3, child: Text('Understanding', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500))),
                      SizedBox(width: 40, child: Text('Trend', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500))),
                    ],
                  ),
                ),
                ...sorted.map((s) => _buildStudentRow(s)),
                // Show more / less
                InkWell(
                  onTap: () => setState(() => _showAllStudents = !_showAllStudents),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        _showAllStudents ? '↑ Show Less' : '↓ Show All ${_students.length} Students',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Areas needing practice ──
          _buildAreasCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStudentRow(_StudentRecord s) {
    final pct = s.understood / 10;
    final barColor = pct >= 0.75
        ? const Color(0xFF10B981)
        : (pct >= 0.55 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final trendIcon = s.trend == 'up'
        ? Icons.trending_up_rounded
        : (s.trend == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    final trendColor = s.trend == 'up'
        ? const Color(0xFF10B981)
        : (s.trend == 'down' ? const Color(0xFFEF4444) : Colors.grey.shade400);

    return Column(
      children: [
        const Divider(height: 1, indent: 18, endIndent: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _deepPurple),
                    ),
                    Text(
                      s.lastActive,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.understood}/10',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: barColor),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Icon(trendIcon, color: trendColor, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsTab() {
    final categories = ['All', 'Numeracy', 'Literacy', 'EVS'];
    final filtered = _lessonCategoryFilter == 'All'
        ? _lessons
        : _lessons.where((l) => l['category'] == _lessonCategoryFilter).toList();
    final avg = filtered.isEmpty ? 0.0 : filtered.fold(0.0, (s, l) => s + (l['pct'] as double)) / filtered.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat row
          Row(
            children: [
              Expanded(child: _buildMiniStatBox('${filtered.length}', 'Lessons', _primary)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStatBox('${(avg * 100).round()}%', 'Avg Score', const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStatBox(
                filtered.where((l) => (l['pct'] as double) >= 0.75).length.toString(),
                'On Track', const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 16),

          // Category filter chips
          Text('Filter by Subject', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final sel = cat == _lessonCategoryFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _lessonCategoryFilter = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? _primary : const Color(0xFFE5E0F5), width: 1.2),
                      ),
                      child: Text(cat, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF6F62AB),
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Lesson cards
          ...filtered.map((l) {
            final pct = l['pct'] as double;
            final barColor = pct >= 0.75
                ? const Color(0xFF10B981)
                : (pct >= 0.55 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
            final statusLabel = pct >= 0.75 ? 'On Track' : (pct >= 0.55 ? 'Needs Practice' : 'Re-teach');
            final statusBg = pct >= 0.75
                ? const Color(0xFFD1FAE5)
                : (pct >= 0.55 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));

            return VernexaFloatable(
              translateY: -2,
              scale: 1.005,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _deepPurple)),
                              const SizedBox(height: 2),
                              Text('${l['grade']} • ${l['category']} • ${l['sessions']} session${(l['sessions'] as int) > 1 ? 's' : ''}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${(pct * 100).round()}%',
                                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: barColor)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(statusLabel,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: barColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUnderstandingTab() {
    const totalStudents = 32;
    final weakConcepts = _concepts.where((c) => (c['score'] as double) < 0.6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              Expanded(child: _buildSummaryTile('26', 'Understood', const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildSummaryTile('4', 'Need Practice', const Color(0xFFF59E0B))),
              const SizedBox(width: 10),
              Expanded(child: _buildSummaryTile('2', 'Re-teach', const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 16),

          // Class donut for understanding
          _buildDonutCard(
            title: 'Overall Comprehension',
            subtitle: 'Based on Learning Pulse sessions — $totalStudents students',
            progress: 0.82,
            label1: '26', label1Desc: 'Understood',
            label2: '4',  label2Desc: 'Needs Practice',
            label3: '2',  label3Desc: 'Re-teach',
          ),
          const SizedBox(height: 16),

          // Concept-wise mastery
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Concept-wise Mastery',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _deepPurple)),
                    Text('$totalStudents students',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 14),
                ..._concepts.map((cat) {
                  final score = cat['score'] as double;
                  final students = cat['students'] as int;
                  final barColor = score >= 0.75
                      ? const Color(0xFF10B981)
                      : (score >= 0.55 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(cat['label'] as String,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: _deepPurple))),
                            Text('$students/$totalStudents',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: barColor)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: score,
                            minHeight: 7,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // AI Suggestions
          if (weakConcepts.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('AI Teaching Suggestions',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...weakConcepts.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _suggestionFor(c['label'] as String),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white70, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _suggestionFor(String concept) {
    switch (concept) {
      case 'Word Problems':
        return 'Use oral storytelling in ${AppState.instance.studentLanguage} — "If you have 3 stones and pick 2 more, how many?" Connect maths to village life scenarios.';
      case 'Phonics & Sounds':
        return 'Practice tribal phonemes that don\'t exist in Hindi — use clapping rhythm for each syllable in ${AppState.instance.studentLanguage} words.';
      default:
        return 'Re-teach "$concept" using hands-on local materials and ${AppState.instance.studentLanguage} language anchoring before moving to the next concept.';
    }
  }

  // ─── Shared Widget Builders ────────────────────────────────────────────────

  Widget _buildAnimatedStatCard({required String value, required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDonutCard({
    required String title,
    required String subtitle,
    required double progress,
    required String label1, required String label1Desc,
    required String label2, required String label2Desc,
    required String label3, required String label3Desc,
  }) {
    return VernexaFloatable(
      translateY: -3,
      scale: 1.01,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _deepPurple)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Donut
                SizedBox(
                  width: 130, height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: _DonutPainter(progress: progress),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(progress * 100).round()}%',
                              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: _deepPurple)),
                          Text('Score', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendRow(const Color(0xFF10B981), label1, label1Desc),
                      const SizedBox(height: 12),
                      _buildLegendRow(const Color(0xFFF59E0B), label2, label2Desc),
                      const SizedBox(height: 12),
                      _buildLegendRow(const Color(0xFFEF4444), label3, label3Desc),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String value, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade600))),
      ],
    );
  }

  Widget _buildTrendCard() {
    const maxBarH = 80.0;
    return VernexaFloatable(
      translateY: -3, scale: 1.01,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Progress Trend', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _deepPurple)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 13),
                      const SizedBox(width: 4),
                      Text('+28% this term', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weeklyTrend.map((d) {
                final pct = d['pct'] as double;
                final isLast = d == _weeklyTrend.last;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(pct * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700,
                            color: isLast ? _primary : Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28, height: maxBarH * pct,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: isLast
                              ? [_primary, const Color(0xFF8B5CF6)]
                              : [_primary.withValues(alpha: 0.25), _primary.withValues(alpha: 0.45)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d['week'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasCard() {
    final weak = _lessons.where((l) => (l['pct'] as double) < 0.6).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Areas', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _deepPurple)),
          const SizedBox(height: 4),
          Text('Lessons scoring below 60% need re-teaching',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          if (weak.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text('All lessons on track! Great work.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
              ],
            )
          else
            ...weak.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['name'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: _deepPurple)),
                        Text('${l['grade']} • ${((l['pct'] as double) * 100).round()}% understanding',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/lessons'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF5C27D8), size: 22),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Desktop ───────────────────────────────────────────────────────────────

  Widget _buildDesktopContent() {
    return Column(
      children: [
        Container(
          color: _primary,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
              ),
              const SizedBox(width: 8),
              Text('Reports', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 32),
              _buildDesktopTabBar(),
              const Spacer(),
              // Period filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: _deepPurple,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                  items: _periods.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _exportReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text('Export', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDesktopOverview(),
              _buildLessonsTab(),
              _buildUnderstandingTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      dividerColor: Colors.transparent,
      tabs: const [Tab(text: 'Overview'), Tab(text: 'Lessons'), Tab(text: 'Understanding')],
    );
  }

  Widget _buildDesktopOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top stat row
              AnimatedBuilder(
                animation: _statAnim,
                builder: (_, __) => Row(
                  children: [
                    Expanded(child: _buildAnimatedStatCard(value: '${(82 * _statAnim.value).round()}%', label: 'Class Score', icon: Icons.insights_rounded, color: _primary)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAnimatedStatCard(value: '${(9 * _statAnim.value).round()}', label: 'Lessons Done', icon: Icons.menu_book_rounded, color: const Color(0xFF10B981))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAnimatedStatCard(value: '${(5 * _statAnim.value).round()}', label: 'Day Streak', icon: Icons.local_fire_department_rounded, color: const Color(0xFFF97316))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAnimatedStatCard(value: '${AppState.instance.studentCount}', label: 'Students', icon: Icons.group_rounded, color: const Color(0xFF3B82F6))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildDonutCard(
                          title: 'Class Understanding', subtitle: '${AppState.instance.studentCount} students enrolled',
                          progress: 0.82, label1: '26', label1Desc: 'Understood',
                          label2: '4', label2Desc: 'Needs Practice', label3: '2', label3Desc: 'Re-teach',
                        ),
                        const SizedBox(height: 20),
                        _buildAreasCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildTrendCard(),
                        const SizedBox(height: 20),
                        // Recent Activity card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recent Activity', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _deepPurple)),
                              const SizedBox(height: 14),
                              ...[
                                ('Lesson: Numbers 1–10 completed', '82% class score', Icons.check_circle_rounded, const Color(0xFF10B981)),
                                ('Learning Pulse: 6 questions run', '3 students need re-teach', Icons.insights_rounded, _primary),
                                ('Worksheet generated & saved', 'Numbers 1–10 • Grade 2', Icons.description_rounded, const Color(0xFF3B82F6)),
                                ('Voice session recorded', 'Mundari pronunciation practice', Icons.mic_rounded, const Color(0xFFF97316)),
                              ].map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(color: a.$4.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(a.$3, color: a.$4, size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.$1, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _deepPurple)),
                                          Text(a.$2, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            const VernexaDesktopSidebar(currentIndex: 3),
            Expanded(child: _buildDesktopContent()),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
            ),
            title: Text('Reports', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
                tooltip: 'Export Report',
                onPressed: _exportReport,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Lessons'), Tab(text: 'Understanding')],
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLessonsTab(),
                _buildUnderstandingTab(),
              ],
            ),
          ),
          bottomNavigationBar: const VernexaBottomNav(currentIndex: 3),
        ),
      ),
    );
  }
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 16.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = const Color(0xFFE9E2FB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5C27D8), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}
