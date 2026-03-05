import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/vocab.dart';
import '../services/vocab_service.dart';
import '../widgets/interactive_particle_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VocabService _vocabService = VocabService();
  late Future<List<Vocab>> _vocabFuture;
  
  Vocab? _currentVocab;
  List<String> _options = [];
  String? _selectedOption;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _vocabFuture = _vocabService.loadVocabularies();
  }

  // Fungsi internal untuk menghitung data quiz tanpa setState
  void _setupQuizData(List<Vocab> allVocabs) {
    if (allVocabs.length < 4) return;

    final random = Random();
    final correctVocab = allVocabs[random.nextInt(allVocabs.length)];
    
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

    setState(() {
      _selectedOption = selected;
      _isCorrect = selected == _currentVocab!.meaning;
    });
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
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Apa arti dari kata ini?",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentVocab!.word,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 40),
                          ..._options.map((option) => _buildOptionButton(option)),
                          if (_selectedOption != null) ...[
                            const SizedBox(height: 24),
                            Divider(color: Colors.deepPurple.withOpacity(0.2)),
                            const SizedBox(height: 24),
                            Icon(
                              _isCorrect! ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect! ? Colors.green : Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCorrect! ? "Benar sekali!" : "Oops, kurang tepat!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isCorrect! ? Colors.green : Colors.red,
                              ),
                            ),
                            if (!_isCorrect!) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Jawaban benar: ${_currentVocab!.meaning}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _generateNewQuiz(allVocabs),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 5,
                                shadowColor: Colors.deepPurple.withOpacity(0.5),
                              ),
                              child: const Text("Pertanyaan Selanjutnya", style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = _selectedOption == option;
    bool isCorrectOption = option == _currentVocab?.meaning;
    
    Color buttonColor = Colors.white.withOpacity(0.4);
    if (_selectedOption != null) {
      if (isCorrectOption) {
        buttonColor = Colors.green.shade100.withOpacity(0.6);
      } else if (isSelected) {
        buttonColor = Colors.red.shade100.withOpacity(0.6);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: OutlinedButton(
              onPressed: () => _checkAnswer(option),
              style: OutlinedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isSelected 
                      ? (_isCorrect! ? Colors.green : Colors.red) 
                      : (_selectedOption != null && isCorrectOption ? Colors.green : Colors.deepPurple.shade200),
                  width: isSelected || (_selectedOption != null && isCorrectOption) ? 2 : 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
