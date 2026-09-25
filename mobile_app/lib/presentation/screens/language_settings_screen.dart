import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const _purple = Color(0xFF5C27D8);
  static const _bg = Color(0xFFF8F6FD);

  final List<Map<String, String>> _teacherLanguages = [
    {'label': 'Hindi (हिंदी)', 'value': 'Hindi'},
    {'label': 'English', 'value': 'English'},
    {'label': 'Odia (ओडिया)', 'value': 'Odia'},
  ];

  final List<Map<String, String>> _studentLanguages = [
    {'label': 'Ho (हो)', 'value': 'Ho'},
    {'label': 'Mundari (मुंडारी)', 'value': 'Mundari'},
    {'label': 'Santhali (संथाली)', 'value': 'Santhali'},
    {'label': 'Kurukh (कुड़ुख)', 'value': 'Kurukh'},
  ];

  late String _selectedTeacherLang;
  late String _selectedStudentLang;
  // 0 = Teacher→Student, 1 = Student→Teacher
  int _translationDirection = 0;

  @override
  void initState() {
    super.initState();
    _selectedTeacherLang = AppState.instance.teacherLanguage;
    _selectedStudentLang = AppState.instance.studentLanguage;
  }

  void _save() {
    AppState.instance.updateClassroomSetup(
      tLang: _selectedTeacherLang,
      sLang: _selectedStudentLang,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _purple,
        duration: const Duration(seconds: 2),
        content: Text(
          'Language settings saved!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false);
  }

  Widget _buildRadioTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VernexaFloatable(
        hoverOffset: -2,
        hoverElevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? _purple.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _purple : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _purple : Colors.grey.shade400,
                      width: selected ? 6 : 2,
                    ),
                    color: selected ? Colors.white : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _purple : const Color(0xFF1A1333),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionTile({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _translationDirection == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VernexaFloatable(
        hoverOffset: -2,
        hoverElevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => setState(() => _translationDirection = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? _purple.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _purple : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? _purple.withValues(alpha: 0.15)
                        : const Color(0xFFF0EEF8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: selected ? _purple : const Color(0xFF8B7EC8),
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? _purple : const Color(0xFF1A1333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF6F62AB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1333),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Teacher Language ──────────────────────────────────
          _sectionLabel('Teacher Language'),
          VernexaFloatable(
            hoverOffset: -2,
            hoverElevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedTeacherLang,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, color: Colors.black87),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _purple),
                items: _teacherLanguages
                    .map((e) => DropdownMenuItem(
                          value: e['value'],
                          child: Text(e['label']!,
                              style:
                                  GoogleFonts.plusJakartaSans(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTeacherLang = v);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Student Language ──────────────────────────────────
          _sectionLabel('Student Language'),
          ..._studentLanguages.map((e) => _buildRadioTile(
                label: e['label']!,
                selected: _selectedStudentLang == e['value'],
                onTap: () => setState(() => _selectedStudentLang = e['value']!),
              )),

          const SizedBox(height: 24),

          // ── Translation Direction ─────────────────────────────
          _sectionLabel('Translation Direction'),
          _buildDirectionTile(
            index: 0,
            icon: Icons.arrow_forward_rounded,
            title: 'Teacher → Student',
            subtitle: '$_selectedTeacherLang → $_selectedStudentLang',
          ),
          _buildDirectionTile(
            index: 1,
            icon: Icons.swap_horiz_rounded,
            title: 'Student → Teacher',
            subtitle: '$_selectedStudentLang → $_selectedTeacherLang',
          ),

          const SizedBox(height: 32),

          // ── Save Button ───────────────────────────────────────
          VernexaFloatable(
            hoverOffset: -3,
            hoverElevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Save Language',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 800;

              if (isDesktop) {
                return Row(
                  children: [
                    const VernexaDesktopSidebar(currentIndex: 4),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            color: Colors.white,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false),
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      color: Color(0xFF28127D)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Language Settings',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF28127D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 540),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 24),
                                child: _buildBody(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Container(
                    color: _purple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'Language Settings',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildBody(context)),
                  const VernexaBottomNav(currentIndex: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
