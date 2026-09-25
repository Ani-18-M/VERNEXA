import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VernexaBottomNav extends StatelessWidget {
  final int currentIndex;

  const VernexaBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width >= 800) {
      return const SizedBox.shrink();
    }

    const activeColor = Color(0xFF5C27D8);
    const inactiveColor = Color(0xFF8B81B8);

    final List<Map<String, dynamic>> navItems = [
      {'label': 'Home', 'icon': Icons.home_rounded, 'route': '/home'},
      {'label': 'Lessons', 'icon': Icons.article_outlined, 'route': '/lessons'},
      {'label': 'Translate', 'icon': Icons.translate_rounded, 'route': '/translate'},
      {'label': 'Reports', 'icon': Icons.insert_chart_outlined_rounded, 'route': '/reports'},
      {'label': 'More', 'icon': Icons.widgets_rounded, 'route': '/more'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == currentIndex;
              final color = isSelected ? activeColor : inactiveColor;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (index == currentIndex) return;
                    final route = item['route'] as String?;
                    if (route != null) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
