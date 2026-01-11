/// Constants for the mind map canvas
class CanvasConstants {
  CanvasConstants._();

  /// Canvas dimensions
  static const double canvasWidth = 4000.0;
  static const double canvasHeight = 4000.0;

  /// Center point of the canvas
  static const double canvasCenterX = canvasWidth / 2;
  static const double canvasCenterY = canvasHeight / 2;

  /// Boundary margin for InteractiveViewer
  static const double boundaryMargin = 2000.0;

  /// Zoom limits
  static const double minScale = 0.3;
  static const double maxScale = 3.0;
  static const double zoomFactor = 1.2;
  static const double defaultScale = 1.0;

  /// Node dimensions
  static const double nodeWidth = 150.0;
  static const double nodeHeight = 60.0;
  static const double nodeHalfWidth = nodeWidth / 2;
  static const double nodeHalfHeight = nodeHeight / 2;

  /// Grid settings
  static const double gridSpacing = 50.0;

  /// Connection line settings
  static const double connectionLineWidth = 3.0;
  static const double connectionOpacity = 0.5;

  /// Layout settings
  static const double horizontalSpacing = 250.0;
  static const double verticalSpacing = 180.0;
  static const double childYOffset = 150.0;
}

/// Constants for UI animations
class AnimationConstants {
  AnimationConstants._();

  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}

/// Constants for subscription limits
class SubscriptionConstants {
  SubscriptionConstants._();

  static const int freeMapLimit = 3;
  static const int freeAiUsageLimit = 10;
  static const int proMapLimit = -1; // Unlimited
  static const int proAiUsageLimit = -1; // Unlimited

  static const int proMonthlyPriceYen = 800;
}
