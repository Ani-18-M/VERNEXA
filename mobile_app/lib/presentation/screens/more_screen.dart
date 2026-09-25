import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const Color _primaryPurple = Color(0xFF5C27D8);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _bgColor = Color(0xFFF8F6FD);

  static const List<_FeatureTile> _tiles = [
    _FeatureTile(
      icon: Icons.record_voice_over_rounded,
      name: 'Voice Conversation',
      description: 'Two-way translation',
      route: '/voice_conversation',
    ),
    _FeatureTile(
      icon: Icons.groups_rounded,
      name: 'Classroom Mode',
      description: 'One device for all',
      route: '/classroom_mode',
    ),
    _FeatureTile(
      icon: Icons.assignment_rounded,
      name: 'Worksheets',
      description: 'Generate printable sheets',
      route: '/worksheets',
    ),
    _FeatureTile(
      icon: Icons.style_rounded,
      name: 'Flashcards',
      description: 'Visual learning cards',
      route: '/flashcards',
    ),
    _FeatureTile(
      icon: Icons.insights_rounded,
      name: 'Learning Pulse',
      description: 'Class understanding',
      route: '/learning_pulse',
    ),
    _FeatureTile(
      icon: Icons.school_rounded,
      name: 'Language Coach',
      description: 'Improve your Mundari',
      route: '/teacher_coach',
    ),
    _FeatureTile(
      icon: Icons.bar_chart_rounded,
      name: 'Reports',
      description: 'Class analytics',
      route: '/reports',
    ),
    _FeatureTile(
      icon: Icons.person_rounded,
      name: 'Profile & Settings',
      description: 'Account & preferences',
      route: '/profile',
    ),
    _FeatureTile(
      icon: Icons.download_done_rounded,
      name: 'Offline Storage',
      description: 'Manage downloaded content',
      route: '/offline_storage',
    ),
    _FeatureTile(
      icon: Icons.logout_rounded,
      name: 'Logout',
      description: 'Sign out of VERNEXA',
      route: '/logout',
    ),
  ];

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _deepPurple,
        ),
      ),
    );
  }

  Widget _buildCard(_FeatureTile tile) {
    return VernexaFloatable(
      onTap: () => Navigator.pushNamed(context, tile.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tile.icon,
                size: 30,
                color: _primaryPurple,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tile.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: _tiles.length,
      itemBuilder: (context, index) => _buildCard(_tiles[index]),
    );
  }

  Widget _buildMobileBody() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Teaching Tools'),
            _buildGrid(),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'VERNEXA v1.0.0 • Powered by Gemini AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Expanded(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 960),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Teaching Tools'),
                _buildGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Row(
          children: [
            const VernexaDesktopSidebar(currentIndex: 4),
            _buildDesktopContent(),
          ],
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
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _primaryPurple,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
          ),
          title: Text(
            'More Tools',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _buildMobileBody(),
        bottomNavigationBar: const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }
}

class _FeatureTile {
  final IconData icon;
  final String name;
  final String description;
  final String route;

  const _FeatureTile({
    required this.icon,
    required this.name,
    required this.description,
    required this.route,
  });
}
