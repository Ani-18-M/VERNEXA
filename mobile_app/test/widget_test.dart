import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vernexa/main.dart';
import 'package:vernexa/presentation/screens/classroom_setup_screen.dart';
import 'package:vernexa/presentation/screens/home_dashboard_screen.dart';
import 'package:vernexa/presentation/screens/lesson_library_screen.dart';
import 'package:vernexa/presentation/screens/lesson_content_screen.dart';
import 'package:vernexa/presentation/screens/real_time_translation_screen.dart';
import 'package:vernexa/presentation/widgets/vernexa_desktop_sidebar.dart';
import 'package:vernexa/presentation/widgets/vernexa_bottom_nav.dart';

void main() {
  testWidgets('Full flow test: Welcome -> Teacher Login -> 3-step Classroom Setup', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VernexaApp());
    await tester.pump();

    // 1. Verify Screen 1: Login
    expect(find.text('VERNEXA'), findsOneWidget);
    expect(find.text('AI Classroom Assistant'), findsOneWidget);
    expect(find.text('Teacher Login'), findsOneWidget);
    expect(find.text('Continue as Teacher'), findsOneWidget);

    // Test Teacher Login screen navigation
    await tester.tap(find.text('Teacher Login'));
    await tester.pumpAndSettle();

    // 2. Verify Teacher Login Screen
    expect(find.text('Welcome Back, Teacher!'), findsOneWidget);
    expect(find.text('Mobile OTP'), findsOneWidget);
    expect(find.text('Teacher ID / PIN'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);

    // Switch to Teacher ID tab
    await tester.tap(find.text('Teacher ID / PIN'));
    await tester.pumpAndSettle();
    expect(find.text('State / Education Board'), findsOneWidget);
    expect(find.text('Teacher ID / U-DISE Code'), findsOneWidget);
    expect(find.text('Security PIN / Password'), findsOneWidget);

    // Switch back to Mobile OTP tab, enter phone and send OTP
    await tester.tap(find.text('Mobile OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Enter 4-Digit OTP'), findsOneWidget);
    expect(find.text('Verify & Continue'), findsOneWidget);

    // Enter OTP digits into the 4 OTP fields
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), '1');
    await tester.enterText(textFields.at(2), '2');
    await tester.enterText(textFields.at(3), '3');
    await tester.enterText(textFields.at(4), '4');
    await tester.pump();

    // Verify & Continue into Classroom Setup
    await tester.tap(find.text('Verify & Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    // Dismiss any active snackbars so bottom buttons are unblocked
    ScaffoldMessenger.of(tester.element(find.byType(ClassroomSetupScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // 3. Verify Screen 2: Classroom Setup (1/3) with clean unselected defaults
    expect(find.text('Set Up Your Classroom'), findsOneWidget);
    expect(find.text('Select Class'), findsOneWidget);
    expect(find.text('Grade 2'), findsOneWidget);
    expect(find.text('Number of Students'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Select Grade 2
    await tester.tap(find.text('Grade 2'));
    await tester.pump();

    // Increment student counter
    await tester.ensureVisible(find.byIcon(Icons.add_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
    }
    expect(find.text('5'), findsOneWidget);

    // Navigate to Step 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 4. Verify Screen 3: Classroom Setup (2/3) with clean unselected defaults
    expect(find.text('Select Student Language'), findsOneWidget);
    expect(find.text('Teacher Language'), findsOneWidget);
    expect(find.text('Select Teacher Language'), findsOneWidget);
    expect(find.text('Student Language'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Select Teacher Language from Dropdown
    await tester.tap(find.text('Select Teacher Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi (हिंदी)').last);
    await tester.pumpAndSettle();

    // Select tribal student language (Mundari)
    await tester.ensureVisible(find.text('Mundari (मुंडारी)'));
    await tester.tap(find.text('Mundari (मुंडारी)'));
    await tester.pump();

    // Navigate to Step 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 5. Verify Screen 4: Classroom Setup (3/3) with clean unselected defaults
    expect(find.text("Select Today's Lesson"), findsOneWidget);
    expect(find.text('Numeracy'), findsOneWidget);
    expect(find.text('Literacy'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Select a subject above to view lessons'), findsOneWidget);
    expect(find.text('Start Class'), findsOneWidget);

    // Select Numeracy category
    await tester.tap(find.text('Numeracy'));
    await tester.pump();
    expect(find.text('Numbers 1 to 10'), findsOneWidget);

    // Select Numbers 1 to 10 lesson
    await tester.tap(find.text('Numbers 1 to 10'));
    await tester.pump();

    // Tap Start Class to launch session confirmation
    await tester.tap(find.text('Start Class'));
    await tester.pumpAndSettle();
    expect(find.text('Classroom Ready!'), findsOneWidget);
    expect(find.text('Launch Assistant'), findsOneWidget);

    // Tap Launch Assistant to enter Screen 5: Home Dashboard
    await tester.tap(find.text('Launch Assistant'));
    await tester.pumpAndSettle();

    // 6. Verify Screen 5: Home Dashboard
    expect(find.text('VERNEXA'), findsWidgets);
    expect(find.text('9876543210'), findsWidgets);
    expect(find.text("Today's Class"), findsOneWidget);
    expect(find.text('Offline-ready'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Voice Chat'), findsOneWidget);

    // Tap 'Lessons' Quick Action to navigate to Screen 6: Lesson Library
    await tester.tap(find.text('Lessons').first);
    await tester.pumpAndSettle();

    // 7. Verify Screen 6: Lesson Library
    expect(find.text('Lessons'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Literacy'), findsOneWidget);
    expect(find.text('Numeracy'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Numbers 1 to 10'), findsOneWidget);

    // Tap 'Numbers 1 to 10' to enter Screen 7: Lesson Content
    await tester.tap(find.text('Numbers 1 to 10'));
    await tester.pumpAndSettle();

    // 8. Verify Screen 7: Lesson Content
    expect(find.text('Learning Outcome'), findsOneWidget);
    expect(find.text('1. Lesson Script'), findsOneWidget);
    expect(find.text('Translate Lesson'), findsOneWidget);
    expect(find.text('Play Audio'), findsOneWidget);

    // Tap 'Translate Lesson' to navigate to Screen 8: Real-Time Translation
    await tester.tap(find.text('Translate Lesson'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 9. Verify Screen 8: Real-Time Translation
    expect(find.text('Real-Time Translation'), findsOneWidget);
    expect(find.text('Teacher → Student'), findsOneWidget);
    expect(find.text('Student → Teacher'), findsOneWidget);
    expect(find.text('Tap to Speak'), findsOneWidget);
    expect(find.text('Play Translation'), findsOneWidget);

    // Toggle recording
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(find.text('Listening... Tap to stop'), findsOneWidget);

    // Stop recording
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    expect(find.text('Translating...'), findsWidgets);

    // Test Play Translation button
    await tester.tap(find.text('Play Translation'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Dismiss any active snackbars and wait for fade out
    ScaffoldMessenger.of(tester.element(find.byType(RealTimeTranslationScreen))).clearSnackBars();
    await tester.pump(const Duration(milliseconds: 500));

    // Test back button from Screen 8 to Screen 7 (Lesson Content)
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Learning Outcome'), findsOneWidget);

    // Test back button from Screen 7 to Screen 6 (Lesson Library)
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Lessons'), findsWidgets);

    // Test back button from Screen 6 to Screen 5 (Home Dashboard)
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text("Today's Class"), findsOneWidget);
  });

  testWidgets('Desktop view renders VernexaDesktopSidebar on screens 5, 6, 7, 8', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Test Screen 5 on Desktop
    await tester.pumpWidget(const MaterialApp(home: HomeDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaDesktopSidebar), findsOneWidget);

    // Test Screen 6 on Desktop
    await tester.pumpWidget(const MaterialApp(home: LessonLibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaDesktopSidebar), findsOneWidget);

    // Test Screen 7 on Desktop
    await tester.pumpWidget(const MaterialApp(home: LessonContentScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaDesktopSidebar), findsOneWidget);

    // Test Screen 8 on Desktop
    await tester.pumpWidget(const MaterialApp(home: RealTimeTranslationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VernexaDesktopSidebar), findsOneWidget);
  });

  testWidgets('Mobile view renders VernexaBottomNav and hides desktop sidebar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Test Screen 5 on Mobile
    await tester.pumpWidget(const MaterialApp(home: HomeDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaBottomNav), findsOneWidget);
    expect(find.byType(VernexaDesktopSidebar), findsNothing);

    // Test Screen 6 on Mobile
    await tester.pumpWidget(const MaterialApp(home: LessonLibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaBottomNav), findsOneWidget);
    expect(find.byType(VernexaDesktopSidebar), findsNothing);

    // Test Screen 7 on Mobile
    await tester.pumpWidget(const MaterialApp(home: LessonContentScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(VernexaBottomNav), findsOneWidget);
    expect(find.byType(VernexaDesktopSidebar), findsNothing);

    // Test Screen 8 on Mobile
    await tester.pumpWidget(const MaterialApp(home: RealTimeTranslationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VernexaBottomNav), findsOneWidget);
    expect(find.byType(VernexaDesktopSidebar), findsNothing);
  });
}
