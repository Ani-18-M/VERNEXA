import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF5C27D8);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _red = Color(0xFFE53935);

  bool _isLoggingOut = false;

  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    // Brief delay to show loading state.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    AppState.instance.setLoggedIn(loggedIn: false);

    // Clear all routes and go back to the login/root screen.
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 480 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : 32,
              vertical: 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildIconCircle(size),
                const SizedBox(height: 36),
                _buildTextBlock(),
                const Spacer(flex: 3),
                _buildButtons(context),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Large Icon Circle ───────────────────────────────────────────────────

  Widget _buildIconCircle(Size size) {
    final circleSize = size.width >= 800 ? 160.0 : 140.0;
    return ScaleTransition(
      scale: _iconScale,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C27D8), Color(0xFF28127D)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle inner glow ring
            Container(
              width: circleSize - 20,
              height: circleSize - 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),
            // Exit / Door icon
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: circleSize * 0.42,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Text Block ──────────────────────────────────────────────────────────

  Widget _buildTextBlock() {
    return Column(
      children: [
        Text(
          'Are you sure you want to quit?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: _deepPurple,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'You will need to log in again to access VERNEXA.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────────────

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        // Cancel button (outlined)
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoggingOut ? null : () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primary, width: 1.8),
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Logout button (red filled)
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoggingOut ? null : _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              disabledBackgroundColor: _red.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Logout',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
