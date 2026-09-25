import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  bool _isLoggedIn = false;
  String _teacherName = '';
  String _phoneNumber = '';
  String _schoolName = '';
  int _selectedGrade = 2;
  int _studentCount = 32;
  String _teacherLanguage = 'Hindi';
  String _studentLanguage = 'Mundari';
  String _selectedLesson = 'Numbers 1 to 10';

  bool get isLoggedIn => _isLoggedIn;
  String get teacherName => _teacherName;
  String get phoneNumber => _phoneNumber;
  String get schoolName => _schoolName;
  int get selectedGrade => _selectedGrade;
  int get studentCount => _studentCount;
  String get teacherLanguage => _teacherLanguage;
  String get studentLanguage => _studentLanguage;
  String get selectedLesson => _selectedLesson;

  void setLoggedIn({
    required bool loggedIn,
    String? name,
    String? phone,
    String? school,
  }) {
    _isLoggedIn = loggedIn;
    if (name != null) {
      _teacherName = name.trim();
    }
    if (phone != null) {
      _phoneNumber = phone.trim();
    }
    if (school != null) {
      _schoolName = school.trim();
    }
    if (!loggedIn) {
      _teacherName = '';
      _phoneNumber = '';
      _schoolName = '';
    }
    notifyListeners();
  }

  void updateProfile({String? name, String? phone, String? school}) {
    if (name != null) _teacherName = name.trim();
    if (phone != null) _phoneNumber = phone.trim();
    if (school != null) _schoolName = school.trim();
    notifyListeners();
  }

  void updateClassroomSetup({
    int? grade,
    int? count,
    String? tLang,
    String? sLang,
    String? lesson,
  }) {
    if (grade != null) _selectedGrade = grade;
    if (count != null && count > 0) _studentCount = count;
    if (tLang != null) _teacherLanguage = _cleanLanguageName(tLang);
    if (sLang != null) _studentLanguage = _cleanLanguageName(sLang);
    if (lesson != null) _selectedLesson = lesson;
    notifyListeners();
  }

  String _cleanLanguageName(String raw) {
    if (raw.contains('(')) {
      return raw.split('(').first.trim();
    }
    return raw.trim();
  }
}
