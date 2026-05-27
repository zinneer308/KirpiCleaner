import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clean_item.dart';
import '../services/cleaner_service.dart';

class ResultScreen extends StatefulWidget {
  final CleanResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildSuccessHeader(),
                const SizedBox(height: 32),
                _buildMainResult(),
                const SizedBox(height: 24),
                _buildPieChart(),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(),
                const SizedBox(height: 32),
                _buildDoneButton(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [AppTheme.accentGreen, Color(0xFF00B77A)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: AppTheme.bgDeep,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Готово! 🦔',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Устройство очищено успешно',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildMainResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B1E), Color(0xFF0A1F30)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            widget.result.formattedSize,
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'освобождено памяти',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildResultStat(
                '✅',
                '${widget.result.cleanedItems}',
                'очищено',
                AppTheme.accentGreen,
              ),
              if (widget.result.failedItems > 0) ...[
                const SizedBox(width: 24),
                _buildResultStat(
                  '⚠️',
                  '${widget.result.failedItems}',
                  'пропущено',
                  AppTheme.accentOrange,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    if (widget.result.byCategory.isEmpty) return const SizedBox.shrink();

    final total = widget.result.totalBytesFreed;
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppTheme.accentCyan,
      AppTheme.accentOrange,
      AppTheme.accentPurple,
      AppTheme.accentGreen,
      const Color(0xFFFFD600),
      const Color(0xFFFF4081),
    ];

    final entries = widget.result.byCategory.entries
        .where((e) => e.value > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Распределение по типам',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _PieChartPainter(
                sections: entries.map((e) => e.value / total).toList(),
                colors: colors.take(entries.length).toList(),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.asMap().entries.map((e) {
              final color = colors[e.key % colors.length];
              final category = e.value.key;
              final pct = ((e.value.value / total) * 100).toInt();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${category.displayName} ($pct%)',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (widget.result.byCategory.isEmpty) return const SizedBox.shrink();

    final sortedEntries = widget.result.byCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final max = sortedEntries.first.value;

    final colors = {
      CleanCategory.cache: AppTheme.accentCyan,
      CleanCategory.temp: AppTheme.accentOrange,
      CleanCategory.thumbnails: AppTheme.accentPurple,
      CleanCategory.apkFiles: const Color(0xFFFFD600),
      CleanCategory.emptyFolders: AppTheme.accentGreen,
      CleanCategory.logs: const Color(0xFFFF4081),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Детали очистки',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final color = colors[entry.key] ?? AppTheme.accentCyan;
            final percent = max > 0 ? entry.value / max : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.key.iconEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        CleanItem.formatBytes(entry.value),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppTheme.bgSurface,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: AppTheme.bgDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Отлично! На главную',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> sections;
  final List<Color> colors;

  _PieChartPainter({required this.sections, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    double startAngle = -pi / 2;

    for (int i = 0; i < sections.length; i++) {
      final sweepAngle = 2 * pi * sections[i];
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.03,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Center hole
    final holePaint = Paint()
      ..color = AppTheme.bgCard
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => false;
}
