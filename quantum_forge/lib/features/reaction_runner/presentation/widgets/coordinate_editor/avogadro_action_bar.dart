import 'package:flutter/material.dart';
import 'package:quantum_forge/core/settings/app_settings_provider.dart';
import 'package:quantum_forge/core/theme/quantum_theme.dart';

/// The structure title editor field with live update synchronization.
class TitleField extends StatefulWidget {
  final String initialValue;
  final QuantumTheme palette;
  final ValueChanged<String> onChanged;

  const TitleField({
    super.key,
    required this.initialValue,
    required this.palette,
    required this.onChanged,
  });

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(covariant TitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync when the title changes from an import, without fighting the
    // user's cursor while they type.
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: TextStyle(color: widget.palette.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Structure title',
          labelStyle: TextStyle(color: widget.palette.textMuted, fontSize: 12),
          prefixIcon: Icon(
            Icons.label_outline,
            size: 16,
            color: widget.palette.textMuted,
          ),
        ),
      ),
    );
  }
}

/// The Avogadro-specific half of the header: export, hand-off, MD simulation and clipboard.
class AvogadroActionBar extends StatelessWidget {
  final QuantumTheme palette;
  final AppSettings settings;
  final int atomCount;
  final int bondCount;
  final void Function(String format) onExport;
  final VoidCallback onSendToAvogadro;
  final VoidCallback onSimulateHybridMd;
  final void Function(String format) onCopy;

  const AvogadroActionBar({
    super.key,
    required this.palette,
    required this.settings,
    required this.atomCount,
    required this.bondCount,
    required this.onExport,
    required this.onSendToAvogadro,
    required this.onSimulateHybridMd,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                'Avogadro 2 bridge',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            '$atomCount atoms · $bondCount bonds · ${settings.defaultExportFormat.shortLabel} default',
            style: TextStyle(color: palette.textMuted, fontSize: 11.5),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onSendToAvogadro,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send to Avogadro'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
          ),
          FilledButton.icon(
            onPressed: onSimulateHybridMd,
            icon: const Icon(Icons.science, size: 16),
            label: const Text('Run Molecular Dynamics (Hybrid ML/MM)'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              foregroundColor: Colors.white,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Export structure',
            onSelected: onExport,
            color: palette.panelAlt,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'cjson',
                child: Text('CJSON — native Avogadro 2'),
              ),
              PopupMenuItem(value: 'cml', child: Text('CML — XML')),
              PopupMenuItem(value: 'sdf', child: Text('SDF / MOL V2000')),
              PopupMenuItem(
                value: 'xyz',
                child: Text('XYZ — cartesian coordinates'),
              ),
            ],
            child: OutlinedAction(
              palette: palette,
              icon: Icons.ios_share,
              label: 'Export…',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Copy to clipboard',
            onSelected: onCopy,
            color: palette.panelAlt,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'cjson', child: Text('Copy CJSON')),
              PopupMenuItem(value: 'cml', child: Text('Copy CML')),
              PopupMenuItem(value: 'xyz', child: Text('Copy XYZ')),
            ],
            child: OutlinedAction(
              palette: palette,
              icon: Icons.content_copy,
              label: 'Copy…',
            ),
          ),
        ],
      ),
    );
  }
}

class OutlinedAction extends StatelessWidget {
  final QuantumTheme palette;
  final IconData icon;
  final String label;

  const OutlinedAction({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
        color: palette.panelAlt,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: palette.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class EditorErrorBanner extends StatelessWidget {
  final String message;
  final QuantumTheme palette;

  const EditorErrorBanner({
    super.key,
    required this.message,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.danger.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: palette.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: palette.textPrimary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

