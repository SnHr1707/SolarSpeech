import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches relevant data from Supabase to inject as context for the LLM.
class DatabaseContextService {
  static final _supabase = Supabase.instance.client;

  // ──────────────────────────────────────────────
  //  Keyword helpers
  // ──────────────────────────────────────────────
  static bool _mentionsInverter(String t) =>
      t.contains('inverter') || t.contains('converter') || t.contains('inv ');
  static bool _mentionsPlant(String t) =>
      t.contains('plant') || t.contains('site') || t.contains('farm') || t.contains('station');
  static bool _mentionsMfm(String t) =>
      t.contains('mfm') || t.contains('meter') || t.contains('multi function');
  static bool _mentionsTemp(String t) =>
      t.contains('temp') || t.contains('thermal') || t.contains('heat');
  static bool _mentionsSensor(String t) =>
      t.contains('sensor') || t.contains('wms') || t.contains('weather');
  static bool _mentionsAlert(String t) =>
      t.contains('alert') || t.contains('alarm') || t.contains('fault') ||
      t.contains('warning') || t.contains('notification');
  static bool _mentionsEnergy(String t) =>
      t.contains('energy') || t.contains('power') || t.contains('generation') ||
      t.contains('kwh') || t.contains('watt');
  static bool _mentionsSLMS(String t) =>
      t.contains('slms') || t.contains('slm') || t.contains('string level') || t.contains('string');

  // ──────────────────────────────────────────────
  //  Full context for chat mode
  // ──────────────────────────────────────────────
  /// Build a context string with data relevant to the user's query.
  static Future<String> getContextForQuery(String query) async {
    final buf = StringBuffer();
    final q = query.toLowerCase();

    // Always include lightweight system overview
    await _addSystemOverview(buf);

    if (_mentionsInverter(q))        await _addInverterContext(buf, q);
    if (_mentionsPlant(q))           await _addPlantContext(buf);
    if (_mentionsMfm(q))             await _addMfmContext(buf);
    if (_mentionsTemp(q))            await _addTempContext(buf);
    if (_mentionsSensor(q))          await _addSensorContext(buf);
    if (_mentionsAlert(q))           await _addAlertContext(buf);
    if (_mentionsEnergy(q))          await _addEnergyContext(buf);
    if (_mentionsSLMS(q))            await _addSlmsContext(buf);

    // If nothing specific was matched, add a broad snapshot
    if (buf.length < 200) {
      await _addInverterContext(buf, q);
      await _addAlertContext(buf);
    }

    return buf.toString();
  }

  // ──────────────────────────────────────────────
  //  Lightweight context for navigation mode
  // ──────────────────────────────────────────────
  static Future<String> getNavigationContext() async {
    final buf = StringBuffer();

    final plants = await _supabase.from('Plant').select('id, name');
    buf.writeln('Available Plants:');
    for (final p in plants) {
      buf.writeln('- ${p['name']} (ID: ${p['id']})');
    }

    final inverters =
        await _supabase.from('Inverter').select('id, name, plantId, Plant(name)');
    buf.writeln('\nAvailable Inverters:');
    for (final inv in inverters) {
      buf.writeln(
          '- ${inv['name']} (ID: ${inv['id']}, Plant: ${inv['Plant']?['name'] ?? 'Unknown'}, PlantID: ${inv['plantId']})');
    }

    final mfms = await _supabase
        .from('MFM')
        .select('id, name, sensorsId, Sensors(plantId, Plant(name))');
    buf.writeln('\nAvailable MFM Sensors:');
    for (final m in mfms) {
      final plantName = m['Sensors']?['Plant']?['name'] ?? 'Unknown';
      final plantId = m['Sensors']?['plantId'] ?? '';
      buf.writeln('- ${m['name']} (ID: ${m['id']}, Plant: $plantName, PlantID: $plantId)');
    }

    final temps = await _supabase
        .from('TemperatureDevice')
        .select('id, name, sensorsId, Sensors(plantId, Plant(name))');
    buf.writeln('\nAvailable Temperature Sensors:');
    for (final t in temps) {
      final plantName = t['Sensors']?['Plant']?['name'] ?? 'Unknown';
      final plantId = t['Sensors']?['plantId'] ?? '';
      buf.writeln('- ${t['name']} (ID: ${t['id']}, Plant: $plantName, PlantID: $plantId)');
    }

    final slms = await _supabase.from('Inverter').select('id, name');
    buf.writeln('\nSLMS-capable Inverters (same IDs as Inverters above):');
    for (final s in slms) {
      buf.writeln('- ${s['name']} (ID: ${s['id']})');
    }

    return buf.toString();
  }

  // ──────────────────────────────────────────────
  //  Section builders
  // ──────────────────────────────────────────────

