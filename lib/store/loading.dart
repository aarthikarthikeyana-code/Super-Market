import 'package:flutter/material.dart';

enum SkeletonKind { list, grid, detail, summary, image }

class AppSkeleton extends StatefulWidget {
  final SkeletonKind kind;
  final int count;
  final bool padded;
  final double height;
  const AppSkeleton({
    super.key,
    this.kind = SkeletonKind.list,
    this.count = 3,
    this.padded = true,
    this.height = 142,
  });
  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _box({double? width, double height = 14, double radius = 10}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2F0E7).withOpacity(0.7),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
      );

  Widget _row() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.75),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF087532).withOpacity(0.03),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F7EE),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 140, height: 16),
              const SizedBox(height: 8),
              _box(width: 90, height: 12),
              const SizedBox(height: 10),
              _box(width: 60, height: 14),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _grid() => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 14) / 2;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: List.generate(
          widget.count,
          (_) => Container(
            width: width > 0 ? width : 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF087532).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 10),
                _box(width: 100, height: 14),
                const SizedBox(height: 6),
                _box(width: 60, height: 11),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 50, height: 16),
                    _box(width: 32, height: 32, radius: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _detail() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF3),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 18),
        _box(width: 200, height: 20),
        const SizedBox(height: 10),
        _box(width: 120, height: 14),
        const SizedBox(height: 16),
        _box(width: 80, height: 24),
        const SizedBox(height: 20),
        _box(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        _box(width: 260, height: 14),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (widget.kind) {
      case SkeletonKind.grid:
        content = _grid();
        break;
      case SkeletonKind.detail:
        content = _detail();
        break;
      case SkeletonKind.image:
        content = _box(height: widget.height, radius: 18);
        break;
      case SkeletonKind.summary:
        content = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 180, height: 20),
              const SizedBox(height: 12),
              _box(width: 240, height: 14),
            ],
          ),
        );
        break;
      case SkeletonKind.list:
      default:
        content = Column(
          children: List.generate(widget.count, (_) => _row()),
        );
        break;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.95).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: widget.padded
          ? Padding(padding: const EdgeInsets.all(16), child: content)
          : content,
    );
  }
}
