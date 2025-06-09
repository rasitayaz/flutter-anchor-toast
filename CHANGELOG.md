# Changelog

## 0.0.2

### 🚀 Major Animation Improvements

* **Smoother Animations**: Completely redesigned animation system for silky 60/120fps performance
* **Better Animation Curves**: Switched from `Curves.elasticOut` to `Curves.easeOutCubic` for high refresh rate optimization
* **Staggered Animation Timing**: Added sophisticated animation intervals for better visual layering
* **Performance Optimization**: Added `RepaintBoundary` widgets to isolate expensive repaints
* **Multi-layer Animation**: Combined scale, opacity, and slide animations with optimized timing
* **Memory Management**: Improved controller disposal for extension method usage
* **Haptic Feedback**: Added optional light haptic feedback for enhanced UX
* **Frame Rate Optimization**: Optimized for modern high refresh rate displays (120Hz+)

### 🔧 Technical Improvements

* **Animation Duration**: Increased from 300ms to 400ms for smoother motion
* **Better Positioning**: Replaced hardcoded size estimation with `FractionalTranslation` 
* **Transition Widgets**: Migrated from `Transform` widgets to `SlideTransition`, `ScaleTransition`, `FadeTransition`
* **Animation State Management**: Enhanced animation controller lifecycle management
* **Test Compatibility**: Fixed timer-related test issues in extension method

### 🐛 Bug Fixes

* **Memory Leaks**: Fixed controller disposal issues in extension method
* **Animation Jank**: Eliminated jerky positioning and inconsistent timing
* **Performance Issues**: Removed multiple transform compositions causing frame drops
* **Test Failures**: Resolved pending timer issues in test environment

## 0.0.1

### Initial Release

* **AnchorToast Widget**: Wrap any anchor widget to enable toast functionality
* **AnchorToastController**: Complete controller for managing toast display and dismissal
* **Smart Positioning**: Automatically determines optimal position (above/below) based on available screen space
* **Smooth Animations**: Beautiful scale and opacity animations with elastic entrance effect
* **Auto-dismiss**: Configurable duration for automatic toast dismissal
* **Manual Dismiss**: `dismiss()` method for manual toast control
* **Context Extension**: Convenient `context.showAnchorToast()` method for simple usage
* **Overlay Integration**: Uses Flutter's Overlay system for proper z-index handling
* **Customizable Offset**: Adjustable spacing between anchor and toast
* **Memory Management**: Proper disposal of resources and animation controllers

### Features

- ✅ Smart positioning above/below anchor based on available space
- ✅ Scale and opacity animations with smooth curves
- ✅ Auto-dismiss with configurable duration
- ✅ Manual dismiss capability
- ✅ Multiple usage patterns (widget wrapper, controller, extension)
- ✅ Proper memory management and cleanup
- ✅ Comprehensive test coverage
- ✅ Example app with various use cases
- ✅ Full documentation and API reference
