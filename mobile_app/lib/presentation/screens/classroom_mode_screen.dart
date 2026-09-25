import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Feature Row Widget
// ──────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5C27D8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: VernexaFloatable(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Purple icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: purple, size: 24),
              ),
              const SizedBox(width: 16),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1333),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6F62AB),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFB8ADE0), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Main Screen
// ──────────────────────────────────────────────────────────────────────────────

class ClassroomModeScreen extends StatefulWidget {
  const ClassroomModeScreen({super.key});

  @override
  State<ClassroomModeScreen> createState() => _ClassroomModeScreenState();
}

class _ClassroomModeScreenState extends State<ClassroomModeScreen> {
  static const _purple = Color(0xFF5C27D8);
  static const _deepPurple = Color(0xFF28127D);
  static const _bg = Color(0xFFF8F6FD);

  static const _features = [
    (
      icon: Icons.volume_up_rounded,
      title: 'Listen',
      subtitle: 'Translates your speech for the class',
    ),
    (
      icon: Icons.mic_rounded,
      title: 'Speak',
      subtitle: 'Capture student responses',
    ),
    (
      icon: Icons.help_outline_rounded,
      title: 'Ask Questions',
      subtitle: 'Encourage participation',
    ),
    (
      icon: Icons.replay_rounded,
      title: 'Repeat',
      subtitle: 'Replay important points',
    ),
  ];

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Classroom Visual Banner ──────────────────────────────────────
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.people_alt_rounded,
              size: 80,
              color: _purple,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Headline ────────────────────────────────────────────────────────
        Text(
          'One shared device is enough for the classroom.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _deepPurple,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 10),

        // ── Subtitle ────────────────────────────────────────────────────────
        Text(
          'Students do not need individual smartphones.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6F62AB),
          ),
        ),

        const SizedBox(height: 28),

        // ── Feature Rows ─────────────────────────────────────────────────
        ..._features.map(
          (f) => _FeatureRow(
            icon: f.icon,
            title: f.title,
            subtitle: f.subtitle,
          ),
        ),

        const SizedBox(height: 8),

        // ── Start Button ────────────────────────────────────────────────
        VernexaFloatable(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Start Classroom Mode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            const VernexaDesktopSidebar(currentIndex: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Desktop top bar
                        Row(
                          children: [
                            VernexaFloatable(
                              onTap: () => Navigator.maybePop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.07),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: _deepPurple),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Classroom Mode',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile Layout ───────────────────────────────────────────────────
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
          elevation: 0,
          leading: VernexaFloatable(
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          title: Text(
            'Classroom Mode',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: _buildContent(),
          ),
        ),
        bottomNavigationBar: const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }
}
