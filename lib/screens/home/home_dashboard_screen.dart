import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentInsightIndex = 0;
  final PageController _insightPageController = PageController(
    viewportFraction: 0.92,
  );

  Timer? _autoTimer;

  // Mock data - later fetch from Firestore
  final int _futureScore = 67;
  final int _scoreTrend = 3;

  final bool _todayLogged = false;
  final bool _stressChecked = false;

  final bool _hasActiveExperiment = true;
  final int _experimentProgress = 4;
  final int _experimentTotal = 7;
  final int _experimentStreak = 2;

  final List<Map<String, dynamic>> _insights = [
    {
      'type': 'leverage',
      'icon': Icons.trending_up,
      'iconColor': Color(0xFF4A90E2),
      'title': 'Highest Impact Action',
      'message':
          'Improving sleep from 5.8h → 7h could raise your Future Score by +8 points.',
      'detail': 'This is your biggest opportunity right now.',
      'action': 'Start Sleep Experiment',
    },
    {
      'type': 'pattern',
      'icon': Icons.lightbulb_outline,
      'iconColor': Colors.amber,
      'title': 'Pattern Detected',
      'message': 'You sleep better on days you exercise.',
      'detail':
          'Exercise days: 4.2/5 sleep quality\nRest days: 3.1/5 sleep quality',
      'action': 'View Pattern Details',
    },
    {
      'type': 'achievement',
      'icon': Icons.celebration_outlined,
      'iconColor': Colors.green,
      'title': 'Great Week!',
      'message': 'You logged habits 6/7 days this week.',
      'detail':
          'That\'s a 14% improvement from last week! Your consistency is paying off.',
      'action': 'Keep Going',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Auto-rotate insights every 8 seconds
    _autoTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final next = (_currentInsightIndex + 1) % _insights.length;
      _insightPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _insightPageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.split(' ').first
        : 'there';

    final dateLine = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Scaffold(
      // IMPORTANT:
      // ✅ No AppBar here — your router/shell already provides "Home" + logout.
      // This fixes the "double Home" and duplicate logout button.
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 700));
            if (mounted) _snack('Dashboard refreshed (mock)');
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Greeting (no "Home" title here)
                _buildGreetingHeader(name: name, dateLine: dateLine),

                const SizedBox(height: 16),

                // (Optional) Future score hero (compact) — feels functional
                _buildFutureScoreHero(),

                const SizedBox(height: 18),

                // Quick Actions (2x2)
                _buildQuickActionsGrid(),

                const SizedBox(height: 24),

                // Insight Carousel (overflow fixed)
                _buildInsightCarousel(),

                const SizedBox(height: 24),

                // Active Experiment
                if (_hasActiveExperiment)
                  _buildActiveExperiment()
                else
                  _buildExperimentSuggestion(),

                const SizedBox(height: 24),

                // Week Ahead Preview (overflow fixed)
                _buildWeekAheadPreview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader({
    required String name,
    required String dateLine,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            '${_getGreeting()}, $name! ☀️',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateLine,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _snack('Today’s Focus (mock)'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFE3F2FD),
              ),
              child: Row(
                children: [
                  const Text(
                    'Today’s Focus: 💤 Better Sleep',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '(Based on your active experiment)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureScoreHero() {
    final improving = _scoreTrend > 0;
    final trendText = improving
        ? '↗ +$_scoreTrend from last week'
        : _scoreTrend < 0
        ? '↘ ${_scoreTrend.abs()} from last week'
        : '→ 0 from last week';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _snack('Open Future Simulator (mock)'),
      child: Container(
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
          children: [
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR FUTURE SCORE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_futureScore',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFE8F5E9),
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
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
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
              child: _QuickActionCard(
                icon: Icons.edit_calendar_outlined,
                title: _todayLogged ? 'Edit Today' : 'Log Today',
                subtitle: '30 sec',
                isCompleted: _todayLogged,
                backgroundColor: const Color(0xFFE3F2FD),
                iconBackgroundColor: const Color(0xFFBBDEFB),
                iconColor: const Color(0xFF2196F3),
                onTap: () => _snack('Opening Daily Rhythms (mock)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.psychology_outlined,
                title: 'Check Stress',
                subtitle: _stressChecked ? 'Logged' : 'Quick',
                isCompleted: _stressChecked,
                backgroundColor: const Color(0xFFE0F7F4),
                iconBackgroundColor: const Color(0xFFB2DFDB),
                iconColor: const Color(0xFF00897B),
                onTap: _showStressCheckIn,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.upload_file_outlined,
                title: 'Upload Doc',
                subtitle: 'Timeline',
                isCompleted: false,
                backgroundColor: const Color(0xFFF3E5F5),
                iconBackgroundColor: const Color(0xFFE1BEE7),
                iconColor: const Color(0xFF8E24AA),
                onTap: () => _snack('Opening Medical Timeline (mock)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.science_outlined,
                title: 'Experiment',
                subtitle: 'Lab',
                isCompleted: false,
                backgroundColor: const Color(0xFFFFEBEE),
                iconBackgroundColor: const Color(0xFFFFCDD2),
                iconColor: const Color(0xFFE53935),
                onTap: () => _snack('Opening Action Lab (mock)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showStressCheckIn() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StressCheckInModal(),
    );
  }

  /// ✅ Overflow fix:
  /// - Increased carousel height slightly
  /// - Insight card text is now constrained (maxLines + ellipsis)
  /// - Added CTA row inside card to avoid “extra space” causing overflow
  Widget _buildInsightCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSIGHTS FOR YOU',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // was 220 -> reduces bottom overflow on smaller screens
          child: PageView.builder(
            controller: _insightPageController,
            onPageChanged: (index) =>
                setState(() => _currentInsightIndex = index),
            itemCount: _insights.length,
            itemBuilder: (context, index) {
              final insight = _insights[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _InsightCard(
                  icon: insight['icon'],
                  iconColor: insight['iconColor'],
                  title: insight['title'],
                  message: insight['message'],
                  detail: insight['detail'],
                  action: insight['action'],
                  onTap: () => _snack('${insight['action']} (mock)'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _insights.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentInsightIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentInsightIndex == index
                    ? const Color(0xFF2196F3)
                    : Colors.black.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveExperiment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR ACTIVE EXPERIMENT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bedtime,
                      color: Color(0xFF2196F3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7-Day Early Sleep\nChallenge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Goal: In bed by 11pm',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '$_experimentProgress/$_experimentTotal days',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: _experimentProgress / _experimentTotal,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2196F3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Streak + impact row (overflow-safe)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              '$_experimentStreak day streak',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: const [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '+8 Mental Resilience',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showExperimentCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Check In Today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExperimentCheckIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '7-Day Early Sleep Challenge',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did you make it to bed by 11pm last night?',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _snack('Better luck tonight! 💪');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '❌ No',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _snack('Great job! 🎉 Keep the streak going!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '✅ Yes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperimentSuggestion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try an Experiment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Small changes, big impact.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _snack('Opening Action Lab (mock)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Experiment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Overflow fix:
  /// - Metric cards now use FittedBox for the number row
  /// - Removes right overflow on small screens
  Widget _buildWeekAheadPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR WEEK AHEAD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
                'If you maintain current habits:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: const [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Physical',
                      current: 68,
                      projected: 69,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  SizedBox(width: 10), // slightly reduced
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Mental',
                      current: 54,
                      projected: 56,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  SizedBox(width: 10), // slightly reduced
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Energy',
                      current: 72,
                      projected: 73,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Small improvements adding up!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _snack('Opening Future Simulator (mock)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF2196F3)),
                  ),
                  child: const Text(
                    'Adjust Your Future',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2196F3),
                    ),
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

/* ---------------- WIDGETS ---------------- */

// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
            border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Insight Card (overflow-safe)
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String detail;
  final String action;
  final VoidCallback onTap;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.detail,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.65),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2196F3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF2196F3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Mini Metric Card (overflow-safe)
class _MiniMetricCard extends StatelessWidget {
  final String label;
  final int current;
  final int projected;
  final Color color;

  const _MiniMetricCard({
    required this.label,
    required this.current,
    required this.projected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // slightly reduced
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ✅ This prevents RIGHT OVERFLOW on small screens
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$current',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: color.withOpacity(0.6),
                  ),
                ),
                Text(
                  '$projected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color.withOpacity(0.75),
                    height: 1,
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

// Stress Check-In Modal
class _StressCheckInModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final options = const [
      {'emoji': '😌', 'label': 'Calm', 'color': Color(0xFF4CAF50)},
      {'emoji': '🙂', 'label': 'Fine', 'color': Color(0xFF8BC34A)},
      {'emoji': '😐', 'label': 'Meh', 'color': Color(0xFFFFC107)},
      {'emoji': '😟', 'label': 'Stressed', 'color': Color(0xFFFF9800)},
      {'emoji': '😰', 'label': 'Overwhelmed', 'color': Color(0xFFF44336)},
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'How\'s your stress right now?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              ...options.map((option) {
                final c = option['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Logged. You\'re feeling ${(option['label'] as String).toLowerCase()}.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                          width: 1.5,
                        ),
                        color: c.withOpacity(0.08),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option['emoji'] as String,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option['label'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
