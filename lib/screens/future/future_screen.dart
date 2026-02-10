import 'dart:math';
import 'package:flutter/material.dart';

class FutureScreen extends StatefulWidget {
  const FutureScreen({super.key});

  @override
  State<FutureScreen> createState() => _FutureScreenState();
}

class _FutureScreenState extends State<FutureScreen> {
  // --- Mock inputs (later from Firestore + AI) ---
  double _sleepHours = 6.2; // 4–10
  double _exerciseMins = 60; // 0–180 per week
  double _stressLevel = 3; // 1–5

  // Base (from Home screen mock)
  final int _baseScore = 67;
  final int _scoreTrend = 3;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // --- Simple mock model (predictable, judge-friendly) ---
  int get _futureScore {
    // Sleep impact: target ~7.5h
    final sleepDelta = (_sleepHours - 6.0) * 4.0; // +4 per extra hour above 6

    // Exercise impact: saturates at 150min
    final ex = min(_exerciseMins, 150.0);
    final exerciseDelta = (ex / 150.0) * 10.0; // up to +10

    // Stress penalty: higher stress reduces score
    final stressDelta =
        (3.0 - _stressLevel) * 6.0; // stress 1 => +12, stress 5 => -12

    final score = _baseScore + sleepDelta + exerciseDelta + stressDelta;
    return score.round().clamp(0, 100);
  }

  int get _physical {
    final val = (_futureScore + (_exerciseMins / 30).round() - 2).clamp(0, 100);
    return val;
  }

  int get _mental {
    final val = (_futureScore - ((_stressLevel - 1) * 6).round()).clamp(0, 100);
    return val;
  }

  int get _energy {
    final val = (_futureScore + ((_sleepHours - 6) * 6).round()).clamp(0, 100);
    return val;
  }

  String get _riskLabel {
    if (_futureScore >= 75) return 'LOW';
    if (_futureScore >= 55) return 'MODERATE';
    return 'HIGH';
  }

