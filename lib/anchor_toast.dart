import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A controller for managing toast displays anchored to widgets.
class AnchorToastController {
  static final Set<AnchorToastController> _activeControllers =
      <AnchorToastController>{};

  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Timer? _autoHideTimer;
  bool _isDisposed = false;
  BuildContext? _anchorContext;
  StreamSubscription<void>? _scrollSubscription;
  ValueNotifier<Offset>? _positionNotifier;
  double _screenPadding = 16.0;
  EdgeInsets? _lastViewInsets;

  /// Constructor registers this controller in the global registry
  AnchorToastController() {
    _activeControllers.add(this);
  }

  /// Shows a toast anchored to the registered context.
  ///
  /// [toast] - The widget to display as toast
  /// [duration] - How long to show the toast before auto-dismissing
  /// [offset] - Additional offset from the anchor (default: 8.0)
  /// [enableHapticFeedback] - Whether to provide haptic feedback (default: true)
  /// [showAbove] - Override automatic positioning: true for above, false for below, null for automatic
  /// [screenPadding] - Minimum padding from screen edges (default: 16.0)
  void showToast({
    required Widget toast,
    required Duration duration,
    double offset = 8.0,
    bool enableHapticFeedback = true,
    bool? showAbove,
    double screenPadding = 16.0,
  }) {
    final anchorContext = _anchorContext;
    if (_isDisposed || anchorContext == null || !anchorContext.mounted) {
      return;
    }

    final context = anchorContext;
    _screenPadding = screenPadding;

    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _immediateCleanup();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

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

    // Calculate the proper position using the unified positioning logic
    final adjustedPosition = _calculateToastPosition(
      anchorContext: context,
      anchorSize: size,
      anchorPosition: position,
    );

    // Ensure position notifier exists and update its value
    final positionNotifier = _positionNotifier;
    if (positionNotifier != null) {
      positionNotifier.value = adjustedPosition;
    } else {
      _positionNotifier = ValueNotifier<Offset>(adjustedPosition);
    }

    // Set up scroll listening
    _setupScrollListener();
    _setupViewInsetsListener();

    OverlayEntry? currentOverlay;
    AnimationController? currentController;
    Timer? currentTimer;

    currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        anchorContext: anchorContext,
        anchorSize: size,
        toast: toast,
        showAbove: shouldShowAbove,
        offset: offset,
        screenSize: screenSize,
        screenPadding: EdgeInsets.all(screenPadding),
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
    overlay.insert(currentOverlay);

    final autoHideTimer = _autoHideTimer;
    autoHideTimer?.cancel();
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

    final autoHideTimer = _autoHideTimer;
    autoHideTimer?.cancel();
    _autoHideTimer = null;

    final overlayEntry = _overlayEntry;
    if (overlayEntry != null) {
      final animationController = _animationController;
      if (animationController != null) {
        if (animationController.status == AnimationStatus.completed ||
            animationController.status == AnimationStatus.forward) {
          try {
            animationController.reverse().then((_) {
              if (!_isDisposed && _overlayEntry != null) {
                overlayEntry.remove();
                _overlayEntry = null;
              }
            });
          } catch (e) {
            overlayEntry.remove();
            _overlayEntry = null;
          }
        } else {
          overlayEntry.remove();
          _overlayEntry = null;
        }
      } else {
        overlayEntry.remove();
        _overlayEntry = null;
      }
    }
  }

  /// Dismisses all currently active toasts from all controllers.
  ///
  /// This is a static method that dismisses toasts from all active
  /// AnchorToastController instances across the entire application.
  static void dismissAll() {
    // Create a copy of the set to avoid concurrent modification
    final controllers = Set<AnchorToastController>.from(_activeControllers);

    for (final controller in controllers) {
      if (!controller._isDisposed) {
        controller.dismiss();
      }
    }
  }

  /// Disposes the controller and cleans up resources.
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Remove from global registry
    _activeControllers.remove(this);

    final autoHideTimer = _autoHideTimer;
    autoHideTimer?.cancel();
    _autoHideTimer = null;

    // Clean up scroll listener
    final anchorContext = _anchorContext;
    if (anchorContext != null && anchorContext.mounted) {
      final scrollable = Scrollable.maybeOf(anchorContext);
      if (scrollable != null) {
        scrollable.position.removeListener(_updateToastPosition);
      }
    }
    final scrollSubscription = _scrollSubscription;
    scrollSubscription?.cancel();
    _scrollSubscription = null;
    final positionNotifier = _positionNotifier;
    positionNotifier?.dispose();
    _positionNotifier = null;

    final overlayEntry = _overlayEntry;
    overlayEntry?.remove();
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
    final autoHideTimer = _autoHideTimer;
    autoHideTimer?.cancel();
    _autoHideTimer = null;

