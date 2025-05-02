import 'package:flutter/material.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:skill_testing_platform/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'All';
  late Stream<List<Test>> _testsStream;
  final TextEditingController _passkeyController = TextEditingController();
  final String _correctPasskey = "1234"; // Hardcoded for simplicity

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _testsStream = _firestoreService.getTests(userId);
  }

  @override
  void dispose() {
    _passkeyController.dispose();
    super.dispose();
  }

  Future<bool> _promptPasskey(String action) async {
    bool passkeyMatches = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Passkey to $action', style: GoogleFonts.poppins()),
        content: TextField(
          controller: _passkeyController,
          decoration: InputDecoration(
            labelText: 'Passkey',
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            border: const UnderlineInputBorder(),
          ),
          obscureText: true,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (_passkeyController.text == _correctPasskey) {
                passkeyMatches = true;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect passkey')),
                );
              }
              _passkeyController.clear();
              Navigator.pop(context);
            },
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.blue)),
          ),
        ],
      ),
    );

    return passkeyMatches;
  }

  Future<void> _deleteTest(String testId) async {
    bool passkeyMatches = await _promptPasskey('Delete');
    if (!passkeyMatches) return;

    try {
      await _firestoreService.deleteTest(testId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete test: $e')),
      );
    }
  }

  Future<void> _editTest(Test test) async {
    bool passkeyMatches = await _promptPasskey('Edit');
    if (!passkeyMatches) return;

    Navigator.pushNamed(context, '/edit_test', arguments: test);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Skill Testing Platform',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    color: Colors.blue,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<List<Test>>(
                        stream: _testsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          final tests = snapshot.data ?? [];
                          final categories = ['All', ...tests.map((test) => test.category).toSet().where((category) => category != null).cast<String>()];
                          final filteredTests = _selectedCategory == 'All'
                              ? tests
                              : tests.where((test) => test.category == _selectedCategory).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Your Tests',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedCategory,
                                    items: categories.map((category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category, style: GoogleFonts.poppins()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (filteredTests.isEmpty)
                                Center(
                                  child: Text(
                                    'No tests available',
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              else
                                ...filteredTests.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final test = entry.value;
                                  return Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        test.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        test.description,
                                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                            onPressed: () => _editTest(test),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => _deleteTest(test.id),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/take_test',
                                          arguments: test,
                                        );
                                      },
                                    ),
                                  ).animate().fadeIn(duration: 600.ms, delay: (index * 100).ms);
                                }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/create_test');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Create New Test',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().scale(duration: 400.ms),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}