  Color get _riskColor {
    if (_riskLabel == 'LOW') return const Color(0xFF2E7D32);
    if (_riskLabel == 'MODERATE') return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  // Trajectory points for: now, 1y, 5y, 10y
  List<double> get _trajectory {
    final now = _futureScore.toDouble();

    // growth factor: -1..+1ish depending on score
    final growth = (now - 50.0) / 50.0;

    final y1 = (now + 6.0 * growth).clamp(0.0, 100.0).toDouble();
    final y5 = (now + 14.0 * growth).clamp(0.0, 100.0).toDouble();
    final y10 = (now + 18.0 * growth).clamp(0.0, 100.0).toDouble();

    return <double>[now, y1, y5, y10];
  }

  String get _keyInsight {
    // simple insight logic
    if (_sleepHours < 6.5) {
      return 'Sleep is your biggest lever right now. Adding 45–60 minutes could noticeably lift your score.';
    }
    if (_exerciseMins < 60) {
      return 'A little movement goes far. Two 20-minute walks can improve energy and resilience.';
    }
    if (_stressLevel >= 4) {
      return 'High stress is dragging your future down. A 2-minute breathing reset can shift the trend.';
    }
    return 'You’re on a good track. Keep consistency this week to compound your future score.';
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: No AppBar here (shell already shows it)
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContextCard(),
              const SizedBox(height: 16),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildOutcomeGrid(),
              const SizedBox(height: 18),
              _buildWhatIfCard(),
              const SizedBox(height: 18),
              _buildInsightCard(),
              const SizedBox(height: 18),
              _buildCTA(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_graph, color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on your last 7 days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Updates as you log Today • Confidence: Medium (mock)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final improving = _scoreTrend > 0;
    final trendText = improving
        ? '↗ +$_scoreTrend from last week'
        : _scoreTrend < 0
        ? '↘ ${_scoreTrend.abs()} from last week'
        : '→ 0 from last week';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR FUTURE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_futureScore',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: improving ? const Color(0xFFE8F5E9) : Colors.black12,
                ),
                child: Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: improving
                        ? const Color(0xFF2E7D32)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trajectory chart (mock)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _TrajectoryChart(values: _trajectory),
          ),

          const SizedBox(height: 12),

          // Axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _AxisLabel('Now'),
              _AxisLabel('1y'),
              _AxisLabel('5y'),
              _AxisLabel('10y'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUTCOMES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutcomeCard(
                label: 'Physical',
                value: _physical,
                color: const Color(0xFF2196F3),
                icon: Icons.favorite_border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutcomeCard(
                label: 'Mental',
                value: _mental,
                color: const Color(0xFF00897B),
                icon: Icons.psychology_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutcomeCard(
                label: 'Energy',
                value: _energy,
                color: const Color(0xFFE53935),
                icon: Icons.bolt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RiskCard(
                label: 'Risk',
                value: _riskLabel,
                color: _riskColor,
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhatIfCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT IF…',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Move sliders to preview your future.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          _SliderRow(
            title: 'Sleep',
            subtitle: '${_sleepHours.toStringAsFixed(1)} hours',
            icon: Icons.bedtime_outlined,
            color: const Color(0xFF2196F3),
            value: _sleepHours,
            min: 4,
            max: 10,
            divisions: 24,
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
          const SizedBox(height: 14),
          _SliderRow(
            title: 'Exercise',
            subtitle: '${_exerciseMins.round()} min / week',
            icon: Icons.directions_walk,
            color: const Color(0xFF00897B),
            value: _exerciseMins,
            min: 0,
            max: 180,
            divisions: 18,
            onChanged: (v) => setState(() => _exerciseMins = v),
          ),
          const SizedBox(height: 14),
          _SliderRow(
            title: 'Stress',
            subtitle: _stressLevel <= 2
                ? 'Low'
                : _stressLevel == 3
                ? 'Medium'
                : 'High',
            icon: Icons.mood,
            color: const Color(0xFFE53935),
            value: _stressLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _stressLevel = v),
          ),

          const SizedBox(height: 10),

          // Quick presets (nice UX)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PresetChip(
                text: 'Better Sleep',
                onTap: () => setState(() {
                  _sleepHours = 7.5;
                }),
              ),
              _PresetChip(
                text: 'More Movement',
                onTap: () => setState(() {
                  _exerciseMins = 120;
                }),
              ),
              _PresetChip(
                text: 'Lower Stress',
                onTap: () => setState(() {
                  _stressLevel = 2;
                }),
              ),
              _PresetChip(
                text: 'Reset',
                onTap: () => setState(() {
                  _sleepHours = 6.2;
                  _exerciseMins = 60;
                  _stressLevel = 3;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key insight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _keyInsight,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFE3F2FD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Want a better future score?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Log today’s habits and improve accuracy.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _snack('Go to Today (wire later)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Improve This Future',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- WIDGETS ---------------- */

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _OutcomeCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value/100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RiskCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withOpacity(0.85),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PresetChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
          color: Colors.black.withOpacity(0.03),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Simple custom chart (no external packages)
class _TrajectoryChart extends StatelessWidget {
  final List<double> values; // length 4
  const _TrajectoryChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrajectoryPainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  final List<double> values;
  _TrajectoryPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2196F3);

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2196F3).withOpacity(0.12);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withOpacity(0.06);

    // light grid
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (size.width) * (i / (values.length - 1));
      final v = values[i].clamp(0, 100);
      final y = size.height * (1 - (v / 100));
      points.add(Offset(x, y));
    }

    // smooth path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final cp = Offset((p1.dx + p2.dx) / 2, p1.dy);
      final cp2 = Offset((p1.dx + p2.dx) / 2, p2.dy);
      path.cubicTo(cp.dx, cp.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // fill under curve
    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fill, paintFill);
    canvas.drawPath(path, paintLine);

    // dots
    final dot = Paint()..color = const Color(0xFF2196F3);
    for (final p in points) {
      canvas.drawCircle(p, 4.5, dot);
      canvas.drawCircle(
        p,
        8.5,
        Paint()..color = const Color(0xFF2196F3).withOpacity(0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
