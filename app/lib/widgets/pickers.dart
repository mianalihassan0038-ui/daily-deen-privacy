import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/cities.dart';
import '../services/location.dart';
import 'common.dart';

/// Bottom sheet with a searchable city list. Returns the city index.
Future<int?> showCityPicker(BuildContext context, AppState state) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => _CityPicker(state: state),
  );
}

class _CityPicker extends StatefulWidget {
  final AppState state;
  const _CityPicker({required this.state});

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = widget.state.s;
    final q = _q.toLowerCase();
    final list = [
      for (var i = 0; i < cities.length; i++)
        if (q.isEmpty || cities[i].name.toLowerCase().contains(q) || cities[i].country.toLowerCase().contains(q)) i,
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (c, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s.t('search_city')),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: list.length,
              itemBuilder: (c, i) {
                final idx = list[i];
                final selected = !widget.state.settings.useCustomLocation && idx == widget.state.settings.cityIndex;
                return ListTile(
                  title: Text(cities[idx].name),
                  subtitle: Text(cities[idx].country),
                  trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () => Navigator.pop(c, idx),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Selects a listed city and saves it.
Future<void> pickCity(BuildContext context, AppState state) async {
  final idx = await showCityPicker(context, state);
  if (idx == null) return;
  state.settings.cityIndex = idx;
  state.settings.useCustomLocation = false;
  state.saveSettings(reschedule: true);
}

/// Uses GPS to set the location. Shows a message on failure.
Future<bool> useDeviceLocation(BuildContext context, AppState state) async {
  final s = state.s;
  try {
    final loc = await currentLocation();
    state.settings
      ..useCustomLocation = true
      ..customLat = loc.lat
      ..customLng = loc.lng
      ..customLocationName = loc.name;
    state.saveSettings(reschedule: true);
    if (context.mounted) toast(context, '${s.t('location_set')}: ${state.settings.locationName}');
    return true;
  } on LocationException catch (e) {
    if (!context.mounted) return false;
    final msg = switch (e.error) {
      LocationError.serviceDisabled => s.t('loc_service_off'),
      LocationError.denied => s.t('loc_denied'),
      LocationError.deniedForever => s.t('loc_denied_forever'),
      LocationError.failed => s.t('loc_failed'),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      action: e.error == LocationError.deniedForever
          ? SnackBarAction(label: s.t('open_settings'), onPressed: openAppSettings)
          : e.error == LocationError.serviceDisabled
              ? SnackBarAction(label: s.t('open_settings'), onPressed: openLocationSettings)
              : null,
    ));
    return false;
  }
}

/// Number input dialog. Returns null when cancelled.
Future<int?> askNumber(BuildContext context, AppState state, String title, {int? initial, int min = 1, int max = 100000}) async {
  final s = state.s;
  final ctrl = TextEditingController(text: initial?.toString() ?? '');
  final key = GlobalKey<FormState>();
  final result = await showDialog<int>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null) return s.t('enter_number');
            if (n < min || n > max) return '${s.t('between')} $min – $max';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(s.t('cancel'))),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(c, int.parse(ctrl.text.trim()));
          },
          child: Text(s.t('save')),
        ),
      ],
    ),
  );
  return result;
}

/// Asks for confirmation. Returns true when confirmed.
Future<bool> confirm(BuildContext context, AppState state, String title, {String? message}) async {
  final s = state.s;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('ok'))),
      ],
    ),
  );
  return ok ?? false;
}
