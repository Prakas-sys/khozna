import 'package:flutter/material.dart';

class SkeletonCard extends StatefulWidget {
  final bool isFullWidth;

  const SkeletonCard({super.key, this.isFullWidth = false});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isFullWidth ? double.infinity : 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (Shimmering)
            _buildShimmerItem(Container(
              height: 175,
              width: double.infinity,
              color: Colors.white,
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), // Tight match for PropertyCard
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerItem(Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                      _buildShimmerItem(Container(
                        width: 70,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Amenities / Location Row Placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildShimmerItem(Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )),
                          const SizedBox(width: 4),
                          _buildShimmerItem(Container(
                            width: 60,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )),
                        ],
                      ),
                      Row(
                        children: [
                          _buildShimmerItem(_buildTinyIconSkeleton()),
                          const SizedBox(width: 12),
                          _buildShimmerItem(_buildTinyIconSkeleton()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Button lines
                  Row(
                    children: [
                      Expanded(
                        child: _buildShimmerItem(Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildShimmerItem(Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(Widget child) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, 0.5, 0.9],
          colors: [
            const Color(0xFFF5F5F5),
            const Color(0xFFEBEBEB),
            const Color(0xFFF5F5F5),
          ],
          transform: _SlidingGradientTransform(offset: _controller.value),
        ).createShader(bounds);
      },
      child: child,
    );
  }

  Widget _buildTinyIconSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.offset});

  final double offset;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (offset * 2 - 1), 0, 0);
  }
}
