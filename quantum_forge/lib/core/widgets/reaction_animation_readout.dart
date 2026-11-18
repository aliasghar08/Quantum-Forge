// ignore_for_file: invalid_use_of_protected_member
part of 'reaction_animation_widget.dart';

extension _ReactionAnimationReadoutExt on _ReactionAnimationWidgetState {
  Widget _buildReadout() {
      final energy = _energyAtFrame;
      final absolute = _absoluteEnergyAtFrame;
      final isMobile = MediaQuery.of(context).size.width < 500;

      return Padding(
        padding: EdgeInsets.fromLTRB(isMobile ? 10 : 16, 4, isMobile ? 10 : 16, 2),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _infoItem('Frame', '${_frame + 1} / $_frameCount'),
                SizedBox(width: isMobile ? 10 : 16),
                if (energy != null) ...[
                  _infoItem('Energy', '${energy.toStringAsFixed(2)} kcal·mol⁻¹'),
                  SizedBox(width: isMobile ? 10 : 16),
                ],
                if (absolute != null) ...[
                  _infoItem('MLIP E', '${absolute.toStringAsFixed(4)} eV'),
                  SizedBox(width: isMobile ? 10 : 16),
                ],
                _infoItem('Progress', '${_progressPercent.toStringAsFixed(1)}%'),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem('Status', _playing ? 'Playing' : 'Stopped'),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem('Speed', '$_effectiveFrameRate FPS'),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem('Cycle', '${_cycleSeconds.toStringAsFixed(1)} s'),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem('Loop', _loopMode.name),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem(
                  'TS frame',
                  '${_transitionStateFrame + 1} / $_frameCount',
                ),
                SizedBox(width: isMobile ? 10 : 16),
                _infoItem('Bonds', '${_bondsForCurrentFrame().length}'),
              ],
            ),
          ),
        ),
      );
    }

  Widget _infoItem(String label, String value) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

  List<PerceivedBond> _bondsForCurrentFrame() {
      if (!_dynamicBonding) return _staticBonds;
      final atoms = _atomsAt(_frame);
      if (atoms.isEmpty) return const <PerceivedBond>[];
      return AvogadroBondPerception.perceive(atoms);
    }

}
