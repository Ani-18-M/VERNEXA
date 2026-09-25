import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import 'classroom_setup_screen.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mobile OTP state (No default prefilled information)
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _otpSent = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  // Teacher ID state (No default prefilled information)
  final TextEditingController _teacherIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedState;

  final List<String> _states = [
    'Jharkhand (झारखंड)',
    'Odisha (ଓଡ଼ିଆ / ओडिशा)',
    'Chhattisgarh (छत्तीसगढ़)',
    'Madhya Pradesh (मध्य प्रदेश)',
    'West Bengal (পশ্চিমবঙ্গ)',
    'Bihar (बिहार)',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _teacherIdController.dispose();
    _passwordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.replaceAll(RegExp(r'\s+'), '').length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF5C27D8),
          content: Text('Please enter a valid 10-digit mobile number'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _resendCountdown = 30;
        // Keep OTP boxes completely blank for teacher to enter
        for (var c in _otpControllers) {
          c.clear();
        }
      });

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('OTP sent successfully! Demo OTP: 1 2 3 4'),
        ),
      );
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleLogin() {
    // Validation based on active tab
    if (_tabController.index == 0) {
      // Mobile OTP Tab
      final otp = _otpControllers.map((c) => c.text.trim()).join();
      if (otp.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF5C27D8),
            content: Text('Please enter the complete 4-digit OTP'),
          ),
        );
        return;
      }
    } else {
      // Teacher ID Tab
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF5C27D8),
            content: Text('Please select your State / Education Board'),
          ),
        );
        return;
      }
      if (_teacherIdController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF5C27D8),
            content: Text('Please enter your Teacher ID or U-DISE Code'),
          ),
        );
        return;
      }
      if (_passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF5C27D8),
            content: Text('Please enter your Security PIN or Password'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String? teacherName;
      String? phone;
      if (_tabController.index == 1 && _teacherIdController.text.trim().isNotEmpty) {
        teacherName = _teacherIdController.text.trim();
      } else if (_tabController.index == 0 && _phoneController.text.trim().isNotEmpty) {
        phone = _phoneController.text.trim();
      }
      AppState.instance.setLoggedIn(loggedIn: true, name: teacherName, phone: phone);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ClassroomSetupScreen(initialStep: 1),
        ),
        (route) => false,
      );

      final welcomeText = teacherName != null && teacherName.isNotEmpty
          ? 'Welcome, $teacherName! Offline profile synced.'
          : (phone != null && phone.isNotEmpty
              ? 'Welcome, $phone! Offline profile synced.'
              : 'Welcome! Offline profile synced.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF5C27D8),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                welcomeText,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF5C27D8);
    const textDark = Color(0xFF261080);
    const textMuted = Color(0xFF6F62AB);
    const bgColor = Color(0xFFF8F6FD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Teacher Login',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 800;
            final isTablet = screenWidth >= 600 && screenWidth < 800;

            final double cardWidth = isDesktop ? 520 : (isTablet ? 480 : double.infinity);
            final EdgeInsets padding = EdgeInsets.symmetric(
              horizontal: isDesktop ? 36.0 : (isTablet ? 28.0 : 20.0),
              vertical: isDesktop ? 32.0 : 20.0,
            );

            return Center(
              child: SingleChildScrollView(
                padding: padding,
                child: Container(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  padding: EdgeInsets.all(isDesktop ? 32 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: textDark.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Badge & Title
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECE8FB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: primaryPurple,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Welcome Back, Teacher!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isDesktop ? 22 : 20,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Sign in to sync your classroom curriculum & records',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Method Tabs (Mobile OTP vs Teacher ID)
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEFA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: textMuted,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Mobile OTP'),
                            Tab(text: 'Teacher ID / PIN'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab View Content
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildMobileOtpView(primaryPurple, textDark, textMuted)
                              : _buildTeacherIdView(primaryPurple, textDark, textMuted);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Offline Mode Notice
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E0F5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.offline_bolt_rounded, color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Offline Mode: Login once to sync lessons for offline tribal classroom teaching.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: textMuted,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_tabController.index == 0 && !_otpSent ? _sendOtp : _handleLogin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                )
                              : Text(
                                  _tabController.index == 0 && !_otpSent ? 'Send OTP' : 'Verify & Continue',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Bypass Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            AppState.instance.setLoggedIn(loggedIn: true, name: 'Teacher', school: 'Govt. Primary School');
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const ClassroomSetupScreen(initialStep: 1),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Skip login & continue offline →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: primaryPurple,
                            ),
                          ),
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

  // Mobile OTP View (No default information)
  Widget _buildMobileOtpView(Color primaryPurple, Color textDark, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: !_otpSent,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.phone_android_rounded, color: primaryPurple),
            prefixText: '+91 ',
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
            hintText: 'Enter 10-digit mobile number',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.grey.shade400),
            filled: true,
            fillColor: _otpSent ? const Color(0xFFF8F6FD) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryPurple, width: 1.8),
            ),
          ),
        ),

        // OTP Section if OTP sent
        if (_otpSent) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter 4-Digit OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _otpSent = false),
                child: Text(
                  'Change Number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4-box OTP Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 58,
                height: 54,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF8F6FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryPurple, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 3) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resendCountdown > 0
                    ? 'Resend OTP in ${_resendCountdown}s'
                    : 'Didn\'t receive OTP? ',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textMuted),
              ),
              if (_resendCountdown == 0)
                InkWell(
                  onTap: _sendOtp,
                  child: Text(
                    'Resend Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primaryPurple,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // Teacher ID View (No default information)
  Widget _buildTeacherIdView(Color primaryPurple, Color textDark, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State Selection
        Text(
          'State / Education Board',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E0F5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedState,
              hint: Text(
                'Select State / Education Board',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  color: Colors.grey.shade400,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
              onChanged: (val) {
                if (val != null) setState(() => _selectedState = val);
              },
              items: _states.map((st) {
                return DropdownMenuItem(value: st, child: Text(st));
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Teacher ID / Employee Code
        Text(
          'Teacher ID / U-DISE Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _teacherIdController,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.badge_rounded, color: primaryPurple),
            hintText: 'e.g. JH-TCH-48291',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryPurple, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Security PIN / Password
        Text(
          'Security PIN / Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_rounded, color: primaryPurple),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            hintText: 'Enter 6-digit PIN or password',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E0F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryPurple, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
