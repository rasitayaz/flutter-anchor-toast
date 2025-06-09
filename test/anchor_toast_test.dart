import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_toast/anchor_toast.dart';

void main() {
  group('AnchorToastController', () {
    testWidgets('should show and dismiss toast', (WidgetTester tester) async {
      final controller = AnchorToastController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.showToast(
                        context: context,
                        toast: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Test Toast',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        duration: const Duration(
                          seconds: 10,
                        ), // Long duration for testing
                      );
                    },
                    child: const Text('Show Toast'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show toast
      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      // Verify toast is shown
      expect(find.text('Test Toast'), findsOneWidget);

      // Wait for animation
      await tester.pump(const Duration(milliseconds: 300));

      // Manually dismiss
      controller.dismiss();
      await tester.pump(const Duration(milliseconds: 300));

      controller.dispose();
    });

    testWidgets('should auto-dismiss after duration', (
      WidgetTester tester,
    ) async {
      final controller = AnchorToastController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.showToast(
                        context: context,
                        toast: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Auto Dismiss Toast',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        duration: const Duration(milliseconds: 100),
                      );
                    },
                    child: const Text('Show Auto Toast'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show toast
      await tester.tap(find.text('Show Auto Toast'));
      await tester.pump();

      // Verify toast is shown
      expect(find.text('Auto Dismiss Toast'), findsOneWidget);

      // Wait for auto-dismiss + animation
      await tester.pump(const Duration(milliseconds: 500));

      controller.dispose();
    });
  });

  group('AnchorToast Widget', () {
    testWidgets('should wrap child widget', (WidgetTester tester) async {
      const testWidget = Text('Anchor Child');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnchorToast(child: testWidget)),
        ),
      );

      expect(find.text('Anchor Child'), findsOneWidget);
    });

    testWidgets('should work with custom controller', (
      WidgetTester tester,
    ) async {
      final controller = AnchorToastController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchorToast(
              controller: controller,
              child: const Text('Custom Controller'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Controller'), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnchorToastExtension', () {
    testWidgets('should show toast using extension', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.showAnchorToast(
                        toast: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Extension Toast',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        duration: const Duration(milliseconds: 100),
                      );
                    },
                    child: const Text('Show Extension Toast'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show toast
      await tester.tap(find.text('Show Extension Toast'));
      await tester.pump();

      // Verify toast is shown
      expect(find.text('Extension Toast'), findsOneWidget);

      // Wait for auto-dismiss
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
