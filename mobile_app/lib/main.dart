import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'presentation/screens/classroom_mode_screen.dart';
import 'presentation/screens/classroom_setup_screen.dart';
import 'presentation/screens/class_settings_screen.dart';
import 'presentation/screens/flashcards_screen.dart';
import 'presentation/screens/home_dashboard_screen.dart';
import 'presentation/screens/language_settings_screen.dart';
import 'presentation/screens/learning_pulse_screen.dart';
import 'presentation/screens/lesson_content_screen.dart';
import 'presentation/screens/lesson_library_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/more_screen.dart';
import 'presentation/screens/profile_settings_screen.dart';
import 'presentation/screens/real_time_translation_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/screens/teacher_coach_screen.dart';
import 'presentation/screens/teacher_login_screen.dart';
import 'presentation/screens/voice_conversation_screen.dart';
import 'presentation/screens/offline_storage_screen.dart';
import 'presentation/screens/logout_screen.dart';
import 'presentation/screens/worksheets_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const VernexaApp());
}

class VernexaApp extends StatelessWidget {
  const VernexaApp({super.key});

  static final Map<String, WidgetBuilder> _appRoutes = {
    '/': (context) => const LoginScreen(),
    '/login': (context) => const TeacherLoginScreen(),
    '/setup': (context) => const ClassroomSetupScreen(initialStep: 1),
    '/setup2': (context) => const ClassroomSetupScreen(initialStep: 2),
    '/setup3': (context) => const ClassroomSetupScreen(initialStep: 3),
    '/home': (context) => const HomeDashboardScreen(),
    '/lessons': (context) => const LessonLibraryScreen(),
    '/lesson_content': (context) => const LessonContentScreen(),
    '/translate': (context) => const RealTimeTranslationScreen(),
    '/reports': (context) => const ReportsScreen(),
    '/more': (context) => const MoreScreen(),
    '/voice_conversation': (context) => const VoiceConversationScreen(),
    '/classroom_mode': (context) => const ClassroomModeScreen(),
    '/worksheets': (context) => const WorksheetsScreen(),
    '/flashcards': (context) => const FlashcardsScreen(),
    '/learning_pulse': (context) => const LearningPulseScreen(),
    '/teacher_coach': (context) => const TeacherCoachScreen(),
    '/profile': (context) => const ProfileSettingsScreen(),
    '/class_settings': (context) => const ClassSettingsScreen(),
    '/language_settings': (context) => const LanguageSettingsScreen(),
    '/offline_storage': (context) => const OfflineStorageScreen(),
    '/logout': (context) => const LogoutScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VERNEXA - AI Classroom Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: _appRoutes,
      onGenerateRoute: (settings) {
        final rawName = settings.name ?? '/';
        final uri = Uri.tryParse(rawName);
        final path = uri?.path ?? '/';
        final normalizedPath = (path.length > 1 && path.endsWith('/'))
            ? path.substring(0, path.length - 1)
            : path;

        final builder = _appRoutes[normalizedPath];
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      },
    );
  }
}
