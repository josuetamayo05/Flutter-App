import 'package:flutter/material.dart';
import '../../models/event_type.dart';
import 'package:uuid/uuid.dart';

typedef EventTypeSave = Future<void> Function(EventType item);

class EventTypeFormSheet extends StatefulWidget {
  final EventType? initial;
  final EventTypeSave onSave;

  const EventTypeFormSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<EventTypeFormSheet> createState() => _EventTypeFormSheetState();
}

class _EventTypeFormSheetState extends State<EventTypeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late final TextEditingController _price;

  String _colorHex = '#00E5FF';
  bool _active = true;

  final _colors = const [
    '#00E5FF',
    '#7C4DFF',
    '#22C55E',
    '#F97316',
    '#EF4444',
    '#06B6D4',
    '#E11D48',
    '#A3E635',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _duration = TextEditingController(text: (i?.durationMinutes ?? 30).toString());
    _price = TextEditingController(text: i?.priceCents != null ? (i!.priceCents! / 100).toStringAsFixed(2) : '');
    _colorHex = i?.colorHex ?? _colorHex;
    _active = i?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.parse(_duration.text.trim());
    final priceTxt = _price.text.trim();
    final priceCents = priceTxt.isEmpty ? null : (double.parse(priceTxt) * 100).round();

    final base = widget.initial;

    final item = EventType(
      id: base?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      durationMinutes: duration,
      colorHex: _colorHex,
      priceCents: priceCents,
      active: _active,
      sortOrder: base?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
    );

    await widget.onSave(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? 'Nuevo tipo de evento' : 'Editar tipo de evento',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duración (min)',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      final n = int.tryParse(t);
                      if (n == null || n <= 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio (opcional)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((hex) {
                final selected = hex == _colorHex;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white10,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Activo'),
              subtitle: const Text('Si está desactivado no aparece para crear citas'),
            ),

            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }
}

extension _CopyEventType on EventType {
  EventType copyWith({String? id, int? sortOrder}) => EventType(
        id: id ?? this.id,
        name: name,
        durationMinutes: durationMinutes,
        colorHex: colorHex,
        priceCents: priceCents,
        active: active,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}