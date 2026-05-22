import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/udp_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

enum PresetMode { strobe, disco, racing, bg, power, custom }

enum DiscoSub { disco, discoT, discoA, discoR }

enum RacingSub { startRace, stopRace, raceLaps, raceLapTime, loopRace }

enum BgSub { setBG, setBgOff }

enum PowerSub { maxLedPow, maxPowerLed }

enum ScenarioStepType {
  setStrobeRGBW,
  strobe,
  disco,
  discoT,
  discoA,
  discoR,
  startRace,
  stopRace,
  raceLaps,
  raceLapTime,
  loopRace,
  setBG,
  setBgOff,
  maxLedPow,
  maxPowerLed,
  delay,
}

class ScenarioStep {
  ScenarioStepType type;
  Map<String, dynamic> data;

  ScenarioStep({required this.type, required this.data});

  String buildCommand() {
    String pad2(int v) => v.toString().padLeft(2, '0');
    String pad3(int v) => v.toString().padLeft(3, '0');
    String pad4(int v) => v.toString().padLeft(4, '0');

    switch (type) {
      case ScenarioStepType.setStrobeRGBW:
        return "setStrobeRGBW ${pad3(data['r'])} ${pad3(data['g'])} ${pad3(data['b'])} ${pad3(data['w'])}";
      case ScenarioStepType.strobe:
        return "strobe ${pad2(data['amount'])} ${pad2(data['millisOn'])} ${pad4(data['millisOff'])}";
      case ScenarioStepType.disco:
        return "disco ${pad2(data['ledCount'])} ${pad4(data['millis'])}";
      case ScenarioStepType.discoT:
        return "discoT ${pad2(data['ledCount'])} ${pad4(data['millis'])} ${pad4(data['blinkCount'])}";
      case ScenarioStepType.discoA:
        return "discoA ${pad2(data['ledCount'])} ${pad4(data['millis'])} ${pad4(data['blinkCount'])}";
      case ScenarioStepType.discoR:
        return "discoR ${pad2(data['ledCount'])} ${pad4(data['millis'])} ${pad4(data['blinkCount'])}";
      case ScenarioStepType.startRace:
        return "startRace ${data['color']}";
      case ScenarioStepType.stopRace:
        return "stopRace ${data['color']}";
      case ScenarioStepType.raceLaps:
        return "raceLaps ${data['color']} ${pad2(data['laps'])}";
      case ScenarioStepType.raceLapTime:
        return "raceLapTime ${data['color']} ${pad2(data['lap'])} ${pad3(data['seconds'])} ${pad2(data['hundreds'])}";
      case ScenarioStepType.loopRace:
        return "loopRace";
      case ScenarioStepType.setBG:
        return "setBG ${pad3(data['r'])} ${pad3(data['g'])} ${pad3(data['b'])} ${pad3(data['w'])} ${pad3(data['fadeFrom'])} ${pad3(data['fadeTo'])}";
      case ScenarioStepType.setBgOff:
        return "setBgOff";
      case ScenarioStepType.maxLedPow:
        return "maxLedPow ${pad3(data['power'])}";
      case ScenarioStepType.maxPowerLed:
        return "maxPowerLed ${pad3(data['power'])}";
      case ScenarioStepType.delay:
        return "delay ${pad4(data['delay'])}";
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'data': data,
      };

  static ScenarioStep fromJson(Map<String, dynamic> json) {
    return ScenarioStep(
      type: ScenarioStepType.values[json['type'] as int],
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  String label() {
    if (type == ScenarioStepType.delay) {
      return "delay ${data['delay']}ms";
    }
    return type.name;
  }
}

class PresetsPage extends StatefulWidget {
  const PresetsPage({super.key});

  @override
  State<PresetsPage> createState() => _PresetsPageState();
}

class _PresetsPageState extends State<PresetsPage> {
  final _udp = UdpService();

  PresetMode? _selectedMode;
  DiscoSub _discoSub = DiscoSub.disco;
  RacingSub _racingSub = RacingSub.startRace;
  BgSub _bgSub = BgSub.setBG;
  PowerSub _powerSub = PowerSub.maxLedPow;

  // normal mode fields
  String _color = "A";
  int _amount = 10;
  int _millisOn = 20;
  int _millisOff = 120;

  int _discoLedCount = 8;
  int _discoMillis = 1500;
  int _discoBlinkCount = 100;

  int _raceLaps = 5;
  int _raceLap = 1;
  int _raceSeconds = 12;
  int _raceHundreds = 50;

  int _bgR = 255;
  int _bgG = 180;
  int _bgB = 120;
  int _bgW = 0;
  int _bgFadeFrom = 50;
  int _bgFadeTo = 200;

  int _powerValue = 100;

  // custom scenario
  List<ScenarioStep> _scenarioSteps = [];
  String _customName = "";

  List<Map<String, dynamic>> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("presets") ?? [];

    if (list.isEmpty) {
      await _savePresetInternal({
        "name": "Soft White Strobe",
        "mode": PresetMode.strobe.index,
        "commands": [
          "setStrobeRGBW 000 000 000 255",
          "strobe 10 20 0120",
        ],
      });
      await _savePresetInternal({
        "name": "Disco Rainbow",
        "mode": PresetMode.disco.index,
        "commands": [
          "disco 08 1500",
        ],
      });
      await _savePresetInternal({
        "name": "Racing Blue",
        "mode": PresetMode.racing.index,
        "commands": [
          "startRace B",
        ],
      });
      await _savePresetInternal({
        "name": "Warm BG",
        "mode": PresetMode.bg.index,
        "commands": [
          "setBG 255 180 120 000 050 200",
        ],
      });
      await _savePresetInternal({
        "name": "Max Power",
        "mode": PresetMode.power.index,
        "commands": [
          "maxLedPow 100",
        ],
      });
      list = prefs.getStringList("presets") ?? [];
    }

    setState(() {
      _presets =
          list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _savePresetInternal(Map<String, dynamic> preset) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("presets") ?? [];
    list.add(jsonEncode(preset));
    await prefs.setStringList("presets", list);
  }

  Future<void> _savePreset() async {
    if (_selectedMode == null) return;

    final commands = _buildCommandsForCurrent();
    if (commands.isEmpty) {
      showStatus(context, "No commands generated");
      return;
    }

    final name = _selectedMode == PresetMode.custom
        ? (_customName.isEmpty ? "Custom Scenario" : _customName)
        : _selectedMode!.name;

    final preset = {
      "name": name,
      "mode": _selectedMode!.index,
      "commands": commands,
    };

    await _savePresetInternal(preset);
    await _loadPresets();
    if (mounted) showStatus(context, "Preset saved");
  }

  Future<void> _deletePreset(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("presets") ?? [];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await prefs.setStringList("presets", list);
    await _loadPresets();
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');
  String _pad3(int v) => v.toString().padLeft(3, '0');
  String _pad4(int v) => v.toString().padLeft(4, '0');

  List<String> _buildCommandsForCurrent() {
    if (_selectedMode == null) return [];

    switch (_selectedMode!) {
      case PresetMode.strobe:
        final rgbw = _colorToRGBW(_color);
        final r = _pad3(rgbw[0]);
        final g = _pad3(rgbw[1]);
        final b = _pad3(rgbw[2]);
        final w = _pad3(rgbw[3]);
        return [
          "setStrobeRGBW $r $g $b $w",
          "strobe ${_pad2(_amount)} ${_pad2(_millisOn)} ${_pad4(_millisOff)}",
        ];

      case PresetMode.disco:
        switch (_discoSub) {
          case DiscoSub.disco:
            return [
              "disco ${_pad2(_discoLedCount)} ${_pad4(_discoMillis)}",
            ];
          case DiscoSub.discoT:
            return [
              "discoT ${_pad2(_discoLedCount)} ${_pad4(_discoMillis)} ${_pad4(_discoBlinkCount)}",
            ];
          case DiscoSub.discoA:
            return [
              "discoA ${_pad2(_discoLedCount)} ${_pad4(_discoMillis)} ${_pad4(_discoBlinkCount)}",
            ];
          case DiscoSub.discoR:
            return [
              "discoR ${_pad2(_discoLedCount)} ${_pad4(_discoMillis)} ${_pad4(_discoBlinkCount)}",
            ];
        }

      case PresetMode.racing:
        switch (_racingSub) {
          case RacingSub.startRace:
            return ["startRace $_color"];
          case RacingSub.stopRace:
            return ["stopRace $_color"];
          case RacingSub.raceLaps:
            return ["raceLaps $_color ${_pad2(_raceLaps)}"];
          case RacingSub.raceLapTime:
            return [
              "raceLapTime $_color ${_pad2(_raceLap)} ${_pad3(_raceSeconds)} ${_pad2(_raceHundreds)}"
            ];
          case RacingSub.loopRace:
            return ["loopRace"];
        }

      case PresetMode.bg:
        switch (_bgSub) {
          case BgSub.setBG:
            return [
              "setBG ${_pad3(_bgR)} ${_pad3(_bgG)} ${_pad3(_bgB)} ${_pad3(_bgW)} ${_pad3(_bgFadeFrom)} ${_pad3(_bgFadeTo)}"
            ];
          case BgSub.setBgOff:
            return ["setBgOff"];
        }

      case PresetMode.power:
        switch (_powerSub) {
          case PowerSub.maxLedPow:
            return ["maxLedPow ${_pad3(_powerValue)}"];
          case PowerSub.maxPowerLed:
            return ["maxPowerLed ${_pad3(_powerValue)}"];
        }

      case PresetMode.custom:
        return _scenarioSteps.map((s) => s.buildCommand()).toList();
    }
  }

  List<int> _colorToRGBW(String c) {
    switch (c) {
      case "R":
        return [255, 0, 0, 0];
      case "G":
        return [0, 255, 0, 0];
      case "B":
        return [0, 0, 255, 0];
      case "W":
        return [0, 0, 0, 255];
      case "A":
      default:
        return [255, 255, 255, 255];
    }
  }

  Future<void> _testPreset(Map<String, dynamic> preset) async {
    final cmds = List<String>.from(preset["commands"] ?? []);
    for (final c in cmds) {
      if (c.startsWith("delay ")) {
        final parts = c.split(" ");
        if (parts.length == 2) {
          final d = int.tryParse(parts[1]) ?? 0;
          await Future.delayed(Duration(milliseconds: d));
        }
      } else {
        await _udp.send(c);
      }
    }
    if (mounted) showStatus(context, "Preset tested");
  }

  Future<void> _testCurrent() async {
    final cmds = _buildCommandsForCurrent();
    if (cmds.isEmpty) {
      showStatus(context, "No commands generated");
      return;
    }
    for (final c in cmds) {
      if (c.startsWith("delay ")) {
        final parts = c.split(" ");
        if (parts.length == 2) {
          final d = int.tryParse(parts[1]) ?? 0;
          await Future.delayed(Duration(milliseconds: d));
        }
      } else {
        await _udp.send(c);
      }
    }
    if (mounted) showStatus(context, "Preset tested");
  }

  Widget _modeButton(PresetMode mode, IconData icon, String label) {
    final active = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.activeBtn.withOpacity(0.20)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.activeBtn : AppColors.cardBorder,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  active ? AppColors.activeBtn : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: active
                    ? AppColors.activeBtn
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _modeButton(PresetMode.strobe, Icons.bolt, "Strobe"),
        _modeButton(PresetMode.disco, Icons.auto_awesome, "Disco"),
        _modeButton(PresetMode.racing, Icons.flag, "Racing"),
        _modeButton(PresetMode.bg, Icons.wb_sunny, "BG Mode"),
        _modeButton(
            PresetMode.power, Icons.battery_charging_full, "Power"),
        _modeButton(PresetMode.custom, Icons.tune, "Custom"),
      ],
    );
  }

  Widget _buildColorDropdown() {
    return DropdownButton<String>(
      value: _color,
      items: const [
        DropdownMenuItem(value: "A", child: Text("All")),
        DropdownMenuItem(value: "R", child: Text("Red")),
        DropdownMenuItem(value: "G", child: Text("Green")),
        DropdownMenuItem(value: "B", child: Text("Blue")),
        DropdownMenuItem(value: "W", child: Text("White")),
      ],
      onChanged: (v) => setState(() => _color = v!),
    );
  }

  Widget _buildStrobeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColorDropdown(),
        const SizedBox(height: 8),
        AppSlider(
          label: "Amount",
          value: _amount.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          displayValue: (v) => _pad2(v.toInt()),
          onChanged: (v) => setState(() => _amount = v.toInt()),
        ),
        AppSlider(
          label: "Millis ON",
          value: _millisOn.toDouble(),
          min: 1,
          max: 99,
          divisions: 98,
          displayValue: (v) => _pad2(v.toInt()),
          onChanged: (v) => setState(() => _millisOn = v.toInt()),
        ),
        AppSlider(
          label: "Millis OFF",
          value: _millisOff.toDouble(),
          min: 1,
          max: 9999,
          divisions: 9998,
          displayValue: (v) => _pad4(v.toInt()),
          onChanged: (v) => setState(() => _millisOff = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildDiscoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<DiscoSub>(
          value: _discoSub,
          items: const [
            DropdownMenuItem(
                value: DiscoSub.disco, child: Text("Disco")),
            DropdownMenuItem(
                value: DiscoSub.discoT, child: Text("DiscoT")),
            DropdownMenuItem(
                value: DiscoSub.discoA, child: Text("DiscoA")),
            DropdownMenuItem(
                value: DiscoSub.discoR, child: Text("DiscoR")),
          ],
          onChanged: (v) => setState(() => _discoSub = v!),
        ),
        const SizedBox(height: 8),
        AppSlider(
          label: "LED Count",
          value: _discoLedCount.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          displayValue: (v) => _pad2(v.toInt()),
          onChanged: (v) =>
              setState(() => _discoLedCount = v.toInt()),
        ),
        AppSlider(
          label: "Millis",
          value: _discoMillis.toDouble(),
          min: 1,
          max: 9999,
          divisions: 9998,
          displayValue: (v) => _pad4(v.toInt()),
          onChanged: (v) => setState(() => _discoMillis = v.toInt()),
        ),
        if (_discoSub != DiscoSub.disco)
          AppSlider(
            label: "Blink Count",
            value: _discoBlinkCount.toDouble(),
            min: 1,
            max: 9999,
            divisions: 9998,
            displayValue: (v) => _pad4(v.toInt()),
            onChanged: (v) =>
                setState(() => _discoBlinkCount = v.toInt()),
          ),
      ],
    );
  }

  Widget _buildRacingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<RacingSub>(
          value: _racingSub,
          items: const [
            DropdownMenuItem(
                value: RacingSub.startRace,
                child: Text("Start Race")),
            DropdownMenuItem(
                value: RacingSub.stopRace, child: Text("Stop Race")),
            DropdownMenuItem(
                value: RacingSub.raceLaps,
                child: Text("Race Laps")),
            DropdownMenuItem(
                value: RacingSub.raceLapTime,
                child: Text("Race Lap Time")),
            DropdownMenuItem(
                value: RacingSub.loopRace,
                child: Text("Loop Race")),
          ],
          onChanged: (v) => setState(() => _racingSub = v!),
        ),
        const SizedBox(height: 8),
        if (_racingSub != RacingSub.loopRace) _buildColorDropdown(),
        if (_racingSub == RacingSub.raceLaps)
          AppSlider(
            label: "Laps",
            value: _raceLaps.toDouble(),
            min: 1,
            max: 99,
            divisions: 98,
            displayValue: (v) => _pad2(v.toInt()),
            onChanged: (v) =>
                setState(() => _raceLaps = v.toInt()),
          ),
        if (_racingSub == RacingSub.raceLapTime) ...[
          AppSlider(
            label: "Lap",
            value: _raceLap.toDouble(),
            min: 1,
            max: 99,
            divisions: 98,
            displayValue: (v) => _pad2(v.toInt()),
            onChanged: (v) =>
                setState(() => _raceLap = v.toInt()),
          ),
          AppSlider(
            label: "Seconds",
            value: _raceSeconds.toDouble(),
            min: 0,
            max: 999,
            divisions: 999,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) =>
                setState(() => _raceSeconds = v.toInt()),
          ),
          AppSlider(
            label: "Hundreds",
            value: _raceHundreds.toDouble(),
            min: 0,
            max: 99,
            divisions: 99,
            displayValue: (v) => _pad2(v.toInt()),
            onChanged: (v) =>
                setState(() => _raceHundreds = v.toInt()),
          ),
        ],
      ],
    );
  }

  Widget _buildBgForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<BgSub>(
          value: _bgSub,
          items: const [
            DropdownMenuItem(
                value: BgSub.setBG, child: Text("Set Background")),
            DropdownMenuItem(
                value: BgSub.setBgOff, child: Text("Background Off")),
          ],
          onChanged: (v) => setState(() => _bgSub = v!),
        ),
        const SizedBox(height: 8),
        if (_bgSub == BgSub.setBG) ...[
          AppSlider(
            label: "R",
            value: _bgR.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) => setState(() => _bgR = v.toInt()),
          ),
          AppSlider(
            label: "G",
            value: _bgG.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) => setState(() => _bgG = v.toInt()),
          ),
          AppSlider(
            label: "B",
            value: _bgB.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) => setState(() => _bgB = v.toInt()),
          ),
          AppSlider(
            label: "W",
            value: _bgW.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) => setState(() => _bgW = v.toInt()),
          ),
          AppSlider(
            label: "Fade From",
            value: _bgFadeFrom.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) =>
                setState(() => _bgFadeFrom = v.toInt()),
          ),
          AppSlider(
            label: "Fade To",
            value: _bgFadeTo.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            displayValue: (v) => _pad3(v.toInt()),
            onChanged: (v) =>
                setState(() => _bgFadeTo = v.toInt()),
          ),
        ],
      ],
    );
  }

  Widget _buildPowerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<PowerSub>(
          value: _powerSub,
          items: const [
            DropdownMenuItem(
                value: PowerSub.maxLedPow,
                child: Text("Max LED Power")),
            DropdownMenuItem(
                value: PowerSub.maxPowerLed,
                child: Text("Max Power LED")),
          ],
          onChanged: (v) => setState(() => _powerSub = v!),
        ),
        const SizedBox(height: 8),
        AppSlider(
          label: "Power",
          value: _powerValue.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          displayValue: (v) => _pad3(v.toInt()),
          onChanged: (v) => setState(() => _powerValue = v.toInt()),
        ),
      ],
    );
  }

  Future<void> _editScenarioStep(
      {ScenarioStep? step, int? index}) async {
    ScenarioStepType type = step?.type ?? ScenarioStepType.setBG;
    Map<String, dynamic> data = Map<String, dynamic>.from(
        step?.data ?? <String, dynamic>{});

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          Widget buildField(
              String label, String key, int min, int max) {
            final current = (data[key] ?? min) as int;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Slider(
                  value: current.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (v) {
                    setLocal(() {
                      data[key] = v.toInt();
                    });
                  },
                ),
              ],
            );
          }

          Widget buildFormForType() {
            switch (type) {
              case ScenarioStepType.setStrobeRGBW:
                data.putIfAbsent('r', () => 255);
                data.putIfAbsent('g', () => 255);
                data.putIfAbsent('b', () => 255);
                data.putIfAbsent('w', () => 255);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildField("R", "r", 0, 255),
                    buildField("G", "g", 0, 255),
                    buildField("B", "b", 0, 255),
                    buildField("W", "w", 0, 255),
                  ],
                );
              case ScenarioStepType.strobe:
                data.putIfAbsent('amount', () => 10);
                data.putIfAbsent('millisOn', () => 20);
                data.putIfAbsent('millisOff', () => 120);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildField("Amount", "amount", 1, 50),
                    buildField("Millis ON", "millisOn", 1, 99),
                    buildField("Millis OFF", "millisOff", 1, 9999),
                  ],
                );
              case ScenarioStepType.disco:
              case ScenarioStepType.discoT:
              case ScenarioStepType.discoA:
              case ScenarioStepType.discoR:
                data.putIfAbsent('ledCount', () => 8);
                data.putIfAbsent('millis', () => 1500);
                data.putIfAbsent('blinkCount', () => 100);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildField("LED Count", "ledCount", 1, 50),
                    buildField("Millis", "millis", 1, 9999),
                    if (type != ScenarioStepType.disco)
                      buildField(
                          "Blink Count", "blinkCount", 1, 9999),
                  ],
                );
              case ScenarioStepType.startRace:
              case ScenarioStepType.stopRace:
              case ScenarioStepType.raceLaps:
              case ScenarioStepType.raceLapTime:
                data.putIfAbsent('color', () => "A");
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: data['color'] as String,
                      items: const [
                        DropdownMenuItem(
                            value: "A", child: Text("All")),
                        DropdownMenuItem(
                            value: "R", child: Text("Red")),
                        DropdownMenuItem(
                            value: "G", child: Text("Green")),
                        DropdownMenuItem(
                            value: "B", child: Text("Blue")),
                        DropdownMenuItem(
                            value: "W", child: Text("White")),
                      ],
                      onChanged: (v) =>
                          setLocal(() => data['color'] = v),
                    ),
                    if (type == ScenarioStepType.raceLaps)
                      buildField("Laps", "laps", 1, 99),
                    if (type == ScenarioStepType.raceLapTime) ...[
                      buildField("Lap", "lap", 1, 99),
                      buildField("Seconds", "seconds", 0, 999),
                      buildField("Hundreds", "hundreds", 0, 99),
                    ],
                  ],
                );
              case ScenarioStepType.loopRace:
                return const SizedBox.shrink();
              case ScenarioStepType.setBG:
                data.putIfAbsent('r', () => 255);
                data.putIfAbsent('g', () => 180);
                data.putIfAbsent('b', () => 120);
                data.putIfAbsent('w', () => 0);
                data.putIfAbsent('fadeFrom', () => 50);
                data.putIfAbsent('fadeTo', () => 200);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildField("R", "r", 0, 255),
                    buildField("G", "g", 0, 255),
                    buildField("B", "b", 0, 255),
                    buildField("W", "w", 0, 255),
                    buildField("Fade From", "fadeFrom", 0, 255),
                    buildField("Fade To", "fadeTo", 0, 255),
                  ],
                );
              case ScenarioStepType.setBgOff:
                return const SizedBox.shrink();
              case ScenarioStepType.maxLedPow:
              case ScenarioStepType.maxPowerLed:
                data.putIfAbsent('power', () => 255);
                return buildField("Power", "power", 0, 255);
              case ScenarioStepType.delay:
                data.putIfAbsent('delay', () => 1000);
                return buildField("Delay (ms)", "delay", 0, 9999);
            }
          }

          return AlertDialog(
            title: const Text("Scenario Step"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<ScenarioStepType>(
                    value: type,
                    items: ScenarioStepType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setLocal(() {
                        type = v!;
                        data = {};
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  buildFormForType(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(
                    ScenarioStep(type: type, data: data),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value is ScenarioStep) {
        setState(() {
          if (index != null) {
            _scenarioSteps[index] = value;
          } else {
            _scenarioSteps.add(value);
          }
        });
      }
    });
  }

  Widget _buildScenarioBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration:
              const InputDecoration(labelText: "Scenario name"),
          onChanged: (v) => _customName = v,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(_scenarioSteps.length, (index) {
            final step = _scenarioSteps[index];
            return LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: Chip(
                  label: Text(step.label()),
                ),
              ),
              child: DragTarget<int>(
                onAccept: (from) {
                  setState(() {
                    final moved = _scenarioSteps.removeAt(from);
                    _scenarioSteps.insert(index, moved);
                  });
                },
                builder: (context, candidate, rejected) {
                  return InputChip(
                    label: Text(step.label()),
                    onPressed: () =>
                        _editScenarioStep(step: step, index: index),
                    onDeleted: () {
                      setState(() {
                        _scenarioSteps.removeAt(index);
                      });
                    },
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: "Add Step",
          icon: Icons.add,
          active: false,
          onTap: () => _editScenarioStep(),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    if (_selectedMode == null) return const SizedBox.shrink();

    return AppCard(
      title: "Preset Settings",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedMode == PresetMode.strobe) _buildStrobeForm(),
          if (_selectedMode == PresetMode.disco) _buildDiscoForm(),
          if (_selectedMode == PresetMode.racing) _buildRacingForm(),
          if (_selectedMode == PresetMode.bg) _buildBgForm(),
          if (_selectedMode == PresetMode.power) _buildPowerForm(),
          if (_selectedMode == PresetMode.custom) _buildScenarioBuilder(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Test",
                  icon: Icons.play_arrow_rounded,
                  active: false,
                  onTap: _testCurrent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: "Save",
                  icon: Icons.save,
                  active: false,
                  onTap: _savePreset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Presets",
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildModeGrid(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 16),
          ...List.generate(_presets.length, (i) {
            final p = _presets[i];
            final cmds = List<String>.from(p["commands"] ?? []);
            return AppCard(
              title: p["name"] ?? "Preset",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mode: ${PresetMode.values[p["mode"] ?? 0].name}"),
                  const SizedBox(height: 8),
                  if (cmds.isNotEmpty)
                    Text(
                      cmds.join("\n"),
                      style: GoogleFonts.robotoMono(fontSize: 11),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Test",
                          icon: Icons.play_arrow_rounded,
                          active: false,
                          onTap: () => _testPreset(p),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: "Delete",
                          icon: Icons.delete_outline,
                          active: false,
                          onTap: () => _deletePreset(i),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}