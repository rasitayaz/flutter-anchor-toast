import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A controller for managing toast displays anchored to widgets.
class AnchorToastController {
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Timer? _autoHideTimer;
  bool _isDisposed = false;
  bool _isTemporary = false; // For extension method usage

  /// Shows a toast anchored to the provided context.
  ///
  /// [context] - The build context of the anchor widget
  /// [toast] - The widget to display as toast
  /// [duration] - How long to show the toast before auto-dismissing
  /// [offset] - Additional offset from the anchor (default: 8.0)
  /// [enableHapticFeedback] - Whether to provide haptic feedback (default: true)
  void showToast({
    required BuildContext context,
    required Widget toast,
    required Duration duration,
    double offset = 8.0,
    bool enableHapticFeedback = true,
  }) {
    if (_isDisposed) return;

    // Provide haptic feedback for better UX
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Dismiss any existing toast first
    dismiss();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Get screen size for positioning calculations
    final screenSize = MediaQuery.of(context).size;
    final availableSpaceBelow = screenSize.height - position.dy - size.height;
    final availableSpaceAbove = position.dy;

    // Determine if toast should appear above or below
    final showAbove =
        availableSpaceBelow < 100 && availableSpaceAbove > availableSpaceBelow;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        position: position,
        anchorSize: size,
        toast: toast,
        showAbove: showAbove,
        offset: offset,
        onAnimationComplete: (controller) {
          if (!_isDisposed) {
            _animationController = controller;
          }
        },
        onDispose: () {
          // Clean up when the toast widget disposes itself
          _animationController = null;
          // If this is a temporary controller (from extension), dispose it
          if (_isTemporary && !_isDisposed) {
            dispose();
          }
        },
      ),
    );

    overlay.insert(_overlayEntry!);

    // Auto-dismiss after duration
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(duration, () {
      if (!_isDisposed) {
        dismiss();
      }
    });
  }

  /// Manually dismisses the currently shown toast.
  void dismiss() {
    if (_isDisposed) return;

    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    if (_overlayEntry != null && _animationController != null) {
      // Only animate if controller is in a valid state
      if (_animationController!.status == AnimationStatus.completed ||
          _animationController!.status == AnimationStatus.forward) {
        try {
          _animationController!.reverse().then((_) {
            if (!_isDisposed && _overlayEntry != null) {
              _overlayEntry!.remove();
              _overlayEntry = null;
            }
          });
        } catch (e) {
          // Animation controller might be disposed
          _overlayEntry?.remove();
          _overlayEntry = null;
        }
      } else {
        // If animation isn't complete, remove immediately
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    }
  }

  /// Disposes the controller and cleans up resources.
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController = null;
  }
}

/// Internal widget that handles the toast display and animation.
class _ToastWidget extends StatefulWidget {
  final Offset position;
  final Size anchorSize;
  final Widget toast;
  final bool showAbove;
  final double offset;
  final Function(AnimationController) onAnimationComplete;
  final VoidCallback onDispose;

  const _ToastWidget({
    required this.position,
    required this.anchorSize,
    required this.toast,
    required this.showAbove,
    required this.offset,
    required this.onAnimationComplete,
    required this.onDispose,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Use consistent curves optimized for high refresh rate displays
    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves
          .easeOutCubic, // Smoother than easeOutBack for high refresh rates
      reverseCurve: Curves.easeInCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curve);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Subtle slide animation for more natural feel
    _slideAnimation =
        Tween<Offset>(
          begin: widget.showAbove
              ? const Offset(0, 0.2)
              : const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    widget.onAnimationComplete(_animationController);

    // Start animation on next frame for optimal performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    widget.onDispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double toastY = widget.showAbove
        ? widget.position.dy - widget.offset
        : widget.position.dy + widget.anchorSize.height + widget.offset;

    return Positioned(
      left: widget.position.dx + (widget.anchorSize.width / 2),
      top: toastY,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FractionalTranslation(
              translation: Offset(
                -0.5, // Center horizontally
                widget.showAbove ? -1.0 : 0.0, // Adjust vertical positioning
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: widget.showAbove
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: RepaintBoundary(
                      child: Material(
                        color: Colors.transparent,
                        child: widget.toast,
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
}

/// A widget that wraps an anchor widget and provides toast functionality.
class AnchorToast extends StatefulWidget {
  final Widget child;
  final AnchorToastController? controller;

  const AnchorToast({super.key, required this.child, this.controller});

  @override
  State<AnchorToast> createState() => _AnchorToastState();
}

class _AnchorToastState extends State<AnchorToast> {
  late AnchorToastController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AnchorToastController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Gets the controller for this AnchorToast widget.
  AnchorToastController get controller => _controller;
}

/// Extension to make it easier to show toasts from any widget.
extension AnchorToastExtension on BuildContext {
  /// Shows a toast anchored to this context.
  void showAnchorToast({
    required Widget toast,
    required Duration duration,
    double offset = 8.0,
    bool enableHapticFeedback = true,
  }) {
    // Create a temporary controller that will auto-dispose
    final controller = AnchorToastController().._isTemporary = true;
    controller.showToast(
      context: this,
      toast: toast,
      duration: duration,
      offset: offset,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
}
