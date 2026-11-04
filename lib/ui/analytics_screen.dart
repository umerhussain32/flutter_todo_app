import 'package:flutter/material.dart';

import '../data/todo_store.dart';

/// Simple progress overview: totals plus a per-category breakdown.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TodoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final total = store.totalCount;
        final done = store.doneCount;
        final pct = total == 0 ? 0.0 : done / total;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Analytics',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: store.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: pct,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                  Center(
                                    child: Text(
                                      '${(pct * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$done of $total tasks completed',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total',
                            value: '$total',
                            icon: Icons.list_alt,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Done',
                            value: '$done',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: '${store.pendingCount}',
                            icon: Icons.pending_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'By category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final c in store.categories.where((c) => !c.isAll))
                      _CategoryRow(
                        name: c.name,
                        done: store.doneByCategory[c.id] ?? 0,
                        total: store.totalByCategory[c.id] ?? 0,
                      ),
                    _CategoryRow(
                      name: 'Uncategorised',
                      done: store.doneByCategory[null] ?? 0,
                      total: store.totalByCategory[null] ?? 0,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0066CC)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final int done;
  final int total;
  const _CategoryRow({required this.name, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$done/$total',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}
