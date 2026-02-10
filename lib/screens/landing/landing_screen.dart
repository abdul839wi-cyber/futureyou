import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        const Icon(Icons.auto_graph, size: 26),
                        const SizedBox(width: 10),
                        const Text(
                          'FutureYou',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _openLogin(context),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Hero
                    Text(
                      'Your health, made visible.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Track in seconds. See the future impact of today’s habits — without journaling or chatbots.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Benefit chips (short, punchy)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _Chip(text: '30 sec / day'),
                        _Chip(text: 'No journaling'),
                        _Chip(text: 'No chatbot'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Visual preview card (feels like product, not docs)
                    _PreviewCard(),

                    const SizedBox(height: 18),

                    // 3 feature highlights only (no “documentation grid”)
                    const Text(
                      'Why people use it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const _FeatureRow(
                      icon: Icons.timeline,
                      title: 'Future Simulator',
                      subtitle: 'Move sliders. Watch your future score change.',
                    ),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                      icon: Icons.today,
                      title: 'Daily Check-In',
                      subtitle: 'Sleep • Exercise • Meals • Mind — done fast.',
                    ),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                      icon: Icons.lightbulb_outline,
                      title: 'Invisible Insights',
                      subtitle:
                          'Spot patterns and leverage points automatically.',
                    ),

                    const SizedBox(height: 18),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => _openLogin(context),
                        child: const Text('Get Started'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Not medical advice. Built to help you understand patterns.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
        color: Colors.black.withOpacity(0.03),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: cs.primary.withOpacity(0.10),
                  border: Border.all(color: cs.primary.withOpacity(0.18)),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Future Score',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          // Fake score bar (looks like a UI element)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              color: Colors.black.withOpacity(0.06),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.67,
                  child: Container(color: cs.primary.withOpacity(0.70)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                '67/100',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withOpacity(0.04),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Text(
                  '↗ +3 this week',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // One-liner insight (short)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.03),
              border: Border.all(color: Colors.black12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You sleep better after exercise days.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.3),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        color: Colors.black.withOpacity(0.02),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.black87,
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
