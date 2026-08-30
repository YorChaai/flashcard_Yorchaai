import 'dart:async';
import 'package:flutter/material.dart';

/// Service to show interactive notifications that support 3-way swipe-to-dismiss:
/// - Left / Right: Dismisses if dragged >= 40% of width.
/// - Down: Dismisses if dragged >= 50% of height.
class AppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    IconData? icon,
  }) {
    hide();

    final overlay = Overlay.of(context, rootOverlay: true);

    _currentEntry = OverlayEntry(
      builder: (ctx) => _SwipeableNotificationBanner(
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          hide();
          onAction?.call();
        },
        duration: duration,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismissed: () {
          _removeEntry();
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _removeEntry();
  }

  static void _removeEntry() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _SwipeableNotificationBanner extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final Color? backgroundColor;
  final IconData? icon;
  final VoidCallback onDismissed;

  const _SwipeableNotificationBanner({
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.duration,
    this.backgroundColor,
    this.icon,
    required this.onDismissed,
  });

  @override
  State<_SwipeableNotificationBanner> createState() => _SwipeableNotificationBannerState();
}

class _SwipeableNotificationBannerState extends State<_SwipeableNotificationBanner>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _enterAnimation;

  AnimationController? _springController;
  AnimationController? _dismissController;

  double _dragDx = 0.0;
  double _dragDy = 0.0;
  bool _isDragging = false;
  bool _isDismissing = false;
  Timer? _autoDismissTimer;

  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _enterAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.forward();
    _startTimer();
  }

  void _startTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted && !_isDragging && !_isDismissing) {
        _animateDismiss(const Offset(0, 80));
      }
    });
  }

  void _pauseTimer() {
    _autoDismissTimer?.cancel();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    _springController?.dispose();
    _dismissController?.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isDismissing) return;
    _pauseTimer();
    _springController?.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragDx += details.delta.dx;
      // Strictly allow dragging downwards ONLY (never upwards)
      _dragDy = (_dragDy + details.delta.dy).clamp(0.0, 500.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDismissing) return;
    setState(() {
      _isDragging = false;
    });

    final renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 350.0;
    final height = renderBox?.size.height ?? 56.0;
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalProgress = _dragDx.abs() / width;
    final verticalProgress = _dragDy / height;

    // Rules:
    // Left / Right threshold: >= 40% (0.40)
    // Downwards threshold: >= 50% (0.50)
    if (horizontalProgress >= 0.40) {
      // Fly completely off the screen edge in the drag direction
      final targetDx = _dragDx > 0 ? (screenWidth + 200) : -(screenWidth + 200);
      _animateDismiss(Offset(targetDx, _dragDy));
    } else if (verticalProgress >= 0.50) {
      // Fly completely downwards off-screen
      _animateDismiss(Offset(_dragDx, 300.0));
    } else {
      // Spring back to exact center
      _springBack();
      _startTimer();
    }
  }

  void _springBack() {
    _springController?.dispose();
    final startDx = _dragDx;
    final startDy = _dragDy;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _springController = controller;

    final anim = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    anim.addListener(() {
      if (mounted) {
        setState(() {
          _dragDx = startDx * (1.0 - anim.value);
          _dragDy = startDy * (1.0 - anim.value);
        });
      }
    });

    controller.forward();
  }

  void _animateDismiss(Offset targetOffset) {
    if (_isDismissing) return;
    _isDismissing = true;
    _springController?.stop();
    _dismissController?.dispose();

    final startDx = _dragDx;
    final startDy = _dragDy;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _dismissController = controller;

    final anim = CurvedAnimation(parent: controller, curve: Curves.easeInCubic);

    anim.addListener(() {
      if (mounted) {
        setState(() {
          _dragDx = startDx + (targetOffset.dx - startDx) * anim.value;
          _dragDy = startDy + (targetOffset.dy - startDy) * anim.value;
        });
      }
    });

    controller.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      bottom: 24.0,
      left: 16.0,
      right: 16.0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedBuilder(
            animation: _enterAnimation,
            builder: (context, child) {
              final enterTranslate = (1.0 - _enterAnimation.value) * 60;

              return Transform.translate(
                offset: Offset(_dragDx, _dragDy + enterTranslate),
                child: Opacity(
                  opacity: _enterAnimation.value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              key: _cardKey,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? (isDark ? const Color(0xFF232734) : const Color(0xFF323644)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: Colors.white70),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: widget.onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _animateDismiss(const Offset(0, 80)),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
