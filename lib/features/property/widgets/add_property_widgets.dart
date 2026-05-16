import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class PropertySuccessScreen extends StatefulWidget {
  final String ownerName;
  final String title;
  final String area;
  final String landmark;
  final String category;
  final String price;
  final DateTime submittedAt;

  const PropertySuccessScreen({
    super.key,
    required this.ownerName,
    required this.title,
    required this.area,
    required this.landmark,
    required this.category,
    required this.price,
    required this.submittedAt,
  });

  @override
  State<PropertySuccessScreen> createState() => _PropertySuccessScreenState();
}

class _PropertySuccessScreenState extends State<PropertySuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _spikeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _spikeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Spike Green Circle ──────────────────────────────────────
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spikes layer
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _SpikePainter(progress: _spikeAnim.value),
                    ),
                    // Main circle
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ───────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Published!',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your property is now live on Khozna',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Compact Summary Card ────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(
                        Icons.home_rounded,
                        widget.title.isEmpty ? 'My Property' : widget.title,
                        const Color(0xFF22C55E),
                      ),
                      const Divider(height: 18, thickness: 0.8),
                      _summaryRow(
                        Icons.location_on_rounded,
                        widget.area,
                        AppTheme.brandColor,
                      ),
                      if (widget.price.isNotEmpty) ...[
                        const Divider(height: 18, thickness: 0.8),
                        _summaryRow(
                          Icons.payments_rounded,
                          '₹${widget.price}/mo',
                          Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Live badge ──────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Live & Verified',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Action Buttons ──────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          elevation: 0,
                          shadowColor: AppTheme.brandColor.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Go to Home',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'View My Listings',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4B5563),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


// ── Spike / Starburst painter ─────────────────────────────────────────────────
class _SpikePainter extends CustomPainter {
  final double progress;
  _SpikePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const spikeCount = 12;
    const innerR = 56.0;
    final outerR = 72.0 + (progress * 10);

    // Outer glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.06 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR + 4, glowPaint);

    // Spikes
    final spikePaint = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.22 * progress)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < spikeCount; i++) {
      final angle = (i * 2 * math.pi) / spikeCount;
      final start = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(start, end, spikePaint);
    }
  }

  @override
  bool shouldRepaint(_SpikePainter old) => old.progress != progress;
}


class CategoryCard extends StatefulWidget {
  final String label;
  final String imagePath;
  final String value;
  final String? selectedValue;
  final Function(String) onSelect;
  final double imageScale;

  const CategoryCard({
    super.key,
    required this.label,
    required this.imagePath,
    required this.value,
    required this.selectedValue,
    required this.onSelect,
    this.imageScale = 1.0,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedValue == widget.value;
    
    // Split label to stylize the slash
    final parts = widget.label.split(' / ');
    final nepaliText = parts[0];
    final englishText = parts.length > 1 ? parts[1] : '';

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.selectionClick();
        widget.onSelect(widget.value);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, isSelected ? 2.5 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                // 3D Push Button Shadow
                BoxShadow(
                  color: isSelected 
                      ? AppTheme.brandColor.withOpacity(0.3) 
                      : const Color(0xFFE2E8F0),
                  offset: isSelected ? const Offset(0, 1.5) : const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: widget.imageScale,
                        child: Image.asset(
                          widget.imagePath,
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppTheme.brandColor : const Color(0xFF1E293B),
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(text: nepaliText),
                              if (englishText.isNotEmpty) ...[
                                TextSpan(
                                  text: ' / ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? AppTheme.brandColor.withOpacity(0.5) : Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: englishText,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StepLayout extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String subtitle;
  final List<Widget> content;
  final ScrollController? controller;
  final Widget? topWidget;

  const StepLayout({
    super.key,
    required this.title,
    this.titleWidget,
    required this.subtitle,
    required this.content,
    this.controller,
    this.topWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topWidget != null) ...[
            topWidget!,
            const SizedBox(height: 12),
          ],
          titleWidget ?? Text(
            title,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 32),
          ...content,
        ],
      ),
    );
  }
}

class PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Color accentColor;
  final bool isLoading;

  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.accentColor = AppTheme.brandColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class PropertyFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool isRequired;
  final int maxLines;
  final IconData? prefixIcon;

  const PropertyFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.isRequired = false,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, size: 18, color: Colors.grey[400]) 
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.brandColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AmenitiesGrid extends StatelessWidget {
  final List<String> selectedItems;
  final Map<String, IconData> icons;
  final Map<String, String> labels;
  final Function(String) onToggle;

  const AmenitiesGrid({
    super.key,
    required this.selectedItems,
    required this.icons,
    required this.labels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final key = icons.keys.elementAt(index);
        final isSelected = selectedItems.contains(key);
        return GestureDetector(
          onTap: () => onToggle(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.brandColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.brandColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[key],
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    labels[key] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuickPriceChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentValue;
  final Function(String) onTap;

  const QuickPriceChip({
    super.key,
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentValue == value;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Rs.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF111827),
                ),
              ),
              TextSpan(
                text: label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CounterField extends StatelessWidget {
  final String label;
  final String value;
  final Function() onIncrement;
  final Function() onDecrement;
  final IconData icon;

  const CounterField({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBtn(Icons.remove_rounded, onDecrement),
              Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.brandColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      value.isEmpty ? '0' : value,
                      key: ValueKey<String>(value),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              _buildBtn(Icons.add_rounded, onIncrement),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(IconData icon, Function() onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1F2937)),
      ),
    );
  }
}

class FloorSelector extends StatelessWidget {
  final String label;
  final String? selectedFloor;
  final Function(String) onSelect;

  const FloorSelector({
    super.key,
    required this.label,
    required this.selectedFloor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final floors = ['Ground', '1st', '2nd', '3rd', '4th', '5th+'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: floors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final floor = floors[index];
              final isSelected = selectedFloor == floor;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(floor);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandColor : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppTheme.brandColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Text(
                    floor,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class QuickSizeSelector extends StatelessWidget {
  final Function(String) onSelect;
  final String currentValue;

  const QuickSizeSelector({
    super.key,
    required this.onSelect,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = {
      'S': '150',
      'M': '350',
      'L': '600',
      'XL': '1000+',
    };

    return Row(
      children: sizes.entries.map((e) {
        final isSelected = currentValue == e.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onSelect(e.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.black87 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                e.key,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PriceInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;

  const PriceInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'Rs.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[300]),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
