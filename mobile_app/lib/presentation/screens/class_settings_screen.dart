import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class ClassSettingsScreen extends StatefulWidget {
  const ClassSettingsScreen({super.key});

  @override
  State<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends State<ClassSettingsScreen> {
  static const _purple = Color(0xFF5C27D8);
  static const _bg = Color(0xFFF8F6FD);

  late int _selectedGrade;
  late int _studentCount;

  final List<int> _grades = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _selectedGrade = AppState.instance.selectedGrade;
    _studentCount = AppState.instance.studentCount;
  }

  void _save() {
    AppState.instance.updateClassroomSetup(
      grade: _selectedGrade,
      count: _studentCount,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _purple,
        duration: const Duration(seconds: 2),
        content: Text(
          'Class settings saved!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false);
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Select Class ──────────────────────────────────────
          Text(
            'Select Class',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1333),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_grades.length, (i) {
            final grade = _grades[i];
            final selected = _selectedGrade == grade;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VernexaFloatable(
                hoverOffset: -2,
                hoverElevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGrade = grade),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? _purple.withValues(alpha: 0.1)
                          : Colors.white,
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
                          'Grade $grade',
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
          }),

          const SizedBox(height: 28),

          // ── Number of Students ────────────────────────────────
          Text(
            'Number of Students',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1333),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                // Minus
                VernexaFloatable(
                  hoverOffset: -2,
                  child: InkWell(
                    onTap: () {
                      if (_studentCount > 1) setState(() => _studentCount--);
                    },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: const Icon(Icons.remove_rounded, color: Color(0xFF5C27D8), size: 22),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$_studentCount',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1333),
                    ),
                  ),
                ),
                // Plus
                VernexaFloatable(
                  hoverOffset: -2,
                  child: InkWell(
                    onTap: () {
                      if (_studentCount < 100) setState(() => _studentCount++);
                    },
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: const Icon(Icons.add_rounded, color: Color(0xFF5C27D8), size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
                          // Desktop top bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            color: Colors.white,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false),
                                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF28127D)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Class Settings',
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
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
                  // Mobile AppBar
                  Container(
                    color: _purple,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/more', (route) => false),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'Class Settings',
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
