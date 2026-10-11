import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/reaction_workspace_viewmodel.dart';

class MobileArrheniusChart extends StatelessWidget {
  const MobileArrheniusChart({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth <= 390;
    final tickInterval = isNarrow ? 300 : 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Arrhenius Plot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'Ea = ${vm.activationEnergyEa} ±${vm.eaUncertainty} kcal/mol',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 11, color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Rate: k(T) = ${vm.rateConstant} s⁻¹',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dynamic tick density (interval: ${tickInterval}K)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 10),
                // Dynamic tick markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: isNarrow
                      ? const [
                          _TickLabel(temp: '300 K', label: '3.33'),
                          _TickLabel(temp: '600 K', label: '1.67'),
                          _TickLabel(temp: '900 K', label: '1.11'),
                        ]
                      : const [
                          _TickLabel(temp: '300 K', label: '3.33'),
                          _TickLabel(temp: '400 K', label: '2.50'),
                          _TickLabel(temp: '500 K', label: '2.00'),
                          _TickLabel(temp: '600 K', label: '1.67'),
                          _TickLabel(temp: '700 K', label: '1.43'),
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TickLabel extends StatelessWidget {
  final String temp;
  final String label;

  const _TickLabel({required this.temp, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          temp,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
