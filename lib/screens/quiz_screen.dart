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

  void _setupQuizData(List<Vocab> allVocabs) {
    if (allVocabs.isEmpty) return;

    final random = Random();
    
    // Pick the next vocab based on session order or random from not mastered
    List<Vocab> pool = allVocabs.where((v) => !_masteredInSession.contains(v.id)).toList();
    
    if (pool.isEmpty) {
      // Level completed!
      return;
    }

    final correctVocab = pool[random.nextInt(pool.length)];
    
    List<String> wrongMeanings = allVocabs
        .where((v) => v.id != correctVocab.id)
        .map((v) => v.meaning)
        .toList();
    wrongMeanings.shuffle();
    
    List<String> quizOptions = [correctVocab.meaning];
    quizOptions.addAll(wrongMeanings.take(3));
    quizOptions.shuffle();

    _currentVocab = correctVocab;
    _options = quizOptions;
    _selectedOption = null;
    _isCorrect = null;
  }

  void _checkAnswer(String selected, List<Vocab> allVocabs) {
    if (_selectedOption != null) return;

    bool correct = selected == _currentVocab!.meaning;
    
    setState(() {
      _selectedOption = selected;
      _isCorrect = correct;
    });

    if (correct) {
      _confettiController.play();
      _masteredInSession.add(_currentVocab!.id);
      _progressService.masterWord(widget.category, _currentVocab!.id);
      
      // Auto move to next after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _nextQuestion(allVocabs);
        }
      });
    }
  }

  void _nextQuestion(List<Vocab> allVocabs) {
    if (_masteredInSession.length >= allVocabs.length) {
       _showCompletionDialog();
       return;
    }
    
    setState(() {
      _setupQuizData(allVocabs);
    });
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
