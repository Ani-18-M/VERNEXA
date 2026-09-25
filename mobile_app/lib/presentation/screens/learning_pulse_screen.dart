import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vernexa_bottom_nav.dart';
import '../widgets/vernexa_desktop_sidebar.dart';

class PulseQuestion {
  final String text;
  final List<String> choices;
  final int correctIndex;
  final String category;
  final Widget? visualAid;

  PulseQuestion({
    required this.text,
    required this.choices,
    required this.correctIndex,
    required this.category,
    this.visualAid,
  });
}

class LearningPulseScreen extends StatefulWidget {
  const LearningPulseScreen({super.key});

  @override
  State<LearningPulseScreen> createState() => _LearningPulseScreenState();
}

class _LearningPulseScreenState extends State<LearningPulseScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _selectedAnswer = -1;
  bool _isRecording = false;
  bool _hasResult = false;
  int _wellUnderstoodPct = 0;
  int _needsPracticePct = 0;
  int _needsReteachPct = 0;
  final List<int> _sessionResults = [];
  bool _sessionComplete = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final Color primaryColor = const Color(0xFF5C27D8);
  final Color deepPurple = const Color(0xFF28127D);
  final Color bgColor = const Color(0xFFF8F6FD);

  late List<PulseQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _initializeQuestions();
  }

  void _initializeQuestions() {
    _questions = [
      PulseQuestion(
        text: 'How many fingers on one hand?',
        choices: ['3', '4', '5', '6'],
        correctIndex: 2,
        category: 'Counting',
      ),
      PulseQuestion(
        text: 'Which number comes after 7?',
        choices: ['6', '8', '9', '10'],
        correctIndex: 1,
        category: 'Ordering',
      ),
      PulseQuestion(
        text: 'Count the objects shown:',
        choices: ['2', '3', '4', '5'],
        correctIndex: 1,
        category: 'Recognition',
        visualAid: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
      PulseQuestion(
        text: 'What is the number written as "तीन" in Hindi?',
        choices: ['1', '2', '3', '4'],
        correctIndex: 2,
        category: 'Recognition',
      ),
      PulseQuestion(
        text: 'Which is greater: 6 or 4?',
        choices: ['4', '5', '6', '7'],
        correctIndex: 2,
        category: 'Ordering',
      ),
      PulseQuestion(
        text: 'How many sides does a triangle have?',
        choices: ['2', '3', '4', '5'],
        correctIndex: 1,
        category: 'Counting',
      ),
    ];
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _recordClassResponse() {
    setState(() {
      _isRecording = true;
      _hasResult = false;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final random = Random();
      
      final wellUnderstood = 60 + random.nextInt(31); 
      final needsPractice = 8 + random.nextInt(18); 
      final needsReteach = 100 - wellUnderstood - needsPractice;

      setState(() {
        _isRecording = false;
        _hasResult = true;
        _wellUnderstoodPct = wellUnderstood;
        _needsPracticePct = needsPractice;
        _needsReteachPct = needsReteach;
        _sessionResults.add(wellUnderstood);
        _progressController.forward(from: 0.0);
      });
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = -1;
        _hasResult = false;
      });
    } else {
      setState(() {
        _sessionComplete = true;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = -1;
        _hasResult = false;
      });
    }
  }

  void _startNewSession() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswer = -1;
      _hasResult = false;
      _sessionResults.clear();
      _sessionComplete = false;
    });
  }

  String _getRecommendation(int score) {
    if (score >= 80) {
      return 'Excellent! Move to the next topic. Give 2-min revision in Mundari before proceeding.';
    } else if (score >= 60) {
      return 'Moderate understanding. Repeat the visual demonstration once more using tribal language.';
    } else {
      return 'Low comprehension detected. Break into small groups and re-teach using local language examples.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: isDesktop
            ? null
            : AppBar(
                title: Text(
                  'Learning Pulse',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                ),
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop) const VernexaDesktopSidebar(currentIndex: 3),
              Expanded(
                child: _sessionComplete ? _buildSessionSummary() : _buildActiveSession(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isDesktop ? null : const VernexaBottomNav(currentIndex: 3),
      ),
    );
  }

  Widget _buildActiveSession() {
    final question = _questions[_currentQuestionIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: deepPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressDots(),
          const SizedBox(height: 32),
          Text(
            question.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (question.visualAid != null) ...[
            const SizedBox(height: 24),
            question.visualAid!,
          ],
          const SizedBox(height: 32),
          _buildChoices(question),
          const SizedBox(height: 48),
          if (_isRecording)
            const Center(child: CircularProgressIndicator())
          else if (!_hasResult)
            ElevatedButton(
              onPressed: _recordClassResponse,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Record Class Response',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            _buildResultsSection(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: const Text('Previous'),
              ),
              if (_hasResult)
                ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: Text(_currentQuestionIndex == _questions.length - 1
                      ? 'Finish Session'
                      : 'Next Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _questions.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentQuestionIndex
                ? primaryColor
                : (index < _currentQuestionIndex
                    ? primaryColor.withOpacity(0.5)
                    : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildChoices(PulseQuestion question) {
    return Column(
      children: List.generate(
        question.choices.length,
        (index) {
          final isSelected = _selectedAnswer == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: _hasResult
                  ? null
                  : () {
                      setState(() {
                        _selectedAnswer = index;
                      });
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey.shade400,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        question.choices[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildResultsSection() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Comprehension',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 360;
                  final indicator = Center(
                    child: SizedBox(
                      width: isSmall ? 96 : 110,
                      height: isSmall ? 96 : 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (_wellUnderstoodPct / 100) * _progressAnimation.value,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
                          ),
                          Text(
                            '${(_wellUnderstoodPct * _progressAnimation.value).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isSmall ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final stats = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatBar('Well Understood', _wellUnderstoodPct, Colors.green),
                      const SizedBox(height: 10),
                      _buildStatBar('Needs Practice', _needsPracticePct, Colors.amber),
                      const SizedBox(height: 10),
                      _buildStatBar('Needs Re-teaching', _needsReteachPct, Colors.red),
                    ],
                  );

                  if (isSmall) {
                    return Column(
                      children: [
                        indicator,
                        const SizedBox(height: 18),
                        stats,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      indicator,
                      const SizedBox(width: 18),
                      Expanded(child: stats),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                '${(32 * _wellUnderstoodPct / 100).round()} of 32 students understood',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Recommendation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRecommendation(_wellUnderstoodPct),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${(percentage * _progressAnimation.value).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (percentage / 100) * _progressAnimation.value,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSessionSummary() {
    final double averageScore = _sessionResults.isEmpty
        ? 0
        : _sessionResults.reduce((a, b) => a + b) / _sessionResults.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(
            'Session Complete',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Class Understanding',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${averageScore.toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: averageScore >= 80
                      ? Colors.green
                      : averageScore >= 60
                          ? Colors.amber
                          : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Question Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_questions.length, (index) {
            final score = index < _sessionResults.length ? _sessionResults[index] : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}: ${_questions[index].text}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: score >= 80
                              ? Colors.green
                              : score >= 60
                                  ? Colors.amber
                                  : Colors.red,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$score%',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startNewSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start New Session',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
