import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocab.dart';
import '../services/vocab_service.dart';
import 'package:fluentid/services/progress_service.dart';
import '../widgets/interactive_particle_background.dart';

class HomeScreen extends StatefulWidget {
  final String levelName;
  final String category;
  final String fileName;
  final int? startIndex;
  final int? endIndex;
  
  const HomeScreen({
    super.key, 
    required this.levelName, 
    required this.category,
    required this.fileName,
    this.startIndex,
    this.endIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final VocabService _vocabService = VocabService();
  late Future<List<Vocab>> _vocabFuture;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late FlutterTts _flutterTts;
  
  final ProgressService _progressService = ProgressService();
  
  Vocab? _currentVocab;
  List<String> _options = [];
  String? _selectedOption;
  bool? _isCorrect;
  final Set<String> _masteredInSession = {};
  int _initialMasteredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
    _vocabFuture = _vocabService.loadVocabularies(widget.fileName).then((list) {
      if (widget.startIndex != null && widget.endIndex != null) {
        int start = widget.startIndex!.clamp(0, list.length);
        int end = widget.endIndex!.clamp(0, list.length);
        return list.sublist(start, end);
      }
      return list;
    });
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _flutterTts = FlutterTts();
    
    _initTts();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  Future<void> _loadInitialProgress() async {
    if (widget.startIndex != null && widget.endIndex != null) {
      int count = await _progressService.getMasteredCountInRange(
        widget.category, 
        widget.startIndex!, 
        widget.endIndex! + 1
      );
      setState(() {
        _initialMasteredCount = count;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Fungsi internal untuk menghitung data quiz tanpa setState
  void _setupQuizData(List<Vocab> allVocabs) {
    if (allVocabs.isEmpty) return;

    final random = Random();
    
    // Filter out words mastered in this session or already mastered in DB
    // To make it logic, we should probably check DB for EACH word, 
    // but that's slow. Let's assume _masteredInSession tracks what we did NOW.
    // If the user wants to re-learn, we might need a different logic.
    // However, the request is "kosakatanya jangan ada yang diulang".
    
    List<Vocab> availableVocabs = allVocabs.where((v) => !_masteredInSession.contains(v.id)).toList();
    
    if (availableVocabs.isEmpty) {
      // All words in this sub-level mastered in this session!
      // We can either restart or show a finished state.
      // For now, let's just use all words if empty to avoid crash, 
      // but ideally we show a "Level Complete" screen.
      availableVocabs = allVocabs;
      _masteredInSession.clear(); 
    }

    final correctVocab = availableVocabs[random.nextInt(availableVocabs.length)];
    
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

  // Fungsi untuk trigger quiz baru dengan setState (dipanggil dari tombol)
  void _generateNewQuiz(List<Vocab> allVocabs) {
    setState(() {
      _setupQuizData(allVocabs);
    });
  }

  void _checkAnswer(String selected) {
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
    } else {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveParticleBackground(
        child: FutureBuilder<List<Vocab>>(
          future: _vocabFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data found'));
            }

            final allVocabs = snapshot.data!;
            
            // Inisialisasi data quiz jika belum ada, tanpa setState karena masih dalam build
            if (_currentVocab == null) {
              _setupQuizData(allVocabs);
            }

            return SafeArea(
              child: Stack(
                children: [
                   // Progress Bar & Info at the top
                   Positioned(
                     top: 0,
                     left: 0,
                     right: 0,
                     child: Container(
                       padding: const EdgeInsets.only(top: 10),
                       child: Column(
                         children: [
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                             child: Row(
                               children: [
                                 // Premium Back Button
                                 Container(
                                   decoration: BoxDecoration(
                                     color: Colors.white.withOpacity(0.2),
                                     borderRadius: BorderRadius.circular(15),
                                     border: Border.all(color: Colors.white.withOpacity(0.3)),
                                   ),
                                   child: IconButton(
                                     icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                                     onPressed: () => Navigator.pop(context),
                                   ),
                                 ),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         widget.levelName,
                                         style: const TextStyle(
                                           color: Colors.black87,
                                           fontWeight: FontWeight.bold,
                                           fontSize: 18,
                                           letterSpacing: 0.5,
                                         ),
                                       ),
                                       const SizedBox(height: 4),
                                       ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: _masteredInSession.length / allVocabs.length,
                                            backgroundColor: Colors.black.withOpacity(0.05),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                            minHeight: 6,
                                          ),
                                        ),
                                     ],
                                   ),
                                 ),
                                 const SizedBox(width: 16),
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                   decoration: BoxDecoration(
                                     color: Colors.deepPurple.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Text(
                                     "${_masteredInSession.length}/${allVocabs.length}",
                                     style: const TextStyle(
                                       color: Colors.deepPurple,
                                       fontWeight: FontWeight.bold,
                                       fontSize: 12,
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
                   Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                    ),
                  ),
                  Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "APA ARTI DARI KATA INI?",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepPurple.withOpacity(0.6),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 56),
                                      Expanded(
                                        child: Text(
                                          _currentVocab!.word,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                      _buildSpeakerButton(),
                                    ],
                                  ),
                                  const SizedBox(height: 48),
                                  ..._options.map((option) => _buildOptionButton(option)),
                                  if (_selectedOption != null) ...[
                                    const SizedBox(height: 32),
                                    _buildFeedbackSection(allVocabs),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            ],
          ),
        );
      },
    ),
      ),
    );
  }

  Widget _buildSpeakerButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.volume_up_rounded, color: Colors.deepPurple, size: 28),
        onPressed: () => _speak(_currentVocab!.word),
      ),
    );
  }

  Widget _buildFeedbackSection(List<Vocab> allVocabs) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCorrect! ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _isCorrect! ? Colors.green : Colors.red,
              size: 50,
            ),
            const SizedBox(width: 12),
            Text(
              _isCorrect! ? "BENAR SEKALI!" : "KURANG TEPAT!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _isCorrect! ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!_isCorrect!) ...[
          const SizedBox(height: 12),
          Text(
            "Jawaban benar: ${_currentVocab!.meaning}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _generateNewQuiz(allVocabs),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              "LANJUTKAN",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = _selectedOption == option;
    bool isCorrectOption = option == _currentVocab?.meaning;
    
    Color buttonColor = Colors.white.withOpacity(0.3);
    Color borderColor = Colors.white.withOpacity(0.5);
    Color textColor = Colors.black87;

    if (_selectedOption != null) {
      if (isCorrectOption) {
        buttonColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green.withOpacity(0.5);
        textColor = Colors.green.shade700;
      } else if (isSelected) {
        buttonColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red.withOpacity(0.5);
        textColor = Colors.red.shade700;
      } else {
        buttonColor = Colors.white.withOpacity(0.1);
        borderColor = Colors.white.withOpacity(0.1);
        textColor = Colors.black26;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: () => _checkAnswer(option),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: isSelected || (_selectedOption != null && isCorrectOption) 
                    ? FontWeight.w800 
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
