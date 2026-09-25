import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_state.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';
import '../widgets/vernexa_floatable.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const Color _primary = Color(0xFF5C27D8);
  static const Color _deepPurple = Color(0xFF28127D);
  static const Color _bg = Color(0xFFF8F6FD);

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

  // ─── Settings Menu Definition ───────────────────────────────────────────

  List<_SettingsItem> get _settingsItems {
    final state = AppState.instance;
    return [
      _SettingsItem(
        icon: Icons.edit,
        title: 'Edit Profile',
        subtitle: state.teacherName.isNotEmpty
            ? state.teacherName
            : (state.phoneNumber.isNotEmpty
                ? state.phoneNumber
                : 'Set name & details'),
      ),
      _SettingsItem(
        icon: Icons.class_rounded,
        title: 'Class Settings',
        subtitle: 'Grade ${state.selectedGrade} — ${state.studentCount} Students',
        route: '/class_settings',
      ),
      _SettingsItem(
        icon: Icons.language,
        title: 'Language Settings',
        subtitle: '${state.teacherLanguage} → ${state.studentLanguage}',
        route: '/language_settings',
      ),
      const _SettingsItem(
        icon: Icons.book_outlined,
        title: 'Lesson Settings',
      ),
      const _SettingsItem(
        icon: Icons.volume_up_outlined,
        title: 'Audio Settings',
      ),
      const _SettingsItem(
        icon: Icons.download_outlined,
        title: 'Offline Storage',
        route: '/offline_storage',
      ),
      const _SettingsItem(
        icon: Icons.sync,
        title: 'Sync',
        route: '/offline_storage',
      ),
      const _SettingsItem(
        icon: Icons.help_outline,
        title: 'Help',
      ),
    ];
  }

  void _showEditProfileDialog() {
    final state = AppState.instance;
    final nameController = TextEditingController(text: state.teacherName);
    final phoneController = TextEditingController(text: state.phoneNumber);
    final schoolController = TextEditingController(text: state.schoolName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Profile',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: _deepPurple,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full Name',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: _primary, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Phone Number',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your mobile number',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.phone_android_rounded,
                      color: _primary, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'School / Organization',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: schoolController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter school name or location',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.account_balance_outlined,
                      color: _primary, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppState.instance.updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                school: schoolController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _primary,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Profile updated successfully!',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            const VernexaDesktopSidebar(currentIndex: 4),
            Expanded(child: _buildDesktopContent()),
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
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
          ),
          title: Text(
            'Profile & Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
        bottomNavigationBar: const VernexaBottomNav(currentIndex: 4),
      ),
    );
  }

  // ─── Desktop Layout ───────────────────────────────────────────────────────

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Avatar + Profile Info card
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    _buildProfileCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Settings list
              Expanded(child: _buildSettingsCard()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile Body ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _buildAvatarSection(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
          const SizedBox(height: 12),
          _buildLogoutRow(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Profile Card (desktop) ───────────────────────────────────────────────

  Widget _buildProfileCard() {
    final state = AppState.instance;
    final hasName = state.teacherName.isNotEmpty;
    final hasPhone = state.phoneNumber.isNotEmpty;
    final hasInfo = hasName || hasPhone;
    final name = hasName
        ? state.teacherName
        : (hasPhone ? state.phoneNumber : 'Teacher Profile');
    final initial = hasName ? state.teacherName[0].toUpperCase() : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: _primary,
            child: initial.isNotEmpty
                ? Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasInfo ? 'Teacher' : 'Not Logged In',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          if (state.schoolName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              state.schoolName,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ] else if (!hasInfo) ...[
            const SizedBox(height: 2),
            Text(
              'Tap Edit Profile to set your details',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Avatar Section (mobile) ──────────────────────────────────────────────

  Widget _buildAvatarSection() {
    final state = AppState.instance;
    final hasName = state.teacherName.isNotEmpty;
    final hasPhone = state.phoneNumber.isNotEmpty;
    final hasInfo = hasName || hasPhone;
    final name = hasName
        ? state.teacherName
        : (hasPhone ? state.phoneNumber : 'Teacher Profile');
    final initial = hasName ? state.teacherName[0].toUpperCase() : '';

    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: _primary,
          child: initial.isNotEmpty
              ? Text(
                  initial,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasInfo ? 'Teacher' : 'Not Logged In',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        if (state.schoolName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            state.schoolName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ] else if (!hasInfo) ...[
          const SizedBox(height: 2),
          Text(
            'Tap Edit Profile to set your details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Settings Card ────────────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _settingsItems.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 68,
            color: Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            final item = _settingsItems[index];
            return _buildSettingsRow(item);
          },
        ),
      ),
    );
  }

  // ─── Single Settings Row ──────────────────────────────────────────────────

  Widget _buildSettingsRow(_SettingsItem item) {
    return VernexaFloatable(
      translateY: -2,
      scale: 1.005,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (item.title == 'Edit Profile') {
            _showEditProfileDialog();
          } else if (item.route != null) {
            Navigator.pushNamed(context, item.route!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _primary,
                duration: const Duration(seconds: 1),
                content: Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _deepPurple,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logout Row ───────────────────────────────────────────────────────────

  Widget _buildLogoutRow() {
    return VernexaFloatable(
      translateY: -2,
      scale: 1.005,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: MediaQuery.of(context).size.width >= 800
              ? null
              : [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(context, '/logout');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.logout_rounded,
                      color: Colors.red.shade600, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Logout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.red.shade300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.route,
  });
}
