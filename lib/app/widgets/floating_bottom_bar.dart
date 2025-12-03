import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingBottomBar extends StatefulWidget {
  const FloatingBottomBar({
    required this.onSearch,
    required this.onNavigate,
    required this.onBookmarks,
    super.key,
  });

  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onBookmarks;

  @override
  State<FloatingBottomBar> createState() => FloatingBottomBarState();
}

class FloatingBottomBarState extends State<FloatingBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Slightly smoother
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 2), // Moves down out of view
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubicEmphasized,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void show() {
    if (!_isVisible) {
      _animationController.reverse();
      setState(() => _isVisible = true);
    }
  }

  void hide() {
    if (_isVisible) {
      _animationController.forward();
      setState(() => _isVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _offsetAnimation,
      // 1. Outer Container handles Margins and Shadows
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -2,
            ),
          ],
        ),
        // 2. ClipRRect handles the rounded corners for the Glass Blur
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            // 3. The actual Blur Effect
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                // 4. CRITICAL: The color MUST have opacity for blur to show
                color: colorScheme.surfaceContainer.withOpacity(0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(
                      context: context,
                      icon: Icons.search_rounded,
                      onPressed: widget.onSearch,
                      tooltip: 'بحث',
                    ),
                    _buildIconButton(
                      context: context,
                      icon: Icons.menu_book_rounded,
                      onPressed: widget.onNavigate,
                      tooltip: 'انتقال سريع',
                      isHighlighted: true,
                    ),
                    _buildIconButton(
                      context: context,
                      icon: Icons
                          .bookmark_border_rounded, // Rounded variant matches better
                      onPressed: widget.onBookmarks,
                      tooltip: 'العلامات المرجعية',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 48, // Larger touch target
          height: 48,
          decoration: isHighlighted
              ? BoxDecoration(
                  // LIGHTER VIBE:
                  // Instead of solid primary, use a soft wash of the primary color
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                )
              : null,
          child: Icon(
            icon,
            color: isHighlighted
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
