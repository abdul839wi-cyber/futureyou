import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic>? _dailyRhythms;
  Map<String, dynamic>? _stressZones;

  late final String _dateId;
  late final String _dateLine;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateId = DateFormat('yyyy-MM-dd').format(now);
    _dateLine = DateFormat('EEEE, MMMM d, y').format(now);

    _loadToday();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _dailyRhythms = null;
          _stressZones = null;
        });
      }
      return;
    }

    try {
      final drRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('dailyRhythms')
          .doc(_dateId);

      final szRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('stressZones')
          .doc(_dateId);

      final results = await Future.wait([drRef.get(), szRef.get()]);

      final drSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final szSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _dailyRhythms = drSnap.data();
        _stressZones = szSnap.data();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not load today data. (check internet)');
    }
  }

  int get _doneCount {
    int done = 0;
    if (_dailyRhythms != null) done++;
    if (_stressZones != null) done++;
    return done;
  }

  String get _progressText {
    final done = _doneCount;
    if (done == 0) return '0/2 done';
    if (done == 1) return '1/2 done';
    return '2/2 complete ✅';
  }

  double get _progressValue => _doneCount / 2.0;

  Future<void> _openDailyRhythmsSheet() async {
    if (_saving) return;

    final initial = _dailyRhythms;

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DailyRhythmsSheet(dateLine: _dateLine, initial: initial),
    );

    if (result == null) return; // cancelled

    await _saveDailyRhythms(result);
  }

  Future<void> _openStressSheet() async {
    if (_saving) return;

    final initial = _stressZones;

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StressSheet(dateLine: _dateLine, initial: initial),
    );

    if (result == null) return;

    await _saveStressZones(result);
  }

  Future<void> _saveDailyRhythms(Map<String, dynamic> payload) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Not logged in.');
      return;
    }

    setState(() => _saving = true);
    try {
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('dailyRhythms')
          .doc(_dateId);

      final data = <String, dynamic>{
        'date': Timestamp.fromDate(DateTime.now()),
        ...payload,
      };

      await ref.set(data, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _dailyRhythms = data;
        _saving = false;
      });

      _snack('Daily Rhythms saved ✅');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Failed to save. Try again.');
    }
  }

  Future<void> _saveStressZones(Map<String, dynamic> payload) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Not logged in.');
      return;
    }

    setState(() => _saving = true);
    try {
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('stressZones')
          .doc(_dateId);

      final data = <String, dynamic>{
        'date': Timestamp.fromDate(DateTime.now()),
        ...payload,
      };

      await ref.set(data, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _stressZones = data;
        _saving = false;
      });

      _snack('Stress Check saved ✅');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Failed to save. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: no AppBar (shell already provides it)
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadToday,
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

                      Text(
                        'CHECK-IN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _CheckInCard(
                        title: _dailyRhythms == null
                            ? 'Daily Rhythms'
                            : 'Daily Rhythms ✅',
                        subtitle: _dailyRhythms == null
                            ? 'Sleep • Exercise • Meals • Mind (20 sec)'
                            : _dailyRhythmsSummary(_dailyRhythms!),
                        icon: Icons.edit_calendar_outlined,
                        backgroundColor: const Color(0xFFE3F2FD),
                        iconBackgroundColor: const Color(0xFFBBDEFB),
                        iconColor: const Color(0xFF2196F3),
                        actionText: _dailyRhythms == null ? 'Start' : 'Edit',
                        onTap: _openDailyRhythmsSheet,
                        disabled: _saving,
                      ),
                      const SizedBox(height: 12),
                      _CheckInCard(
                        title: _stressZones == null
                            ? 'Stress Check'
                            : 'Stress Check ✅',
                        subtitle: _stressZones == null
                            ? 'Quick mood + trigger (10 sec)'
                            : _stressSummary(_stressZones!),
                        icon: Icons.psychology_outlined,
                        backgroundColor: const Color(0xFFE0F7F4),
                        iconBackgroundColor: const Color(0xFFB2DFDB),
                        iconColor: const Color(0xFF00897B),
                        actionText: _stressZones == null ? 'Start' : 'Edit',
                        onTap: _openStressSheet,
                        disabled: _saving,
                      ),

                      const SizedBox(height: 18),

                      _buildWhyItMatters(),

                      const SizedBox(height: 18),

                      if (_doneCount == 2)
                        _buildDoneCard()
                      else
                        _buildNudgeCard(),

                      const SizedBox(height: 18),

                      if (_saving)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Saving…',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
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
            'Today Check-in',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 10,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFE3F2FD),
                ),
                child: Text(
                  _progressText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '30 seconds. No journaling. Just quick taps.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyItMatters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Today’s inputs update your future curve and insights automatically.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFE8F5E9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You’re done for today ✅',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Nice. This is how habits compound.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  _snack('Future will use today’s data (wire later)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFF2E7D32)),
              ),
              child: const Text(
                'Preview Future Update',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeCard() {
    final missing = _doneCount == 0
        ? 'Start with Daily Rhythms — it’s the biggest signal.'
        : (_dailyRhythms == null
              ? 'Complete Daily Rhythms to improve accuracy.'
              : 'Add a quick Stress Check to spot triggers.');

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
            'Quick tip',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            missing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _dailyRhythmsSummary(Map<String, dynamic> dr) {
    // Keep it short, attractive, not “documentation”
    final sleep = (dr['sleep']?['hours'] ?? dr['sleepHours'] ?? 0).toString();
    final ex = (dr['exercise']?['durationMinutes'] ?? 0).toString();
    final meals = (dr['meals']?['quality'] ?? 0).toString();
    return 'Sleep: ${sleep}h • Exercise: ${ex}m • Meals: ${meals}/5';
    // (We allow multiple shapes in case you tweak schema later)
  }

  String _stressSummary(Map<String, dynamic> sz) {
    final emoji = (sz['stressEmoji'] ?? '🙂').toString();
    final trig = (sz['trigger'] ?? '—').toString();
    return '$emoji • Trigger: $trig';
  }
}

/* ---------------- UI WIDGETS ---------------- */

class _CheckInCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

  final String actionText;
  final VoidCallback onTap;
  final bool disabled;

  const _CheckInCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.actionText,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.75),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- BOTTOM SHEETS ---------------- */

class _DailyRhythmsSheet extends StatefulWidget {
  final String dateLine;
  final Map<String, dynamic>? initial;

  const _DailyRhythmsSheet({required this.dateLine, required this.initial});

  @override
  State<_DailyRhythmsSheet> createState() => _DailyRhythmsSheetState();
}

class _DailyRhythmsSheetState extends State<_DailyRhythmsSheet> {
  double sleepHours = 6.5;
  int sleepQuality = 3;
  bool feltRested = false;

  String exerciseType = 'walk';
  double exerciseMinutes = 20;

  int mealQuality = 3;
  double waterCups = 6;

  bool meditation = false;
  double meditationMinutes = 5;
  double screenTimeHours = 4;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init == null) return;

    // Support both nested schema and flat fallback
    final s = init['sleep'] ?? {};
    sleepHours = (s['hours'] ?? init['sleepHours'] ?? sleepHours).toDouble();
    sleepQuality = (s['quality'] ?? sleepQuality).toInt();
    feltRested = (s['feltRested'] ?? feltRested) as bool;

    final e = init['exercise'] ?? {};
    exerciseType = (e['type'] ?? exerciseType).toString();
    exerciseMinutes = (e['durationMinutes'] ?? exerciseMinutes).toDouble();

    final m = init['meals'] ?? {};
    mealQuality = (m['quality'] ?? mealQuality).toInt();
    waterCups = (m['waterIntake'] ?? waterCups).toDouble();

    final mind = init['mind'] ?? {};
    meditation = (mind['meditation'] ?? meditation) as bool;
    meditationMinutes = (mind['meditationMinutes'] ?? meditationMinutes)
        .toDouble();
    screenTimeHours = (mind['screenTimeHours'] ?? screenTimeHours).toDouble();
  }

  void _save() {
    final payload = <String, dynamic>{
      'sleep': {
        'hours': sleepHours,
        'quality': sleepQuality,
        'feltRested': feltRested,
      },
      'exercise': {
        'type': exerciseType,
        'durationMinutes': exerciseMinutes.round(),
      },
      'meals': {'quality': mealQuality, 'waterIntake': waterCups.round()},
      'mind': {
        'meditation': meditation,
        'meditationMinutes': meditation ? meditationMinutes.round() : 0,
        'screenTimeHours': screenTimeHours,
      },
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Daily Rhythms',
      subtitle: widget.dateLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetSectionTitle('Sleep'),
          _SliderBlock(
            icon: Icons.bedtime_outlined,
            color: const Color(0xFF2196F3),
            title: 'Hours slept',
            valueText: '${sleepHours.toStringAsFixed(1)} h',
            value: sleepHours,
            min: 3.0,
            max: 10.0,
            divisions: 28,
            onChanged: (v) => setState(() => sleepHours = v),
          ),
          const SizedBox(height: 10),
          _ChipsRow<int>(
            title: 'Sleep quality',
            values: const [1, 2, 3, 4, 5],
            labels: const ['1', '2', '3', '4', '5'],
            selected: sleepQuality,
            onSelected: (v) => setState(() => sleepQuality = v),
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            title: 'Felt rested',
            value: feltRested,
            onChanged: (v) => setState(() => feltRested = v),
          ),

          const SizedBox(height: 16),
          const _SheetSectionTitle('Exercise'),
          _ChipsRow<String>(
            title: 'Type',
            values: const ['walk', 'gym', 'sports', 'none'],
            labels: const ['Walk', 'Gym', 'Sports', 'None'],
            selected: exerciseType,
            onSelected: (v) => setState(() => exerciseType = v),
            color: const Color(0xFF00897B),
          ),
          const SizedBox(height: 10),
          _SliderBlock(
            icon: Icons.directions_walk,
            color: const Color(0xFF00897B),
            title: 'Duration',
            valueText: '${exerciseMinutes.round()} min',
            value: exerciseMinutes,
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (v) => setState(() => exerciseMinutes = v),
          ),

          const SizedBox(height: 16),
          const _SheetSectionTitle('Meals'),
          _ChipsRow<int>(
            title: 'Meal quality',
            values: const [1, 2, 3, 4, 5],
            labels: const ['1', '2', '3', '4', '5'],
            selected: mealQuality,
            onSelected: (v) => setState(() => mealQuality = v),
            color: const Color(0xFF8E24AA),
          ),
          const SizedBox(height: 10),
          _SliderBlock(
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF8E24AA),
            title: 'Water',
            valueText: '${waterCups.round()} cups',
            value: waterCups,
            min: 0,
            max: 12,
            divisions: 12,
            onChanged: (v) => setState(() => waterCups = v),
          ),

          const SizedBox(height: 16),
          const _SheetSectionTitle('Mind'),
          _ToggleRow(
            title: 'Meditation',
            value: meditation,
            onChanged: (v) => setState(() => meditation = v),
          ),
          if (meditation) ...[
            const SizedBox(height: 10),
            _SliderBlock(
              icon: Icons.self_improvement,
              color: const Color(0xFF4A90E2),
              title: 'Meditation minutes',
              valueText: '${meditationMinutes.round()} min',
              value: meditationMinutes,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (v) => setState(() => meditationMinutes = v),
            ),
          ],
          const SizedBox(height: 10),
          _SliderBlock(
            icon: Icons.phone_iphone,
            color: const Color(0xFFE53935),
            title: 'Screen time',
            valueText: '${screenTimeHours.toStringAsFixed(1)} h',
            value: screenTimeHours,
            min: 0,
            max: 12,
            divisions: 24,
            onChanged: (v) => setState(() => screenTimeHours = v),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
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
                'Save',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StressSheet extends StatefulWidget {
  final String dateLine;
  final Map<String, dynamic>? initial;

  const _StressSheet({required this.dateLine, required this.initial});

  @override
  State<_StressSheet> createState() => _StressSheetState();
}

class _StressSheetState extends State<_StressSheet> {
  int stressLevel = 3; // 1..5
  String emoji = '😐';
  String? trigger; // work/relationships/health/money/other
  bool? controllable; // null until selected
  bool tookBreathing = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init == null) return;

    stressLevel = (init['stressLevel'] ?? stressLevel).toInt();
    emoji = (init['stressEmoji'] ?? emoji).toString();
    trigger = init['trigger'] as String?;
    controllable = init['controllable'] as bool?;
    tookBreathing = (init['tookBreathingExercise'] ?? tookBreathing) as bool;
  }

  void _selectStress(int level, String e) {
    setState(() {
      stressLevel = level;
      emoji = e;
    });
  }

  void _save() {
    final payload = <String, dynamic>{
      'stressLevel': stressLevel,
      'stressEmoji': emoji,
      'trigger': trigger,
      'controllable': controllable,
      'tookBreathingExercise': tookBreathing,
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Stress Check',
      subtitle: widget.dateLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetSectionTitle('How do you feel right now?'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _EmojiChoice(
                  emoji: '😌',
                  label: 'Calm',
                  selected: stressLevel == 1,
                  color: const Color(0xFF2E7D32),
                  onTap: () => _selectStress(1, '😌'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmojiChoice(
                  emoji: '🙂',
                  label: 'Fine',
                  selected: stressLevel == 2,
                  color: const Color(0xFF558B2F),
                  onTap: () => _selectStress(2, '🙂'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmojiChoice(
                  emoji: '😐',
                  label: 'Meh',
                  selected: stressLevel == 3,
                  color: const Color(0xFFF9A825),
                  onTap: () => _selectStress(3, '😐'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmojiChoice(
                  emoji: '😟',
                  label: 'Stressed',
                  selected: stressLevel == 4,
                  color: const Color(0xFFEF6C00),
                  onTap: () => _selectStress(4, '😟'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmojiChoice(
                  emoji: '😰',
                  label: 'Over',
                  selected: stressLevel == 5,
                  color: const Color(0xFFC62828),
                  onTap: () => _selectStress(5, '😰'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const _SheetSectionTitle('What triggered it?'),
          const SizedBox(height: 10),

          _ChipWrap(
            values: const ['work', 'relationships', 'health', 'money', 'other'],
            labels: const ['Work', 'Relationships', 'Health', 'Money', 'Other'],
            selected: trigger,
            color: const Color(0xFF00897B),
            onSelected: (v) => setState(() => trigger = v),
          ),

          const SizedBox(height: 16),
          const _SheetSectionTitle('Was it controllable?'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _BinaryChip(
                  text: 'Yes',
                  selected: controllable == true,
                  color: const Color(0xFF2E7D32),
                  onTap: () => setState(() => controllable = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BinaryChip(
                  text: 'No',
                  selected: controllable == false,
                  color: const Color(0xFFC62828),
                  onTap: () => setState(() => controllable = false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _ToggleRow(
            title: 'Did a 60-second breathing reset',
            value: tookBreathing,
            onChanged: (v) => setState(() => tookBreathing = v),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SHEET LAYOUT HELPERS ---------------- */

class _SheetScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String text;
  const _SheetSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.03),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.valueText,
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
        border: Border.all(color: color.withOpacity(0.15)),
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
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                valueText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.7),
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

class _ChipsRow<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color color;

  const _ChipsRow({
    required this.title,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.black.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(values.length, (i) {
            final v = values[i];
            final isSel = v == selected;
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isSel
                      ? color.withOpacity(0.16)
                      : Colors.black.withOpacity(0.03),
                  border: Border.all(
                    color: isSel
                        ? color.withOpacity(0.35)
                        : Colors.black.withOpacity(0.10),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isSel ? color : Colors.black.withOpacity(0.75),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelected;

  const _ChipWrap({
    required this.values,
    required this.labels,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(values.length, (i) {
        final v = values[i];
        final isSel = v == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onSelected(v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSel
                  ? color.withOpacity(0.16)
                  : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: isSel
                    ? color.withOpacity(0.35)
                    : Colors.black.withOpacity(0.10),
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: isSel ? color : Colors.black.withOpacity(0.75),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BinaryChip extends StatelessWidget {
  final String text;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _BinaryChip({
    required this.text,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? color.withOpacity(0.14)
              : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.35)
                : Colors.black.withOpacity(0.10),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? color : Colors.black.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _EmojiChoice({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? color.withOpacity(0.10)
              : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.35)
                : Colors.black.withOpacity(0.10),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: selected ? color : Colors.black.withOpacity(0.65),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
