import 'package:flutter/material.dart';

class AnimatedActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool darkStyle;
  final IconData icon;

  const AnimatedActionButton({
    super.key,
    required this.text,
    required this.onTap,
    this.darkStyle = false,
    this.icon = Icons.add,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool invert = _pressed;

    final Decoration decoration;
    final Color textColor;
    final Color iconColor;

    if (widget.darkStyle) {
      decoration = BoxDecoration(
        color: invert ? const Color(0xFFFFD6E0) : const Color(0xFF232531),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );
      textColor = invert ? Colors.black : Colors.white;
      iconColor = invert ? Colors.black : Colors.white;
    } else {
      decoration = BoxDecoration(
        gradient: invert
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFD6E0), Color(0xFFCDE7FF)],
              ),
        color: invert ? const Color(0xFF232531) : null,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );
      textColor = invert ? Colors.white : Colors.black;
      iconColor = invert ? Colors.white : Colors.black;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              widget.text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}