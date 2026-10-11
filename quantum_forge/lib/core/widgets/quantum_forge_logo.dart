import 'package:flutter/material.dart';

/// The official Quantum Forge logo widget.
///
/// Uses the master asset `assets/Quantum_forge_icon.jpeg` with customizable
/// sizing, border radius, and subtle quantum cyan glow.
class QuantumForgeLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showGlow;
  final BoxBorder? border;

  const QuantumForgeLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
    this.showGlow = true,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/Quantum_forge_icon.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF0F172A),
            alignment: Alignment.center,
            child: Icon(
              Icons.science_rounded,
              color: const Color(0xFF4FC3F7),
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
