import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:anchor_toast/anchor_toast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Anchor Toast Demo', home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _infoController = AnchorToastController();
  final _warningController = AnchorToastController();
  final _errorController = AnchorToastController();
  final _rapidFireController = AnchorToastController();
  final _longController = AnchorToastController();
  final _customController = AnchorToastController();
  final _bottomController = AnchorToastController();

  Widget _buildToast(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _infoController.dispose();
    _warningController.dispose();
    _errorController.dispose();
    _rapidFireController.dispose();
    _longController.dispose();
    _customController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Anchor Toast ⚓')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 56,
          children: [
            AnchorToast(
              controller: _infoController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _infoController.showToast(
                    toast: _buildToast('Hello world!', Colors.blue),
                    duration: const Duration(seconds: 3),
                  );
                },
                child: const Text('Info'),
              ),
            ),

            AnchorToast(
              controller: _warningController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _warningController.showToast(
                    toast: _buildToast('Warning!', Colors.orange),
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Warning'),
              ),
            ),

            AnchorToast(
              controller: _errorController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _errorController.showToast(
                    toast: _buildToast('Error occurred!', Colors.red),
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Error'),
              ),
            ),

            AnchorToast(
              controller: _rapidFireController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  for (int i = 1; i <= 3; i++) {
                    if (context.mounted) {
                      _rapidFireController.showToast(
                        toast: _buildToast('Toast $i', Colors.deepPurple),
                        duration: const Duration(milliseconds: 800),
                      );
                    }
                    await Future.delayed(const Duration(milliseconds: 300));
                  }
                },
                child: const Text('Rapid Fire'),
              ),
            ),

            AnchorToast(
              controller: _longController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _longController.showToast(
                    toast: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Colors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Dolor ullamco commodo ea laborum non. Commodo duis fugiat tempor deserunt non incididunt magna et ullamco id. Deserunt reprehenderit ea occaecat proident mollit aliquip non.',
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    duration: const Duration(seconds: 3),
                  );
                },
                child: const Text('Long Message'),
              ),
            ),

            AnchorToast(
              controller: _customController,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _customController.showToast(
                    toast: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: ColoredBox(
                          color: Colors.blue.withValues(alpha: 0.2),
                          child: FlutterLogo(size: 200),
                        ),
                      ),
                    ),
                    duration: const Duration(seconds: 3),
                  );
                },
                child: const Text('Custom Widget'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnchorToast(
        controller: _bottomController,
        child: Container(
          color: Colors.indigo[100]!,
          padding: EdgeInsets.only(top: 8),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _bottomController.showToast(
                      toast: _buildToast(
                        'Toast from bottom navbar!',
                        Colors.indigo,
                      ),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Text('Bottom'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _infoController.dismiss();
                    _warningController.dismiss();
                    _errorController.dismiss();
                    _rapidFireController.dismiss();
                    _longController.dismiss();
                    _customController.dismiss();
                    _bottomController.dismiss();
                  },
                  child: const Text('Dismiss All Toasts'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
