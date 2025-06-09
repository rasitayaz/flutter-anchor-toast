import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A controller for managing toast displays anchored to widgets.
class AnchorToastController {
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Timer? _autoHideTimer;
  bool _isDisposed = false;
  BuildContext? _anchorContext;
  StreamSubscription<void>? _scrollSubscription;
  ValueNotifier<Offset>? _positionNotifier;

  /// Shows a toast anchored to the registered context.
  ///
  /// [toast] - The widget to display as toast
  /// [duration] - How long to show the toast before auto-dismissing
  /// [offset] - Additional offset from the anchor (default: 8.0)
  /// [enableHapticFeedback] - Whether to provide haptic feedback (default: true)
  /// [showAbove] - Override automatic positioning: true for above, false for below, null for automatic
  void showToast({
    required Widget toast,
    required Duration duration,
    double offset = 8.0,
    bool enableHapticFeedback = true,
    bool? showAbove,
  }) {
    if (_isDisposed || _anchorContext == null || !_anchorContext!.mounted) {
      return;
    }

    final context = _anchorContext!;

    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _immediateCleanup();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;

    // Calculate available space considering both padding and view insets (keyboard, etc.)
    final availableSpaceBelow =
        screenSize.height -
        position.dy -
        size.height -
        padding.bottom -
        viewInsets.bottom;
    final availableSpaceAbove = position.dy - padding.top - viewInsets.top;

    // Check if the anchor is below the vertical center of the visible screen area
    final visibleHeight =
        screenSize.height - viewInsets.top - viewInsets.bottom;
    final visibleTop = viewInsets.top;
    final anchorCenterY = position.dy + (size.height / 2);
    final visibleCenterY = visibleTop + (visibleHeight / 2);
    final anchorBelowCenter = anchorCenterY > visibleCenterY;

    // Use preferred position if specified, otherwise use automatic positioning
    final shouldShowAbove =
        showAbove ??
        (anchorBelowCenter ||
            (availableSpaceBelow < 100 &&
                availableSpaceAbove > availableSpaceBelow));

    // Calculate proper positioning for the toast
    const double screenPadding = 16.0;
    final double anchorCenterX = position.dx + (size.width / 2);

    // Adjust horizontal position to keep toast on screen
    double adjustedX = anchorCenterX;
    // We'll estimate a reasonable max toast width for positioning
    final double maxToastWidth = screenSize.width - (screenPadding * 2);
    final double halfToastWidth = maxToastWidth / 2;

    if (anchorCenterX - halfToastWidth < screenPadding) {
      adjustedX = screenPadding + halfToastWidth;
    } else if (anchorCenterX + halfToastWidth >
        screenSize.width - screenPadding) {
      adjustedX = screenSize.width - screenPadding - halfToastWidth;
    }

    final adjustedPosition = Offset(adjustedX - (size.width / 2), position.dy);

    // Create position notifier for scroll tracking
    _positionNotifier?.dispose();
    _positionNotifier = ValueNotifier<Offset>(adjustedPosition);

    // Set up scroll listening
    _setupScrollListener();

    OverlayEntry? currentOverlay;
    AnimationController? currentController;
    Timer? currentTimer;

    currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        anchorContext: _anchorContext!,
        anchorSize: size,
        toast: toast,
        showAbove: shouldShowAbove,
        offset: offset,
        screenSize: screenSize,
        screenPadding: padding,
        positionNotifier: _positionNotifier!,
        onAnimationComplete: (controller) {
          currentController = controller;
          if (currentOverlay == _overlayEntry && !_isDisposed) {
            _animationController = controller;
          }
        },
        onDispose: () {
          currentController = null;
          if (currentOverlay == _overlayEntry) {
            _animationController = null;
          }
        },
      ),
    );

    _overlayEntry = currentOverlay;
    overlay.insert(_overlayEntry!);

    _autoHideTimer?.cancel();
    currentTimer = Timer(duration, () {
      if (currentOverlay == _overlayEntry && !_isDisposed) {
        _dismissWithController(currentOverlay, currentController);
      }
    });
    _autoHideTimer = currentTimer;
  }

  /// Manually dismisses the currently shown toast.
  void dismiss() {
    if (_isDisposed) return;

    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    if (_overlayEntry != null) {
      if (_animationController != null) {
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
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
        } else {
          _overlayEntry?.remove();
          _overlayEntry = null;
        }
      } else {
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

    // Clean up scroll listener
    if (_anchorContext != null && _anchorContext!.mounted) {
      final scrollable = Scrollable.maybeOf(_anchorContext!);
      if (scrollable != null) {
        scrollable.position.removeListener(_updateToastPosition);
      }
    }
    _scrollSubscription?.cancel();
    _scrollSubscription = null;
    _positionNotifier?.dispose();
    _positionNotifier = null;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController = null;
    _anchorContext = null;
  }

  /// Registers the anchor context with this controller.
  /// This method is called internally by the AnchorToast widget.
  void _registerContext(BuildContext context) {
    _anchorContext = context;
  }

  /// Unregisters the anchor context from this controller.
  /// This method is called internally by the AnchorToast widget.
  void _unregisterContext() {
    _anchorContext = null;
  }

  /// Immediately cleans up any existing toast without animation.
  /// Used internally to prevent conflicts during rapid successive calls.
  void _immediateCleanup() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    // Clean up scroll listener
    if (_anchorContext != null && _anchorContext!.mounted) {
      final scrollable = Scrollable.maybeOf(_anchorContext!);
      if (scrollable != null) {
        scrollable.position.removeListener(_updateToastPosition);
      }
    }
    _scrollSubscription?.cancel();
    _scrollSubscription = null;
    _positionNotifier?.dispose();
    _positionNotifier = null;

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  /// Dismisses a specific toast with its animation controller.
  /// Used internally to handle auto-dismiss with the correct controller.
  void _dismissWithController(
    OverlayEntry? overlay,
    AnimationController? controller,
  ) {
    if (_isDisposed || overlay == null || overlay != _overlayEntry) return;

    if (controller != null &&
        (controller.status == AnimationStatus.completed ||
            controller.status == AnimationStatus.forward)) {
      try {
        controller.reverse().then((_) {
          if (!_isDisposed && overlay == _overlayEntry) {
            overlay.remove();
            _overlayEntry = null;
          }
        });
        return;
      } catch (e) {
        // Fall through to immediate removal
      }
    }

    // Immediate removal for cases where animation is not available or failed
    overlay.remove();
    _overlayEntry = null;
  }

  /// Sets up scroll listener to track position changes
  void _setupScrollListener() {
    _scrollSubscription?.cancel();

    if (_anchorContext == null || !_anchorContext!.mounted) return;

    // Find the nearest scrollable
    final scrollable = Scrollable.maybeOf(_anchorContext!);
    if (scrollable != null) {
      scrollable.position.addListener(_updateToastPosition);
    }
  }

  /// Updates the toast position based on current anchor position
  void _updateToastPosition() {
    if (_isDisposed ||
        _anchorContext == null ||
        !_anchorContext!.mounted ||
        _positionNotifier == null) {
      return;
    }

    try {
      final renderBox = _anchorContext!.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(_anchorContext!).size;

      // Calculate proper positioning for the toast (same logic as in showToast)
      const double screenPadding = 16.0;
      final double anchorCenterX = position.dx + (size.width / 2);

      // Adjust horizontal position to keep toast on screen
      double adjustedX = anchorCenterX;
      final double maxToastWidth = screenSize.width - (screenPadding * 2);
      final double halfToastWidth = maxToastWidth / 2;

      if (anchorCenterX - halfToastWidth < screenPadding) {
        adjustedX = screenPadding + halfToastWidth;
      } else if (anchorCenterX + halfToastWidth >
          screenSize.width - screenPadding) {
        adjustedX = screenSize.width - screenPadding - halfToastWidth;
      }

      final adjustedPosition = Offset(
        adjustedX - (size.width / 2),
        position.dy,
      );
      _positionNotifier!.value = adjustedPosition;
    } catch (e) {
      // Silently handle errors that might occur during position updates
    }
  }
}

