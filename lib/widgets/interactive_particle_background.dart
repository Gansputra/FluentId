import 'dart:math';
import 'package:flutter/material.dart';

class InteractiveParticleBackground extends StatefulWidget {
  final Widget child;
  const InteractiveParticleBackground({super.key, required this.child});

  @override
  State<InteractiveParticleBackground> createState() => _InteractiveParticleBackgroundState();
}

class _InteractiveParticleBackgroundState extends State<InteractiveParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final int numberOfParticles = 40;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Background Gradient + Particles
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF3E5F5), // Very light purple
                  Colors.white,
                  const Color(0xFFE3F2FD), // Very light blue
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) => setState(() => _tapPosition = event.localPosition),
            onPointerMove: (event) => setState(() => _tapPosition = event.localPosition),
            onPointerUp: (event) => setState(() => _tapPosition = null),
            onPointerCancel: (event) => setState(() => _tapPosition = null),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: particles,
                    tapPosition: _tapPosition,
                  ),
                );
              },
            ),
          ),
        ),
        // The actual content
        IgnorePointer(
          ignoring: false, // Ensure content is interactable
          child: widget.child,
        ),
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late double opacity;

  Particle() {
    reset();
  }

  void reset() {
    final random = Random();
    x = random.nextDouble();
    y = random.nextDouble();
    vx = (random.nextDouble() - 0.5) * 0.001;
    vy = (random.nextDouble() - 0.5) * 0.001;
    size = random.nextDouble() * 4 + 2;
    opacity = random.nextDouble() * 0.5 + 0.2;
  }

  void update(Offset? tapPosition, Size screenSize) {
    x += vx;
    y += vy;

    // Bounce off edges
    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;

    // Interaction with tap
    if (tapPosition != null) {
      double dx = (tapPosition.dx / screenSize.width) - x;
      double dy = (tapPosition.dy / screenSize.height) - y;
      double distance = sqrt(dx * dx + dy * dy);
      
      if (distance < 0.2) {
        // Repel from touch
        x -= dx * 0.01;
        y -= dy * 0.01;
      }
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? tapPosition;

  ParticlePainter({required this.particles, this.tapPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length; i++) {
      var p = particles[i];
      p.update(tapPosition, size);

      double px = p.x * size.width;
      double py = p.y * size.height;

      // Draw particle
      paint.color = Colors.deepPurple.withOpacity(p.opacity);
      canvas.drawCircle(Offset(px, py), p.size, paint);

      // Draw lines between nearby particles
      for (int j = i + 1; j < particles.length; j++) {
        var p2 = particles[j];
        double p2x = p2.x * size.width;
        double p2y = p2.y * size.height;
        
        double dx = px - p2x;
        double dy = py - p2y;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance < 100) {
          linePaint.color = Colors.deepPurple.withOpacity(0.15 * (1 - distance / 100));
          canvas.drawLine(Offset(px, py), Offset(p2x, p2y), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
