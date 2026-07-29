import 'package:flutter/material.dart';

/// Custom scroll behavior for terminal views.
///
/// Uses [PtyScrollPhysics] which combines [BouncingScrollPhysics]-style
/// responsive drag feel with [ClampingScrollPhysics]-style ballistic fling
/// control — the terminal buffer is very tall (thousands of lines), so even
/// a moderate ballistic fling can scroll through hundreds of lines unless the
/// deceleration is properly bounded.
///
/// Also uses [RangeMaintainingScrollPhysics] to prevent position snapping
/// when new terminal output is appended during a scroll.
class PtyScrollBehavior extends ScrollBehavior {
  const PtyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const PtyScrollPhysics(parent: RangeMaintainingScrollPhysics());
  }
}

/// Hybrid scroll physics for terminal content.
///
/// - **Drag**: 1:1 finger-to-scroll mapping with low (3.5 px) start threshold
///   — feels responsive like [BouncingScrollPhysics].
/// - **Fling**: Uses [ClampingScrollSimulation] which has ~67× higher effective
///   friction than [BouncingScrollSimulation], preventing the "whoosh" effect
///   where a light flick scrolls through half the buffer.
/// - **Overscroll**: Uses spring simulation to gently return in-range.
class PtyScrollPhysics extends ScrollPhysics {
  const PtyScrollPhysics({super.parent});

  @override
  PtyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PtyScrollPhysics(parent: buildParent(ancestor));
  }

  // ── Drag ──────────────────────────────────────────────────────

  /// Low threshold — finger starts affecting scroll immediately.
  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  /// 1:1 drag mapping for responsive feel (like [BouncingScrollPhysics]).
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset;
  }

  /// Allow overscroll so the drag can enter the overscroll region
  /// (the spring simulation will return it).
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  // ── Fling ─────────────────────────────────────────────────────

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    // Overscroll — use a spring to gently return in-range.
    if (position.outOfRange) {
      final end = position.pixels > position.maxScrollExtent
          ? position.maxScrollExtent
          : position.minScrollExtent;
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity.clamp(-2000.0, 2000.0),
        tolerance: tolerance,
      );
    }

    // In-range fling — use ClampingScrollSimulation for controlled
    // deceleration (much higher friction than BouncingScrollSimulation).
    if (velocity.abs() < tolerance.velocity) return null;
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}