/// Internal widget that handles the toast display and animation.
class _ToastWidget extends StatefulWidget {
  final BuildContext anchorContext;
  final Size anchorSize;
  final Widget toast;
  final bool showAbove;
  final double offset;
  final Size screenSize;
  final EdgeInsets screenPadding;
  final ValueNotifier<Offset> positionNotifier;
  final Function(AnimationController) onAnimationComplete;
  final VoidCallback onDispose;

  const _ToastWidget({
    required this.anchorContext,
    required this.anchorSize,
    required this.toast,
    required this.showAbove,
    required this.offset,
    required this.screenSize,
    required this.screenPadding,
    required this.positionNotifier,
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: const Threshold(0.0),
      ),
    );

    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween(
          begin: widget.showAbove
              ? const Offset(0, 0.2)
              : const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
            reverseCurve: const Threshold(0.0),
          ),
        );

    widget.onAnimationComplete(_animationController);

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
    return ValueListenableBuilder<Offset>(
      valueListenable: widget.positionNotifier,
      builder: (context, position, child) {
        final double toastY = widget.showAbove
            ? position.dy - widget.offset
            : position.dy + widget.anchorSize.height + widget.offset;

        // Calculate horizontal positioning with screen boundary constraints
        const double screenPadding = 16.0; // Minimum padding from screen edges
        final double anchorCenterX =
            position.dx + (widget.anchorSize.width / 2);

        return Positioned(
          left: anchorCenterX,
          top: toastY,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.screenSize.width - (screenPadding * 2),
                  ),
                  child: FractionalTranslation(
                    translation: Offset(-0.5, widget.showAbove ? -1.0 : 0.0),
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
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A widget that wraps an anchor widget and provides toast functionality.
class AnchorToast extends StatefulWidget {
  final Widget child;
  final AnchorToastController controller;

  const AnchorToast({super.key, required this.child, required this.controller});

  @override
  State<AnchorToast> createState() => _AnchorToastState();
}

class _AnchorToastState extends State<AnchorToast> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.controller._unregisterContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Register the context with the controller every time we build
    widget.controller._registerContext(context);
    return widget.child;
  }

  /// Gets the controller for this AnchorToast widget.
  AnchorToastController get controller => widget.controller;
}