    // Clean up scroll listener
    final anchorContext = _anchorContext;
    if (anchorContext != null && anchorContext.mounted) {
      final scrollable = Scrollable.maybeOf(anchorContext);
      if (scrollable != null) {
        scrollable.position.removeListener(_updateToastPosition);
      }
    }
    final scrollSubscription = _scrollSubscription;
    scrollSubscription?.cancel();
    _scrollSubscription = null;

    // Note: We don't dispose _positionNotifier here as it can be reused
    // It will only be disposed when the controller itself is disposed

    final overlayEntry = _overlayEntry;
    if (overlayEntry != null) {
      overlayEntry.remove();
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
    final scrollSubscription = _scrollSubscription;
    scrollSubscription?.cancel();

    final anchorContext = _anchorContext;
    if (anchorContext == null || !anchorContext.mounted) return;

    // Find the nearest scrollable
    final scrollable = Scrollable.maybeOf(anchorContext);
    if (scrollable != null) {
      scrollable.position.addListener(_updateToastPosition);
    }
  }

  /// Sets up listener for view insets changes (keyboard, system UI)
  void _setupViewInsetsListener() {
    final anchorContext = _anchorContext;
    if (anchorContext == null || !anchorContext.mounted) return;

    // Store current view insets for comparison
    _lastViewInsets = MediaQuery.viewInsetsOf(anchorContext);

    // Add post-frame callback to check for view insets changes
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkViewInsetsChange(),
    );
  }

  /// Checks if view insets have changed and updates toast position accordingly
  void _checkViewInsetsChange() {
    final anchorContext = _anchorContext;
    if (_isDisposed ||
        anchorContext == null ||
        !anchorContext.mounted ||
        _overlayEntry == null) {
      return;
    }

    final currentViewInsets = MediaQuery.viewInsetsOf(anchorContext);
    final lastViewInsets = _lastViewInsets;

    if (lastViewInsets == null || currentViewInsets != lastViewInsets) {
      _lastViewInsets = currentViewInsets;
      _updateToastPosition();
    }

    // Schedule next check
    if (_overlayEntry != null && !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkViewInsetsChange(),
      );
    }
  }

  /// Calculates the proper toast position with unified logic
  Offset _calculateToastPosition({
    required BuildContext anchorContext,
    required Size anchorSize,
    required Offset anchorPosition,
  }) {
    final screenSize = MediaQuery.sizeOf(anchorContext);
    final padding = MediaQuery.paddingOf(anchorContext);
    final viewInsets = MediaQuery.viewInsetsOf(anchorContext);

    // Calculate proper positioning for the toast
    final anchorCenterX = anchorPosition.dx + (anchorSize.width / 2);

    // Adjust horizontal position to keep toast on screen
    double adjustedX = anchorCenterX;
    final maxToastWidth = screenSize.width - (_screenPadding * 2);
    final halfToastWidth = maxToastWidth / 2;

    if (anchorCenterX - halfToastWidth < _screenPadding) {
      adjustedX = _screenPadding + halfToastWidth;
    } else if (anchorCenterX + halfToastWidth >
        screenSize.width - _screenPadding) {
      adjustedX = screenSize.width - _screenPadding - halfToastWidth;
    }

    // Add vertical bounds checking to keep toast within safe area
    double adjustedY = anchorPosition.dy;
    final minY = padding.top + viewInsets.top + _screenPadding;
    final maxY =
        screenSize.height - padding.bottom - viewInsets.bottom - _screenPadding;
    adjustedY = adjustedY.clamp(minY, maxY);

    return Offset(adjustedX - (anchorSize.width / 2), adjustedY);
  }

  /// Updates the toast position based on current anchor position
  void _updateToastPosition() {
    final anchorContext = _anchorContext;
    final positionNotifier = _positionNotifier;
    if (_isDisposed ||
        anchorContext == null ||
        !anchorContext.mounted ||
        positionNotifier == null) {
      return;
    }

    try {
      final renderBox = anchorContext.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);

      // Use the unified positioning logic
      final adjustedPosition = _calculateToastPosition(
        anchorContext: anchorContext,
        anchorSize: size,
        anchorPosition: position,
      );

      positionNotifier.value = adjustedPosition;
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
        final toastY = widget.showAbove
            ? position.dy - widget.offset
            : position.dy + widget.anchorSize.height + widget.offset;

        // Calculate horizontal positioning with screen boundary constraints
        final screenPaddingValue =
            widget.screenPadding.left; // Use the padding value
        final anchorCenterX = position.dx + (widget.anchorSize.width / 2);

        return Positioned(
          left: anchorCenterX,
          top: toastY,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        widget.screenSize.width - (screenPaddingValue * 2),
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
