# Anchor Toast ⚓

A Flutter package for displaying contextual toasts anchored to widgets with smart positioning and smooth animations.

## Features

- 🎯 **Smart Positioning**: Automatically determines whether to show toasts above or below the anchor widget based on available space
- 🎨 **Smooth Animations**: Beautiful scale and opacity animations for toast appearance and disappearance
- ⏰ **Auto-dismiss**: Toasts automatically disappear after a specified duration
- 🎮 **Manual Control**: Dismiss toasts manually using the controller
- 🧩 **Simple API**: Easy-to-use widget wrapper and extension methods
- 📱 **Overlay Support**: Uses Flutter's Overlay system for proper z-index handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  anchor_toast: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Method 1: Using AnchorToast Widget with Controller

```dart
import 'package:anchor_toast/anchor_toast.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final AnchorToastController _controller = AnchorToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnchorToast(
      controller: _controller,
      child: ElevatedButton(
        onPressed: () {
          _controller.showToast(
            context: context,
            toast: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hello World!',
                style: TextStyle(color: Colors.white),
              ),
            ),
            duration: Duration(seconds: 2),
          );
        },
        child: Text('Show Toast'),
      ),
    );
  }
}
```

### Method 2: Using Context Extension (Simpler)

```dart
import 'package:anchor_toast/anchor_toast.dart';

Builder(
  builder: (context) => ElevatedButton(
    onPressed: () {
      context.showAnchorToast(
        toast: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Success!',
            style: TextStyle(color: Colors.white),
          ),
        ),
        duration: Duration(seconds: 3),
      );
    },
    child: Text('Show Toast'),
  ),
)
```

### Method 3: Manual Controller Usage

```dart
final controller = AnchorToastController();

// Show toast
controller.showToast(
  context: context,
  toast: YourCustomToastWidget(),
  duration: Duration(seconds: 2),
  offset: 12.0, // Optional: custom offset from anchor
);

// Manually dismiss
controller.dismiss();

// Don't forget to dispose
controller.dispose();
```

## API Reference

### AnchorToastController

The main controller class for managing toast displays.

#### Methods

- `showToast({required BuildContext context, required Widget toast, required Duration duration, double offset = 8.0})` - Shows a toast anchored to the provided context
- `dismiss()` - Manually dismisses the currently shown toast
- `dispose()` - Disposes the controller and cleans up resources

#### Parameters

- `context` - The build context of the anchor widget
- `toast` - The widget to display as toast
- `duration` - How long to show the toast before auto-dismissing
- `offset` - Additional offset from the anchor (default: 8.0)

### AnchorToast Widget

A wrapper widget that provides toast functionality to its child.

```dart
AnchorToast({
  Key? key,
  required Widget child,
  AnchorToastController? controller, // Optional: provide your own controller
})
```

### Extension Methods

#### BuildContext.showAnchorToast

A convenient extension method for showing toasts directly from any BuildContext.

```dart
context.showAnchorToast({
  required Widget toast,
  required Duration duration,
  double offset = 8.0,
});
```

## Customization Examples

### Custom Toast Styles

```dart
// Success toast
context.showAnchorToast(
  toast: Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.green,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, color: Colors.white),
        SizedBox(width: 8),
        Text('Success!', style: TextStyle(color: Colors.white)),
      ],
    ),
  ),
  duration: Duration(seconds: 2),
);

// Error toast
context.showAnchorToast(
  toast: Material(
    color: Colors.red,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'Error occurred!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  ),
  duration: Duration(seconds: 3),
);
```

### Custom Positioning

The package automatically determines the best position (above or below) based on available space, but you can influence this by adjusting the `offset` parameter:

```dart
context.showAnchorToast(
  toast: YourToastWidget(),
  duration: Duration(seconds: 2),
  offset: 16.0, // Larger offset for more spacing
);
```

## Smart Positioning

The package automatically calculates available space above and below the anchor widget and chooses the optimal position:

- If there's more space below and enough room (> 100px), shows below
- If there's more space above, shows above
- Gracefully handles edge cases near screen boundaries

## Animation Details

Toasts use a sophisticated multi-layered animation system for the smoothest possible user experience:

- **Scale Animation**: Uses `Curves.easeOutCubic` optimized for high refresh rate displays
- **Opacity Animation**: Staggered timing with `Interval(0.0, 0.8)` for better visual layering  
- **Slide Animation**: Subtle slide motion with `Interval(0.1, 1.0)` for natural feel
- **Duration**: 400ms for smooth, polished animations
- **Performance**: RepaintBoundary widgets isolate repaints for 60/120fps performance
- **Haptic Feedback**: Optional light haptic feedback for enhanced UX

## Best Practices

1. **Always dispose controllers**: Make sure to call `dispose()` on controllers in your widget's `dispose()` method
2. **Use context extension for simple cases**: For one-off toasts, use `context.showAnchorToast()`
3. **Reuse controllers**: For multiple toasts from the same widget, reuse the same controller
4. **Keep toast content concise**: Toasts work best with short, clear messages
5. **Consider accessibility**: Ensure toast content is readable and accessible

## Troubleshooting

### Toast not appearing
- Make sure the context has access to an Overlay (usually provided by MaterialApp or WidgetsApp)
- Verify that the context belongs to a widget that's currently mounted

### Toast positioning issues
- The package calculates position based on the anchor widget's render box
- Make sure the anchor widget has been laid out before showing the toast

### Memory leaks
- Always dispose of AnchorToastController instances
- The context extension method creates and disposes controllers automatically

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
