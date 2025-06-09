# Changelog

## Unreleased

### Added
* **Customizable Horizontal Padding**: New `horizontalPadding` parameter in `showToast()` method allows control over screen edge padding
  - Default value remains 16.0 pixels for backward compatibility
  - Controls minimum distance between toast and screen edges
  - Affects toast positioning and maximum width calculations
  - Applies to both automatic positioning and manual position updates during scrolling

## 0.1.0

### Added
* **Manual Position Override**: New `showAbove` parameter in `showToast()` method allows manual control over toast positioning
  - Set `showAbove: true` to force toast above the anchor
  - Set `showAbove: false` to force toast below the anchor  
  - Set `showAbove: null` (default) to use automatic smart positioning

### Improved
* **Keyboard-Aware Positioning**: Smart positioning now considers view insets (keyboard, system UI) for better toast placement
  - Automatically accounts for keyboard height when calculating available space
  - Uses visible screen area center instead of full screen center when keyboard is shown
  - Ensures toasts remain visible and accessible when keyboard or other system UI is active

## 0.0.1

### Initial Release

* **AnchorToast Widget**: Wrap any anchor widget to enable toast functionality
* **AnchorToastController**: Complete controller for managing toast display and dismissal
* **Smart Positioning**: Automatically determines optimal position (above/below) based on available screen space
* **Smooth Animations**: Beautiful scale and opacity animations with optimized timing
* **Auto-dismiss**: Configurable duration for automatic toast dismissal
* **Manual Dismiss**: `dismiss()` method for manual toast control
* **Overlay Integration**: Uses Flutter's Overlay system for proper z-index handling
* **Customizable Offset**: Adjustable spacing between anchor and toast
* **Memory Management**: Proper disposal of resources and animation controllers

### Features

- Smart positioning above/below anchor based on available space
- Scale and opacity animations with smooth curves
- Auto-dismiss with configurable duration
- Manual dismiss capability
- Clean and simple API with `AnchorToast` widget and controller
- Proper memory management and cleanup
- Comprehensive test coverage
- Example app with various use cases
- Full documentation and API reference
