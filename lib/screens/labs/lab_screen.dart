// lib/screens/lab/lab_screen.dart
//
// FutureYou — Experiments Lab (refined MVP)
// - Matches Home UI vibe (soft cards, pastel accents, clean hierarchy)
// - One active experiment at a time
// - Today’s action + 1-tap check-in (Done / Missed)
// - Recommended experiments (only 2–3) when no active experiment (or show as “Next up”)
// - Past experiments list (completed/abandoned)
// - Wired to Firestore: users/{uid}/experiments/{experimentId}
//
// NOTE:
// - This is MVP-safe. It uses simple fields compatible with your schema.
// - Daily check-ins stored as an ARRAY of {date: Timestamp, completed: bool}.
// - It also stores quick “streak” and “progress” client-side computed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  bool _busy = false;

  Map<String, dynamic>? _activeExp; // experiment doc data + id injected
  List<Map<String, dynamic>> _past = []; // completed/abandoned

  late final String _todayId;
  late final DateTime _today;
  late final String _dateLine;

  // Recommended templates (MVP)
  final List<_ExperimentTemplate> _templates = const [
    _ExperimentTemplate(
      title: '7-Day Early Sleep Challenge',
      type: 'sleep',
      durationDays: 7,
      goal: 'In bed by 11:00 pm',
      metric: 'Mental Resilience',
      changePoints: 8,
      color: Color(0xFFE3F2FD),
      iconColor: Color(0xFF2196F3),
      icon: Icons.bedtime_outlined,
      effortLabel: '30 sec/day',
      why: 'Chosen when sleep is your biggest leverage.',
    ),
    _ExperimentTemplate(
      title: '10-Min Walk (Daily)',
      type: 'exercise',
      durationDays: 7,
      goal: 'Walk 10 minutes anytime',
      metric: 'Energy',
      changePoints: 6,
      color: Color(0xFFE0F7F4),
      iconColor: Color(0xFF00897B),
      icon: Icons.directions_walk,
      effortLabel: '1 min/day',
      why: 'Boosts energy and sleep quality with minimal effort.',
    ),
    _ExperimentTemplate(
      title: '60-Second Breathing Reset',
      type: 'stress',
      durationDays: 7,
      goal: 'One 60s reset when stressed',
      metric: 'Mental Resilience',
      changePoints: 5,
      color: Color(0xFFFFEBEE),
      iconColor: Color(0xFFE53935),
      icon: Icons.spa_outlined,
      effortLabel: '60 sec/day',
      why: 'Best when stress spikes are the pattern.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _todayId = DateFormat('yyyy-MM-dd').format(_today);
    _dateLine = DateFormat('EEEE, MMMM d, y').format(_today);

    _load();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _activeExp = null;
        _past = [];
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final q = await _db
          .collection('users')
          .doc(user.uid)
          .collection('experiments')
          .orderBy('startDate', descending: true)
          .get();

      Map<String, dynamic>? active;
      final past = <Map<String, dynamic>>[];

      for (final doc in q.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'active').toString();
        final withId = <String, dynamic>{...data, '_id': doc.id};

        if (status == 'active' && active == null) {
          active = withId;
        } else {
          past.add(withId);
        }
      }

      if (!mounted) return;
      setState(() {
        _activeExp = active;
        _past = past;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not load experiments. Check internet.');
    }
  }

  // ---------- Computed helpers ----------

  bool get _hasActive => _activeExp != null;

  DateTime? _tsToDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  List<Map<String, dynamic>> _checkInsOf(Map<String, dynamic> exp) {
    final list = exp['dailyCheckIns'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  bool _didCheckInToday(Map<String, dynamic> exp) {
    final checkIns = _checkInsOf(exp);
    for (final c in checkIns) {
      final d = _tsToDate(c['date']);
      if (d == null) continue;
      final id = DateFormat('yyyy-MM-dd').format(d);
      if (id == _todayId) return true;
    }
    return false;
  }

  bool? _todayCompleted(Map<String, dynamic> exp) {
    final checkIns = _checkInsOf(exp);
    for (final c in checkIns) {
      final d = _tsToDate(c['date']);
      if (d == null) continue;
      final id = DateFormat('yyyy-MM-dd').format(d);
      if (id == _todayId) return (c['completed'] as bool?);
    }
    return null;
  }

  int _completedCount(Map<String, dynamic> exp) {
    final checkIns = _checkInsOf(exp);
    int count = 0;
    for (final c in checkIns) {
      if ((c['completed'] as bool?) == true) count++;
    }
    return count;
  }

  int _streak(Map<String, dynamic> exp) {
    // Simple: count consecutive "completed: true" days ending at today or yesterday
    final checkIns = _checkInsOf(exp)
      ..sort((a, b) {
        final ad = _tsToDate(a['date']) ?? DateTime(1970);
        final bd = _tsToDate(b['date']) ?? DateTime(1970);
        return bd.compareTo(ad); // descending
      });

    int streak = 0;
    DateTime cursor = DateTime(_today.year, _today.month, _today.day);

    for (final c in checkIns) {
      final d = _tsToDate(c['date']);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);

      // If entry is for the current cursor day
      if (day == cursor) {
        if ((c['completed'] as bool?) == true) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return streak;
  }

  int _durationDays(Map<String, dynamic> exp) {
    final start = _tsToDate(exp['startDate']);
    final end = _tsToDate(exp['endDate']);
    if (start == null || end == null) return 7;
    final d = end.difference(start).inDays;
    return (d <= 0) ? 7 : d;
  }

  int _elapsedDays(Map<String, dynamic> exp) {
    final start = _tsToDate(exp['startDate']);
    if (start == null) return 0;
    final s = DateTime(start.year, start.month, start.day);
    final t = DateTime(_today.year, _today.month, _today.day);
    final d = t.difference(s).inDays + 1; // include today
    return d.clamp(0, 999);
  }

  int _daysLeft(Map<String, dynamic> exp) {
    final total = _durationDays(exp);
    final elapsed = _elapsedDays(exp);
    final left = total - elapsed;
    return left < 0 ? 0 : left;
  }

  double _progress(Map<String, dynamic> exp) {
    final total = _durationDays(exp);
    final done = _completedCount(exp);
    if (total <= 0) return 0;
    return (done / total).clamp(0.0, 1.0);
  }

  String _metricPill(Map<String, dynamic> exp) {
    final pi = exp['predictedImpact'];
    if (pi is Map) {
      final metric = (pi['metric'] ?? 'Score').toString();
      final pts = (pi['changePoints'] ?? 0).toString();
      return '+$pts $metric';
    }
    return '+0 Impact';
  }

  // ---------- Actions ----------

  Future<void> _startExperiment(_ExperimentTemplate t) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Not logged in.');
      return;
    }
    if (_busy) return;
    if (_hasActive) {
      _snack('Finish current experiment before starting a new one.');
      return;
    }

    setState(() => _busy = true);
    try {
      final start = DateTime(_today.year, _today.month, _today.day);
      final end = start.add(Duration(days: t.durationDays));

      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('experiments')
          .doc();

      final data = <String, dynamic>{
        'experimentId': ref.id,
        'title': t.title,
        'type': t.type,
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'goal': t.goal,
        'dailyCheckIns': <Map<String, dynamic>>[],
        'predictedImpact': {'metric': t.metric, 'changePoints': t.changePoints},
        'status': 'active',
      };

      await ref.set(data);

      if (!mounted) return;
      _snack('Experiment started ✅');
      await _load();
    } catch (_) {
      if (!mounted) return;
      _snack('Could not start experiment. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkInToday({required bool completed}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeExp == null) return;
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final id = _activeExp!['_id'] as String;
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('experiments')
          .doc(id);

      // Reload fresh doc to avoid race issues
      final snap = await ref.get();
      final exp = snap.data() ?? {};

      final checkIns = (exp['dailyCheckIns'] is List)
          ? (exp['dailyCheckIns'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      // Remove existing today entry, then add new
      checkIns.removeWhere((c) {
        final d = _tsToDate(c['date']);
        if (d == null) return false;
        return DateFormat('yyyy-MM-dd').format(d) == _todayId;
      });

      checkIns.add({
        'date': Timestamp.fromDate(
          DateTime(_today.year, _today.month, _today.day),
        ),
        'completed': completed,
      });

      await ref.update({'dailyCheckIns': checkIns});

      if (!mounted) return;

      _snack(
        completed ? 'Logged: Done ✅' : 'Logged: Missed — continue tomorrow',
      );
      await _load();

      // Optional: auto-complete experiment when end date passed (MVP-friendly)
      final updated = _activeExp;
      if (updated != null && _daysLeft(updated) == 0) {
        await _completeIfEnded();
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Could not save check-in. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeIfEnded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeExp == null) return;

    final end = _tsToDate(_activeExp!['endDate']);
    if (end == null) return;

    final endDay = DateTime(end.year, end.month, end.day);
    final todayDay = DateTime(_today.year, _today.month, _today.day);

    if (todayDay.isBefore(endDay)) return;

    try {
      final id = _activeExp!['_id'] as String;
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('experiments')
          .doc(id);

      await ref.update({'status': 'completed'});
      _snack('Experiment completed 🎉');
      await _load();
    } catch (_) {
      // ignore for MVP
    }
  }

  Future<void> _abandonActive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeExp == null) return;
    if (_busy) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'End experiment?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('You can start a new one right after.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'End',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final id = _activeExp!['_id'] as String;
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('experiments')
          .doc(id);
      await ref.update({'status': 'abandoned'});
      _snack('Experiment ended.');
      await _load();
    } catch (_) {
      _snack('Could not end experiment.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),

                      if (_hasActive) ...[
                        _buildActiveExperimentCard(_activeExp!),
                        const SizedBox(height: 18),
                        _buildTodayActionCard(_activeExp!),
                        const SizedBox(height: 18),
                        _buildNextUpCard(),
                      ] else ...[
                        _buildStartNudge(),
                        const SizedBox(height: 12),
                        _buildRecommendedSection(),
                      ],

                      const SizedBox(height: 22),
                      _buildPastSection(),

                      if (_busy) ...[
                        const SizedBox(height: 14),
                        _buildBusyBar(),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Text(
            'Experiments Lab',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _dateLine,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tiny, time-boxed challenges that compound into future gains.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveExperimentCard(Map<String, dynamic> exp) {
    final title = (exp['title'] ?? 'Active Experiment').toString();
    final goal = (exp['goal'] ?? '—').toString();
    final total = _durationDays(exp);
    final done = _completedCount(exp);
    final streak = _streak(exp);
    final left = _daysLeft(exp);
    final pill = _metricPill(exp);
    final progress = _progress(exp);

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _abandonActive,
                icon: const Icon(Icons.close),
                tooltip: 'End',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Goal: $goal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _Pill(
                  text: '$done/$total days',
                  color: const Color(0xFFE3F2FD),
                  textColor: const Color(0xFF1565C0),
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  text: left == 0 ? 'Ends today' : '$left days left',
                  color: const Color(0xFFFFF8E1),
                  textColor: const Color(0xFF8D6E00),
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _Pill(
                  text: pill,
                  color: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  text: streak >= 2
                      ? '🔥 $streak-day streak'
                      : 'Build a streak',
                  color: const Color(0xFFFFEBEE),
                  textColor: const Color(0xFFE53935),
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActionCard(Map<String, dynamic> exp) {
    final goal = (exp['goal'] ?? 'Do your experiment action').toString();
    final checked = _didCheckInToday(exp);
    final todayDone = _todayCompleted(exp); // null if not checked

    final statusText = !checked
        ? 'Not logged yet'
        : (todayDone == true
              ? 'Logged: Done ✅'
              : 'Logged: Missed — continue tomorrow');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY’S ACTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _checkInToday(completed: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    foregroundColor: const Color(0xFF1565C0),
                    backgroundColor: Colors.white.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Missed',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _checkInToday(completed: true),
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
                    'Done ✅',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextUpCard() {
    // When active experiment exists, show “Next up” as locked suggestions (no paralysis)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT UP (LOCKED)',
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Finish your current experiment to unlock a new one.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.75),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartNudge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start one tiny experiment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick one action for 7 days. One tap a day. Real compounding.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED FOR YOU',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        ..._templates.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TemplateCard(
              t: t,
              disabled: _busy || _hasActive,
              onTap: () => _showTemplateDetails(t),
            ),
          ),
        ),
      ],
    );
  }

  void _showTemplateDetails(_ExperimentTemplate t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TemplateDetailSheet(
        t: t,
        disabled: _busy || _hasActive,
        onStart: () async {
          Navigator.pop(context);
          await _startExperiment(t);
        },
      ),
    );
  }

  Widget _buildPastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAST EXPERIMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        if (_past.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Text(
              'No past experiments yet.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          )
        else
          Column(
            children: _past
                .take(6)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PastExperimentTile(exp: e),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildBusyBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Working…', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/* ---------------- Components ---------------- */

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _Pill({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _ExperimentTemplate t;
  final bool disabled;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.t,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: t.color,
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.iconColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(t.icon, color: t.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.durationDays} days • ${t.effortLabel}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+${t.changePoints} ${t.metric}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: t.iconColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _TemplateDetailSheet extends StatelessWidget {
  final _ExperimentTemplate t;
  final bool disabled;
  final Future<void> Function() onStart;

  const _TemplateDetailSheet({
    required this.t,
    required this.disabled,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.iconColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(t.icon, color: t.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${t.durationDays} days • ${t.effortLabel}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: t.color,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.goal,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Predicted impact: +${t.changePoints} ${t.metric}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: t.iconColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.why,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.65),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disabled ? null : () => onStart(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    disabled
                        ? 'Finish current experiment first'
                        : 'Start this experiment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One active experiment at a time to avoid decision fatigue.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PastExperimentTile extends StatelessWidget {
  final Map<String, dynamic> exp;

  const _PastExperimentTile({required this.exp});

  DateTime? _ts(dynamic ts) => ts is Timestamp ? ts.toDate() : null;

  @override
  Widget build(BuildContext context) {
    final title = (exp['title'] ?? 'Experiment').toString();
    final status = (exp['status'] ?? 'completed').toString();
    final start = _ts(exp['startDate']);
    final end = _ts(exp['endDate']);

    final dateLine = (start != null && end != null)
        ? '${DateFormat('MMM d').format(start)} → ${DateFormat('MMM d').format(end)}'
        : '—';

    final badgeColor = status == 'completed'
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final badgeText = status == 'completed' ? 'Completed' : 'Ended';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: badgeColor,
            ),
            child: Text(
              badgeText,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateLine,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.6),
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

/* ---------------- Data model ---------------- */

class _ExperimentTemplate {
  final String title;
  final String type;
  final int durationDays;
  final String goal;
  final String metric;
  final int changePoints;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String effortLabel;
  final String why;

  const _ExperimentTemplate({
    required this.title,
    required this.type,
    required this.durationDays,
    required this.goal,
    required this.metric,
    required this.changePoints,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.effortLabel,
    required this.why,
  });
}
