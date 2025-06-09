import 'package:flutter/material.dart';
import 'package:anchor_toast/anchor_toast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor Toast Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AnchorToastController _controller = AnchorToastController();

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Anchor Toast Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Anchor Toast Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Example 1: Using AnchorToast widget with controller
            const Text('1. Using AnchorToast widget with controller:'),
            const SizedBox(height: 8),
            AnchorToast(
              controller: _controller,
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    _controller.showToast(
                      context: context,
                      toast: _buildToast('Hello from controller!', Colors.blue),
                      duration: const Duration(seconds: 3),
                    );
                  },
                  child: const Text('Show Controller Toast'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Example 2: Using context extension
            const Text('2. Using context extension:'),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  context.showAnchorToast(
                    toast: _buildToast('Extension method toast!', Colors.green),
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Show Extension Toast'),
              ),
            ),

            const SizedBox(height: 24),

            // Example 3: Different toast styles
            const Text('3. Different toast styles:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.showAnchorToast(
                          toast: _buildToast('Warning!', Colors.orange),
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: const Text('Warning'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.showAnchorToast(
                          toast: _buildToast('Error occurred!', Colors.red),
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: const Text('Error'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Animation Performance Test
            const Text('6. Animation Performance Test:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Show multiple toasts in sequence to test smoothness
                        for (int i = 1; i <= 3; i++) {
                          // Use a separate context check for each iteration
                          if (context.mounted) {
                            context.showAnchorToast(
                              toast: _buildToast('Toast $i', Colors.deepPurple),
                              duration: const Duration(milliseconds: 800),
                            );
                          }
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                        }
                      },
                      child: const Text('Rapid Fire'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.showAnchorToast(
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Smooth Animation!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          duration: const Duration(seconds: 3),
                        );
                      },
                      child: const Text('Fancy Toast'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Example 4: Custom toast widget
            const Text('4. Custom toast widget:'),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  context.showAnchorToast(
                    toast: Card(
                      color: Colors.purple,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Custom Toast!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    duration: const Duration(seconds: 3),
                  );
                },
                child: const Text('Show Custom Toast'),
              ),
            ),

            const SizedBox(height: 24),

            // Manual dismiss button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _controller.dismiss();
              },
              child: const Text('Dismiss Current Toast'),
            ),

            const SizedBox(height: 32),

            // Position test buttons
            const Text('5. Position testing (top and bottom):'),
            const SizedBox(height: 8),

            // Top button
            Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    context.showAnchorToast(
                      toast: _buildToast('Toast from top!', Colors.teal),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Text('Top Button'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom button
            Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    context.showAnchorToast(
                      toast: _buildToast('Toast from bottom!', Colors.indigo),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Text('Bottom Button'),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
