import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import 'vernexa_floatable.dart';

class VernexaDesktopSidebar extends StatelessWidget {
  final int currentIndex;

  const VernexaDesktopSidebar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const sidebarBg = Colors.white;
    const activeColor = Color(0xFF5C27D8);
    const borderColor = Color(0xFFE5E0F5);
    final state = AppState.instance;
    final displayName = state.teacherName.isNotEmpty
        ? state.teacherName
        : (state.phoneNumber.isNotEmpty ? state.phoneNumber : 'Teacher Profile');
    final hasInitial = state.teacherName.isNotEmpty || state.phoneNumber.isNotEmpty;
    final initial = state.teacherName.isNotEmpty
        ? state.teacherName[0].toUpperCase()
        : (state.phoneNumber.isNotEmpty ? state.phoneNumber[0] : '');

    final List<Map<String, dynamic>> items = [
      {'label': 'Home', 'icon': Icons.home_rounded, 'route': '/home'},
      {'label': 'Lessons', 'icon': Icons.article_outlined, 'route': '/lessons'},
      {'label': 'Translate', 'icon': Icons.translate_rounded, 'route': '/translate'},
      {'label': 'Reports', 'icon': Icons.insert_chart_outlined_rounded, 'route': '/reports'},
      {'label': 'More', 'icon': Icons.widgets_rounded, 'route': '/more'},
    ];

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VERNEXA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: const Color(0xFF28127D),
                        ),
                      ),
                      Text(
                        'AI Classroom Assistant',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6F62AB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),

          // 2. Navigation Items with Hover & Float Animations
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: _SidebarNavItem(
                    label: item['label'] as String,
                    icon: item['icon'] as IconData,
                    isSelected: isSelected,
                    onTap: () {
                      if (index == currentIndex) return;
                      final route = item['route'] as String?;
                      if (route != null) {
                        Navigator.pushReplacementNamed(context, route);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // 3. Bottom Teacher Profile Chip with Hover Animation
          Padding(
            padding: const EdgeInsets.all(12),
            child: VernexaFloatable(
              translateY: -2,
              scale: 1.01,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: activeColor,
                      child: hasInitial
                          ? Text(
                              initial,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          : const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF28127D),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Offline Ready',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF5C27D8);

    Color getBgColor() {
      if (widget.isSelected) return activeColor;
      if (_isHovered) return const Color(0xFFF3EFFF);
      return Colors.transparent;
    }

    Color getTextColor() {
      if (widget.isSelected) return Colors.white;
      if (_isHovered) return activeColor;
      return const Color(0xFF4A3E80);
    }

    Color getIconColor() {
      if (widget.isSelected) return Colors.white;
      if (_isHovered) return activeColor;
      return const Color(0xFF6F62AB);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(_isHovered && !widget.isSelected ? 3.0 : 0.0, 0.0, 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: getIconColor(),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
