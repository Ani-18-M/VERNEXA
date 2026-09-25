import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import 'classroom_setup_screen.dart';
import 'teacher_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _navigateToClassroomSetup(BuildContext context) {
    AppState.instance.setLoggedIn(loggedIn: true, name: 'Teacher', school: 'Govt. Primary School');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ClassroomSetupScreen(),
      ),
    );
  }

  void _showTeacherLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeacherLoginScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (AppState.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5C27D8)),
        ),
      );
    }

    const bgColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isDesktop = screenWidth >= 800;
            final isTablet = screenWidth >= 600 && screenWidth < 800;

            // Responsive vertical allocations
            final double topPadding = (screenHeight * 0.02).clamp(10.0, 24.0);
            final double titleFontSize = isDesktop ? 36.0 : (isTablet ? 30.0 : 25.0);
            final double subtitleFontSize = isDesktop ? 16.5 : (isTablet ? 15.0 : 13.5);
            final double illustrationMaxH = isDesktop
                ? (screenHeight * 0.28).clamp(180.0, 280.0)
                : (screenHeight * 0.29).clamp(150.0, 220.0);
            final double textSpacing = (screenHeight * 0.012).clamp(6.0, 14.0);
            final double missionFontSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
            final double buttonHeight = isDesktop ? 48.0 : 50.0;

            // Responsive footer height: on desktop, use the full aspect ratio (1376x608) so 100% of the landscape is visible
            final double footerHeight = isDesktop
                ? (screenWidth * (608.0 / 1376.0))
                : (isTablet
                    ? (screenHeight * 0.32).clamp(200.0, 300.0)
                    : (screenHeight * 0.28).clamp(180.0, 240.0));

            final String footerAsset = isDesktop
                ? 'assets/images/landscape_clean_desktop.png'
                : 'assets/images/landscape_clean_mobile.png';

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Content Container
                      Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 860 : (isTablet ? 560 : 440),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 36.0 : 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: topPadding),

                              // 1. App Title Header
                              Text(
                                'VERNEXA',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: isDesktop ? 1.0 : 0.6,
                                  color: const Color(0xFF261080),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AI Classroom Assistant',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: const Color(0xFF6F62AB),
                                ),
                              ),
                              SizedBox(height: textSpacing),

                              // 2. Main 2D Teacher & Students Illustration
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: illustrationMaxH,
                                  maxWidth: isDesktop ? 440 : double.infinity,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isDesktop ? 22 : 18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF261080).withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(isDesktop ? 22 : 18),
                                    child: Image.asset(
                                      'assets/images/gemini_teacher_students.png',
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: textSpacing),

                              // 3. Mission Text
                              Text(
                                isDesktop
                                    ? 'Breaking language barriers. Empowering every classroom.'
                                    : 'Breaking language barriers.\nEmpowering every classroom.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: missionFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF422A76),
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 18 : 12),

                              // 4. Action Buttons (Desktop: Row; Mobile: Stack)
                              if (isDesktop || isTablet)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: isDesktop ? 220 : 190,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => _showTeacherLogin(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5C27D8),
                                          foregroundColor: Colors.white,
                                          elevation: 1,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          alignment: Alignment.center,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Teacher Login',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    SizedBox(
                                      width: isDesktop ? 220 : 190,
                                      height: buttonHeight,
                                      child: OutlinedButton(
                                        onPressed: () => _navigateToClassroomSetup(context),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF4B2D8C),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          alignment: Alignment.center,
                                          side: const BorderSide(
                                            color: Color(0xFF9086B8),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Continue as Teacher',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4B2D8C),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => _showTeacherLogin(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5C27D8),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          alignment: Alignment.center,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Teacher Login',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: OutlinedButton(
                                        onPressed: () => _navigateToClassroomSetup(context),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF4B2D8C),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          alignment: Alignment.center,
                                          side: const BorderSide(
                                            color: Color(0xFF9086B8),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Continue as Teacher',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4B2D8C),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      if (!isDesktop) const Spacer() else const SizedBox(height: 28),

                      // 5. Blended Landscape Banner (100% visible on all devices, edge-to-edge)
                      SizedBox(
                        width: double.infinity,
                        height: footerHeight,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Landscape illustration spanning full width
                            Image.asset(
                              footerAsset,
                              width: double.infinity,
                              height: footerHeight,
                              fit: isDesktop ? BoxFit.fitWidth : BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                            ),

                            // Top gradient fade seamlessly dissolving sky into screen background (white)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: isDesktop ? (footerHeight * 0.28) : (footerHeight * 0.40),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      bgColor,
                                      bgColor.withValues(alpha: 0.80),
                                      bgColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.40, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // Centered crisp typography: "Better Teachers \n Brighter Futures"
                            Positioned(
                              bottom: (footerHeight * 0.12).clamp(16.0, 36.0),
                              left: 16,
                              right: 16,
                              child: Text(
                                'Better Teachers\nBrighter Futures',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isDesktop ? 22.0 : (isTablet ? 19.0 : 17.0),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.22,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.40),
                                      offset: const Offset(0, 1.5),
                                      blurRadius: 4.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