  static Future<void> _addSystemOverview(StringBuffer buf) async {
    try {
      final plants = await _supabase.from('Plant').select();
      double totalCapacity = 0, totalEnergy = 0, todayEnergy = 0;
      for (final p in plants) {
        totalCapacity += (p['capacityKWp'] as num?)?.toDouble() ?? 0;
        totalEnergy += (p['totalEnergy'] as num?)?.toDouble() ?? 0;
        todayEnergy += (p['todayEnergy'] as num?)?.toDouble() ?? 0;
      }
      final invCount = (await _supabase.from('Inverter').select('id')).length;
      final alertCount = (await _supabase.from('Alert').select('id')).length;

      buf.writeln('=== System Overview ===');
      buf.writeln('Plants: ${plants.length} | Total Capacity: ${totalCapacity.toStringAsFixed(1)} kWp');
      buf.writeln('Inverters: $invCount | Active Alerts: $alertCount');
      buf.writeln('Total Energy: ${totalEnergy.toStringAsFixed(1)} kWh | Today Energy: ${todayEnergy.toStringAsFixed(1)} kWh');
      buf.writeln('Plant Names: ${plants.map((p) => "${p['name']} (ID:${p['id']})").join(', ')}');
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addInverterContext(StringBuffer buf, String query) async {
    try {
      final inverters =
          await _supabase.from('Inverter').select('id, name, plantId, Plant(name)');
      buf.writeln('=== Inverters ===');
      for (final inv in inverters) {
        buf.writeln(
            '- ${inv['name']} (ID:${inv['id']}, Plant:${inv['Plant']?['name']}, PlantID:${inv['plantId']})');
      }

      // Add latest data for each inverter (limited to 10 for context size)
      final limit = inverters.length > 10 ? 10 : inverters.length;
      for (int i = 0; i < limit; i++) {
        final inv = inverters[i];
        final latest = await _supabase
            .from('InverterData')
            .select()
            .eq('inverterId', inv['id'] as String)
            .order('timestamp', ascending: false)
            .limit(1);
        if (latest.isNotEmpty) {
          final d = latest[0];
          buf.writeln(
              '  Latest ${inv['name']}: ActivePower=${d['activePower']}kW, '
              'ETodayPower=${d['eTodayPower']}kWh, ETotalPower=${d['eTotalPower']}kWh, '
              'PVVoltage=${d['totalPVVoltage']}V, PVCurrent=${d['totalPVCurrent']}A, '
              'Timestamp=${d['timestamp']}');
        }
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addPlantContext(StringBuffer buf) async {
    try {
      final plants = await _supabase.from('Plant').select();
      buf.writeln('=== Plant Details ===');
      for (final p in plants) {
        buf.writeln(
            '- ${p['name']} (ID:${p['id']}): Capacity=${p['capacityKWp']}kWp, '
            'TotalEnergy=${p['totalEnergy']}kWh, TodayEnergy=${p['todayEnergy']}kWh, '
            'CO2Reduced=${p['co2Reduced']}kg');
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addMfmContext(StringBuffer buf) async {
    try {
      final mfms = await _supabase
          .from('MFM')
          .select('id, name, sensorsId, Sensors(plantId, Plant(name))');
      buf.writeln('=== MFM Sensors ===');
      for (final m in mfms) {
        final plantName = m['Sensors']?['Plant']?['name'] ?? 'Unknown';
        buf.writeln('- ${m['name']} (ID:${m['id']}, Plant:$plantName)');

        final latest = await _supabase
            .from('MFMData')
            .select()
            .eq('mfmId', m['id'] as String)
            .order('timestamp', ascending: false)
            .limit(1);
        if (latest.isNotEmpty) {
          final d = latest[0];
          buf.writeln(
              '  Latest: L1V=${d['l1Voltage']}V, L2V=${d['l2Voltage']}V, L3V=${d['l3Voltage']}V, '
              'L1I=${d['l1Current']}A, L2I=${d['l2Current']}A, L3I=${d['l3Current']}A, '
              'TotalPower=${d['totalPower']}kW, Timestamp=${d['timestamp']}');
        }
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addTempContext(StringBuffer buf) async {
    try {
      final temps = await _supabase
          .from('TemperatureDevice')
          .select('id, name, sensorsId, Sensors(plantId, Plant(name))');
      buf.writeln('=== Temperature Sensors ===');
      for (final t in temps) {
        final plantName = t['Sensors']?['Plant']?['name'] ?? 'Unknown';
        buf.writeln('- ${t['name']} (ID:${t['id']}, Plant:$plantName)');

        final latest = await _supabase
            .from('TemperatureData')
            .select()
            .eq('deviceId', t['id'] as String)
            .order('timestamp', ascending: false)
            .limit(1);
        if (latest.isNotEmpty) {
          final d = latest[0];
          buf.writeln(
              '  Latest: AmbientTemp=${d['ambientTemp']}°C, ModuleTemp=${d['moduleTemp']}°C, '
              'Timestamp=${d['timestamp']}');
        }
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addSensorContext(StringBuffer buf) async {
    try {
      final sensors = await _supabase.from('Sensors').select('id, plantId, Plant(name)');
      buf.writeln('=== Sensors Overview ===');
      for (final s in sensors) {
        buf.writeln('- Sensor Hub ID:${s['id']} → Plant:${s['Plant']?['name']} (PlantID:${s['plantId']})');
      }

      final wfms = await _supabase
          .from('WFM')
          .select('id, name, sensorsId, Sensors(plantId, Plant(name))');
      buf.writeln('Weather Stations (WFM):');
      for (final w in wfms) {
        buf.writeln('- ${w['name']} (ID:${w['id']}, Plant:${w['Sensors']?['Plant']?['name']})');
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addAlertContext(StringBuffer buf) async {
    try {
      final alerts = await _supabase
          .from('Alert')
          .select('*, Plant(name)')
          .order('triggeredAt', ascending: false)
          .limit(20);
      buf.writeln('=== Recent Alerts (up to 20) ===');
      for (final a in alerts) {
        buf.writeln(
            '- [${a['severity']}] ${a['message']} | Device:${a['deviceId']} | '
            'Plant:${a['Plant']?['name']} | At:${a['triggeredAt']}');
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addEnergyContext(StringBuffer buf) async {
    try {
      final plants = await _supabase.from('Plant').select('id, name, totalEnergy, todayEnergy, capacityKWp');
      buf.writeln('=== Energy Data ===');
      for (final p in plants) {
        buf.writeln(
            '- ${p['name']}: Today=${p['todayEnergy']}kWh, Total=${p['totalEnergy']}kWh, '
            'Capacity=${p['capacityKWp']}kWp');
      }

      // Latest inverter power readings
      final inverters = await _supabase.from('Inverter').select('id, name');
      for (final inv in inverters) {
        final latest = await _supabase
            .from('InverterData')
            .select('activePower, eTodayPower, eTotalPower, timestamp')
            .eq('inverterId', inv['id'] as String)
            .order('timestamp', ascending: false)
            .limit(1);
        if (latest.isNotEmpty) {
          final d = latest[0];
          buf.writeln(
              '  ${inv['name']}: ActivePower=${d['activePower']}kW, '
              'EToday=${d['eTodayPower']}kWh, ETotal=${d['eTotalPower']}kWh');
        }
      }
      buf.writeln();
    } catch (_) {}
  }

  static Future<void> _addSlmsContext(StringBuffer buf) async {
    try {
      final inverters = await _supabase.from('Inverter').select('id, name, plantId, Plant(name)');
      buf.writeln('=== SLMS (String Level Monitoring) ===');
      buf.writeln('SLMS data is indexed by inverter ID. Available inverters:');
      for (final inv in inverters) {
        buf.writeln('- ${inv['name']} (ID:${inv['id']}, Plant:${inv['Plant']?['name']})');
      }
      buf.writeln();
    } catch (_) {}
  }

  // ──────────────────────────────────────────────
  //  Fetch specific data on demand (for LLM tool-use / second-round)
  // ──────────────────────────────────────────────

  /// Fetch inverter time-series data for a date range.
  static Future<String> fetchInverterData(
      String inverterId, DateTime start, DateTime end) async {
    final data = await _supabase
        .from('InverterData')
        .select()
        .eq('inverterId', inverterId)
        .gte('timestamp', start.toIso8601String())
        .lt('timestamp', end.toIso8601String())
        .order('timestamp')
        .limit(100);
    if (data.isEmpty) return 'No inverter data for this period.';
    final buf = StringBuffer('InverterData (${data.length} rows):\n');
    for (final r in data) {
      buf.writeln(
          '  ${r['timestamp']}: ActivePower=${r['activePower']}kW, '
          'EToday=${r['eTodayPower']}kWh, ETotal=${r['eTotalPower']}kWh, '
          'PVV=${r['totalPVVoltage']}V, PVI=${r['totalPVCurrent']}A');
    }
    return buf.toString();
  }

  /// Fetch MFM time-series data for a date range.
  static Future<String> fetchMfmData(
      String mfmId, DateTime start, DateTime end) async {
    final data = await _supabase
        .from('MFMData')
        .select()
        .eq('mfmId', mfmId)
        .gte('timestamp', start.toIso8601String())
        .lt('timestamp', end.toIso8601String())
        .order('timestamp')
        .limit(100);
    if (data.isEmpty) return 'No MFM data for this period.';
    final buf = StringBuffer('MFMData (${data.length} rows):\n');
    for (final r in data) {
      buf.writeln(
          '  ${r['timestamp']}: L1V=${r['l1Voltage']}V, L2V=${r['l2Voltage']}V, '
          'L3V=${r['l3Voltage']}V, TotalPower=${r['totalPower']}kW');
    }
    return buf.toString();
  }

  /// Fetch temperature time-series data for a date range.
  static Future<String> fetchTempData(
      String deviceId, DateTime start, DateTime end) async {
    final data = await _supabase
        .from('TemperatureData')
        .select()
        .eq('deviceId', deviceId)
        .gte('timestamp', start.toIso8601String())
        .lt('timestamp', end.toIso8601String())
        .order('timestamp')
        .limit(100);
    if (data.isEmpty) return 'No temperature data for this period.';
    final buf = StringBuffer('TemperatureData (${data.length} rows):\n');
    for (final r in data) {
      buf.writeln(
          '  ${r['timestamp']}: Ambient=${r['ambientTemp']}°C, Module=${r['moduleTemp']}°C');
    }
    return buf.toString();
  }
}
