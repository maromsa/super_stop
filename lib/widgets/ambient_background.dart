import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnimatedAmbientBackground extends StatefulWidget {
  const AnimatedAmbientBackground({
    super.key,
    required this.colors,
    this.minBlobOpacity = 0.22,
    this.maxBlobOpacity = 0.38,
    this.blurSigma = 80,
  });

  final List<Color> colors;
  final double minBlobOpacity;
  final double maxBlobOpacity;
  final double blurSigma;

  @override
  State<AnimatedAmbientBackground> createState() => _AnimatedAmbientBackgroundState();
}

class _AnimatedAmbientBackgroundState extends State<AnimatedAmbientBackground>
    with SingleTickerProviderStateMixin {
  static const int _blobCount = 9;
  late final AnimationController _controller;
  late final List<_AmbientBlob> _blobs;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _blobs = List<_AmbientBlob>.generate(_blobCount, (index) => _createBlob(index));
  }

  _AmbientBlob _createBlob(int index) {
    final radius = _random.nextDouble() * 200 + 160;
    final speed = _random.nextDouble() * 0.8 + 0.2;
    final phase = _random.nextDouble() * 2 * math.pi;
    final color = widget.colors[index % widget.colors.length];
    return _AmbientBlob(
      origin: Offset(_random.nextDouble(), _random.nextDouble()),
      radius: radius,
      speed: speed,
      phase: phase,
      color: color,
      opacity: _random.nextDouble() * (widget.maxBlobOpacity - widget.minBlobOpacity) + widget.minBlobOpacity,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedAmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.colors, oldWidget.colors)) {
      for (var i = 0; i < _blobs.length; i++) {
        final blob = _blobs[i];
        _blobs[i] = blob.copyWith(color: widget.colors[i % widget.colors.length]);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _AmbientBackgroundPainter(
              blobs: _blobs,
              time: _controller.value,
              blurSigma: widget.blurSigma,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AmbientBlob {
  const _AmbientBlob({
    required this.origin,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
    required this.opacity,
  });

  final Offset origin;
  final double radius;
  final double speed;
  final double phase;
  final Color color;
  final double opacity;

  _AmbientBlob copyWith({Color? color}) {
    return _AmbientBlob(
      origin: origin,
      radius: radius,
      speed: speed,
      phase: phase,
      color: color ?? this.color,
      opacity: opacity,
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  _AmbientBackgroundPainter({
    required this.blobs,
    required this.time,
    required this.blurSigma,
  });

  final List<_AmbientBlob> blobs;
  final double time;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    final amplitude = Offset(size.width * 0.08, size.height * 0.08);

    for (final blob in blobs) {
      final dx = math.sin((time * math.pi * 2 * blob.speed) + blob.phase) * amplitude.dx;
      final dy = math.cos((time * math.pi * 2 * blob.speed) + blob.phase) * amplitude.dy;

      final position = Offset(blob.origin.dx * size.width, blob.origin.dy * size.height) + Offset(dx, dy);

      paint.color = blob.color.withOpacity(blob.opacity);
      canvas.drawCircle(position, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.blobs != blobs;
  }
}
