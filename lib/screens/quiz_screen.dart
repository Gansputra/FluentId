import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocab.dart';
import '../services/vocab_service.dart';
import '../services/progress_service.dart';
import '../core/app_theme.dart';
import '../widgets/quiz_option_card.dart';

class QuizScreen extends StatefulWidget {
  final String levelName;
  final String category;
  final String fileName;
  final int? startIndex;
  final int? endIndex;
  
  const QuizScreen({
    super.key, 
    required this.levelName, 
    required this.category,
    required this.fileName,
    this.startIndex,
    this.endIndex,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final VocabService _vocabService = VocabService();
  final ProgressService _progressService = ProgressService();
  late FlutterTts _flutterTts;
  late ConfettiController _confettiController;
  
  late Future<List<Vocab>> _vocabFuture;
  Vocab? _currentVocab;
  List<String> _options = [];
  String? _selectedOption;
  bool? _isCorrect;
  final Set<String> _masteredInSession = {};
  
  int _currentIndex = 0;
  int _totalQuiz = 0;
  bool _isIncorrect = false; // Add this to track if user got it wrong at least once

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _flutterTts = FlutterTts();
    _initTts();
    
    _vocabFuture = _vocabService.loadVocabularies(widget.fileName).then((list) {
      if (widget.startIndex != null && widget.endIndex != null) {
        int start = widget.startIndex!.clamp(0, list.length);
        int end = (widget.endIndex! + 1).clamp(0, list.length);
        var sublist = list.sublist(start, end);
        _totalQuiz = sublist.length;
        return sublist;
      }
      _totalQuiz = list.length;
      return list;
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _setupQuizData(List<Vocab> allVocabs, {int? index}) {
    if (allVocabs.isEmpty) return;
    
    // use specified index or current
    int targetIndex = index ?? _currentIndex;
    if (targetIndex >= allVocabs.length) targetIndex = 0;
    if (targetIndex < 0) targetIndex = 0;

    final correctVocab = allVocabs[targetIndex];
    
    List<String> wrongMeanings = allVocabs
        .where((v) => v.id != correctVocab.id)
        .map((v) => v.meaning)
        .toSet().toList();
    wrongMeanings.shuffle();
    
    List<String> quizOptions = [correctVocab.meaning];
    quizOptions.addAll(wrongMeanings.take(3));
    quizOptions.shuffle();

    _currentIndex = targetIndex;
    _currentVocab = correctVocab;
    _options = quizOptions;
    _selectedOption = null;
    _isCorrect = null;
    _isIncorrect = false;
  }

  void _checkAnswer(String selected, List<Vocab> allVocabs) {
    if (_isCorrect == true) return; // Already answered correctly

    bool correct = selected == _currentVocab!.meaning;
    
    setState(() {
      _selectedOption = selected;
      _isCorrect = correct;
      if (!correct) _isIncorrect = true;
    });

    if (correct) {
      _confettiController.play();
      _masteredInSession.add(_currentVocab!.id);
      _progressService.masterWord(widget.category, _currentVocab!.id);
      
      // Auto move is nice, but we have buttons now. 
      // Let's keep a short auto-move if it's not the last one
      if (_currentIndex < allVocabs.length - 1) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _isCorrect == true && _selectedOption == selected) {
            _nextQuestion(allVocabs);
          }
        });
      } else if (_masteredInSession.length >= allVocabs.length) {
         Future.delayed(const Duration(milliseconds: 1500), () => _showCompletionDialog());
      }
    }
  }

  void _nextQuestion(List<Vocab> allVocabs) {
    if (_currentIndex < allVocabs.length - 1) {
      setState(() {
        _setupQuizData(allVocabs, index: _currentIndex + 1);
      });
    } else {
      if (_masteredInSession.length >= allVocabs.length) {
        _showCompletionDialog();
      }
    }
  }

  void _previousQuestion(List<Vocab> allVocabs) {
    if (_currentIndex > 0) {
      setState(() {
        _setupQuizData(allVocabs, index: _currentIndex - 1);
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Level Complete! 🎉"),
        content: const Text("You have mastered all words in this level. Great job!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: FutureBuilder<List<Vocab>>(
          future: _vocabFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No data found"));
            }

            final allVocabs = snapshot.data!;
            if (_currentVocab == null) {
              _setupQuizData(allVocabs);
            }

            if (_currentVocab == null) return const SizedBox();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildHeader(allVocabs),
                    const SizedBox(height: 48),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                           return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                        },
                        child: Column(
                          key: ValueKey<String>(_currentVocab!.id),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "What is the meaning of:",
                              style: AppStyles.subtitle.copyWith(letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_currentVocab!.word, style: AppStyles.h1.copyWith(fontSize: 40)),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () => _flutterTts.speak(_currentVocab!.word),
                                    child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            ..._options.map((opt) => QuizOptionCard(
                              option: opt,
                              isSelected: _selectedOption == opt,
                              isCorrect: _selectedOption == opt ? _isCorrect : null,
                              onTap: () => _checkAnswer(opt, allVocabs),
                            )),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          label: "Previous",
                          onPressed: _currentIndex > 0 ? () => _previousQuestion(allVocabs) : null,
                        ),
                        _buildNavButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          label: "Next",
                          onPressed: _currentIndex < allVocabs.length - 1 ? () => _nextQuestion(allVocabs) : null,
                          isNext: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<Vocab> allVocabs) {
    double progressValue = _masteredInSession.length / allVocabs.length;
    
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.levelName, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    "${_masteredInSession.length}/${allVocabs.length}",
                    style: AppStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCorrect == true 
                        ? Colors.green 
                        : (_isCorrect == false && _selectedOption != null ? Colors.red : AppColors.primary),
                  ),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isNext = false,
  }) {
    bool isDisabled = onPressed == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isNext && !isDisabled ? AppColors.primaryGradient : null,
          color: !isNext ? Colors.white : (isDisabled ? Colors.grey.shade300 : null),
          border: !isNext 
            ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5)
            : null,
          boxShadow: isNext && !isDisabled ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) Icon(icon, size: 20, color: AppColors.primary),
                  if (!isNext) const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isNext ? Colors.white : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isNext) const SizedBox(width: 12),
                  if (isNext) const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
