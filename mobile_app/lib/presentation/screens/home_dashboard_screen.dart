import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    const bgPurple = Color(0xFF28127D);

    return Scaffold(
      backgroundColor: bgPurple,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            if (isDesktop) {
              return Row(
                children: [
                  const VernexaDesktopSidebar(currentIndex: 0),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 960),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        child: _buildDesktopVerticalLayout(context, state),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Mobile / Tablet layout with Bottom Nav
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: _buildMobileContent(context, state),
                  ),
                ),
                const VernexaBottomNav(currentIndex: 0),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP: SINGLE-PAGE VIEWPORT-FITTED VERTICAL FLOW (NO SCROLLING)
  // ==========================================
  Widget _buildDesktopVerticalLayout(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Top Greeting Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimeGreeting(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.teacherName.isNotEmpty
                      ? state.teacherName
                      : (state.phoneNumber.isNotEmpty ? state.phoneNumber : 'Welcome'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Classroom Live Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Today's Class Card (Spacious, prominent, floatable)
        VernexaFloatable(
          hoverOffset: -3,
          hoverElevation: 12,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C27D8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Today's Class",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5C27D8),
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildClassMetricBadge('Class', 'Grade ${state.selectedGrade}', Icons.school_rounded, const Color(0xFF5C27D8)),
                            const SizedBox(width: 12),
                            _buildClassMetricBadge('Students', '${state.studentCount}', Icons.groups_rounded, const Color(0xFF0284C7)),
                            const SizedBox(width: 12),
                            _buildClassMetricBadge('Language', state.studentLanguage, Icons.translate_rounded, const Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Lesson",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6F62AB),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.selectedLesson,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF261080),
                            ),
                          ),
                        ],
                      ),
                    ),
                    VernexaFloatable(
                      hoverOffset: -2,
                      hoverElevation: 6,
                      borderRadius: BorderRadius.circular(20),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/setup'),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: Text(
                          'Change',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C27D8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 3. Offline-ready Banner (Substantial, floatable)
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/offline_storage'),
          child: VernexaFloatable(
          hoverOffset: -2,
          hoverElevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FDF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB9F6CA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Offline Mode Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SYNCED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Core classroom tools, vernacular speech recognition, and curriculum modules cached locally.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF15803D), size: 20),
              ],
            ),
          ),
        ),
        ),

        const SizedBox(height: 22),

        // 4. Quick Actions Header
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 14),

        // 5. Quick Actions Grid
        _buildDesktopQuickActionsGrid(context),
      ],
    );
  }

  Widget _buildClassMetricBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6F62AB),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF261080),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Translate',
                icon: Icons.g_translate_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                onTap: () => Navigator.pushNamed(context, '/translate'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Voice Chat',
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFF5C27D8),
                iconBg: const Color(0xFFECE8FB),
                onTap: () => Navigator.pushNamed(context, '/voice_conversation'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Lessons',
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFFEC4899),
                iconBg: const Color(0xFFFDF2F8),
                onTap: () => Navigator.pushNamed(context, '/lessons'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Flashcards',
                icon: Icons.style_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEEF2FF),
                onTap: () => Navigator.pushNamed(context, '/flashcards'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Language Coach',
                icon: Icons.record_voice_over_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                onTap: () => Navigator.pushNamed(context, '/teacher_coach'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                context,
                title: 'Learning Pulse',
                icon: Icons.insights_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFF3E8FF),
                onTap: () => Navigator.pushNamed(context, '/learning_pulse'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 3
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildWideActionTile(
                context,
                title: 'Classroom Mode',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF1E293B),
                iconBg: const Color(0xFFE2E8F0),
                onTap: () => Navigator.pushNamed(context, '/classroom_mode'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: _buildWideActionTile(
                context,
                title: 'Offline Storage',
                icon: Icons.download_done_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFECFDF5),
                onTap: () => Navigator.pushNamed(context, '/offline_storage'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: _buildWideActionTile(
                context,
                title: 'Classroom Reports',
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                onTap: () => Navigator.pushNamed(context, '/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ==========================================
  // MOBILE / TABLET CONTENT
  // ==========================================
  Widget _buildMobileContent(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Bar (Centered, clean, no T avatar circles)
        Center(
          child: Column(
            children: [
              Text(
                'VERNEXA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI Classroom Assistant',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Greeting
        Text(
          _getTimeGreeting(),
          style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 2),
        Text(
          state.teacherName.isNotEmpty
              ? state.teacherName
              : (state.phoneNumber.isNotEmpty ? state.phoneNumber : 'Welcome'),
          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
        ),

        const SizedBox(height: 20),

        // Today's Class Card
        VernexaFloatable(
          hoverOffset: -3,
          hoverElevation: 10,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Class",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF261080),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildClassMetric('Class', 'Grade ${state.selectedGrade}')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildClassMetric('Students', '${state.studentCount}')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildClassMetric('Language', state.studentLanguage)),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Lesson",
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6F62AB)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            state.selectedLesson,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF261080),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/setup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C27D8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Change', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Offline Banner
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/offline_storage'),
          child: VernexaFloatable(
          hoverOffset: -2,
          hoverElevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FDF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB9F6CA), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Core classroom tools available without continuous internet.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF15803D), size: 18),
              ],
            ),
          ),
        ),
        ),

        const SizedBox(height: 22),

        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 12),

        _buildDesktopQuickActionsGrid(context),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClassMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6F62AB)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF261080)),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return VernexaFloatable(
      hoverOffset: -4,
      hoverElevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF261080),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return VernexaFloatable(
      hoverOffset: -4,
      hoverElevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF261080),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFC4B8E2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
