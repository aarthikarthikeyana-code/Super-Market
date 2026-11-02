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
    duration: const Duration(milliseconds: 1100),
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

  Widget _box({double? width, double height = 14, double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE5DC),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
  Widget _row() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        _box(width: 54, height: 62, radius: 14),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 160),
              const SizedBox(height: 12),
              _box(width: 100, height: 10),
              const SizedBox(height: 14),
              _box(width: 70, height: 12),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tile() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(height: 142, radius: 20),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 70, height: 10),
              const SizedBox(height: 12),
              _box(height: 14),
              const SizedBox(height: 8),
              _box(width: 90, height: 14),
              const SizedBox(height: 24),
              _box(width: 65, height: 18),
            ],
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading content',
    excludeSemantics: true,
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Opacity(
        opacity: .55 + .4 * Curves.easeInOut.transform(_pulse.value),
        child: child,
      ),
      child: Padding(
        padding: widget.padded ? const EdgeInsets.all(20) : EdgeInsets.zero,
        child: switch (widget.kind) {
          SkeletonKind.image => _box(height: widget.height, radius: 0),
          SkeletonKind.summary => SizedBox(
            height: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 200, height: 24),
                const SizedBox(height: 12),
                _box(width: 260),
              ],
            ),
          ),
          SkeletonKind.grid => LayoutBuilder(
            builder: (_, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 660 ? 4 : 2,
                mainAxisExtent: 300,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.count,
              itemBuilder: (_, _) => _tile(),
            ),
          ),
          SkeletonKind.detail => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 190, height: 26),
              const SizedBox(height: 24),
              _box(height: 110, radius: 20),
              const SizedBox(height: 20),
              for (var i = 0; i < widget.count; i++) _row(),
            ],
          ),
          SkeletonKind.list => Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < widget.count; i++) _row()],
          ),
        },
      ),
    ),
  );
}
