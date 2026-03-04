import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vocab.dart';
import '../services/vocab_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VocabService _vocabService = VocabService();
  late Future<List<Vocab>> _vocabFuture;
  Vocab? _currentVocab;

  @override
  void initState() {
    super.initState();
    _vocabFuture = _vocabService.loadVocabularies();
  }

  void _refreshRandomVocab(List<Vocab> vocabs) {
    if (vocabs.isNotEmpty) {
      setState(() {
        _currentVocab = vocabs[Random().nextInt(vocabs.length)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Vocab>>(
        future: _vocabFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final vocabs = snapshot.data!;
          // Set initial random vocab once data is loaded
          _currentVocab ??= vocabs[Random().nextInt(vocabs.length)];

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentVocab!.word,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentVocab!.meaning,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                          ),
                          const Divider(height: 32),
                          const Text(
                            "Contoh Kalimat:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${_currentVocab!.example}"',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _refreshRandomVocab(vocabs),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Kata Acak Lainnya"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
