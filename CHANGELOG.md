# Changelog

## 0.3.2

### Added
* **Configurable Dismiss Animation**: New optional `animate` parameter in `dismiss()` method for controlling dismissal animation
  - `dismiss()` - Dismisses with animation (default behavior, maintains backward compatibility)
  - `dismiss(animate: true)` - Explicitly dismisses with animation
  - `dismiss(animate: false)` - Dismisses immediately without animation
  - Useful for scenarios requiring instant dismissal or custom animation handling

## 0.3.1

### Fixed
* **Toast Interactivity Issue**: Fixed toasts not being clickable due to improper use of `FractionalTranslation` widget
  - Replaced `FractionalTranslation` with proper `Positioned`, `Align`, and `Transform.translate` widgets

## 0.3.0

### Added
* **Global Dismiss All Functionality**: New static `dismissAll()` method in `AnchorToastController` for dismissing all active toasts
  - `AnchorToastController.dismissAll()` dismisses toasts from all controllers across the entire application
  - Automatic controller registry system tracks all active controllers
  - Controllers are automatically registered on creation and unregistered on disposal
  - Safe concurrent modification handling prevents issues when dismissing multiple toasts

### Improved  
* **Example App Enhancement**: Updated example to demonstrate the new `dismissAll()` functionality
  - Simplified "Dismiss All Toasts" button implementation using the new static method
  - Cleaner code by removing the need to manually call dismiss on each individual controller

## 0.2.0

### Added
* **Customizable Screen Padding**: New `screenPadding` parameter in `showToast()` method allows control over screen edge padding
  - Default value remains 16.0 pixels for backward compatibility
  - Controls minimum distance between toast and screen edges
  - Affects toast positioning and maximum width calculations
  - Applies to both automatic positioning and manual position updates during scrolling

### Improved
* **Enhanced Keyboard-Aware Positioning**: Comprehensive keyboard and view insets handling for optimal toast placement
  - **Real-time Keyboard Tracking**: Automatic repositioning when keyboard appears/disappears using view insets monitoring
  - **Vertical Bounds Checking**: Toasts are automatically clamped within safe screen bounds considering keyboard height
  - **Unified Position Calculation**: Single positioning logic ensures consistency between initial placement and dynamic updates
  - **Optimized ValueNotifier Lifecycle**: Position notifier is now reused across multiple toasts for better memory efficiency

### Fixed
* **Null Safety Improvements**: Removed all null assertion operators (`!`) and replaced with safe null-checking patterns
* **Position Calculation Consistency**: Unified the initial toast positioning and scroll-based repositioning logic to prevent discrepancies
* **Memory Optimization**: Position notifier is no longer recreated for each toast, reducing garbage collection overhead

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
