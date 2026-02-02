import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Powerlift Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE53935),
          secondary: Color(0xFF1E1E1E),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      home: const PlateCalculatorHome(),
    );
  }
}

class PlateCalculatorHome extends StatefulWidget {
  const PlateCalculatorHome({super.key});

  @override
  State<PlateCalculatorHome> createState() => _PlateCalculatorHomeState();
}

class _PlateCalculatorHomeState extends State<PlateCalculatorHome> {
  final TextEditingController _targetController = TextEditingController(text: '135');
  bool _isKg = false;
  bool _showVisualBar = true;
  int _sides = 2;
  Timer? _adjustmentTimer;

  List<Bar> _bars = [
    Bar(name: 'Standard Bar', weight: 45.0),
    Bar(name: 'Squat Bar', weight: 55.0),
    Bar(name: 'Women\'s Bar', weight: 35.0),
    Bar(name: 'EZ Bar', weight: 25.0),
    Bar(name: 'Dumbbell', weight: 10.0),
    Bar(name: 'No Bar', weight: 0.0),
  ];
  late Bar _currentBar;

  List<Plate> _inventory = [
    Plate(weight: 55, amount: 4, color: const Color(0xFFE53935)), // Red
    Plate(weight: 45, amount: 12, color: const Color(0xFF1E88E5)), // Blue
    Plate(weight: 35, amount: 4, color: const Color(0xFFFFEB3B)), // Yellow
    Plate(weight: 25, amount: 4, color: const Color(0xFF43A047)), // Green
    Plate(weight: 10, amount: 6, color: Colors.white),
    Plate(weight: 5, amount: 6, color: Colors.grey),
    Plate(weight: 2.5, amount: 4, color: const Color(0xFFB0BEC5)), // Silver
    Plate(weight: 1, amount: 4, color: Colors.amber), // Gold
  ];

  CalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _currentBar = _bars[0];
    _calculate();
    _targetController.addListener(_calculate);
  }

  void _calculate() {
    double target = double.tryParse(_targetController.text) ?? 0;
    setState(() {
      _result = plateCalculator(
        plates: _inventory,
        barWeight: _currentBar.weight,
        objectiveWeight: target,
        sides: _sides,
        maxPlatesPerSide: 12,
      );
    });
  }

  void _adjustWeight(double delta) {
    if (delta > 0 && _result != null && _result!.isOverloaded) {
      HapticFeedback.vibrate();
      _adjustmentTimer?.cancel();
      return;
    }
    
    HapticFeedback.selectionClick();
    double current = double.tryParse(_targetController.text) ?? 0;
    double newValue = current + delta;
    if (newValue < _currentBar.weight) newValue = _currentBar.weight;
    _targetController.text = newValue.toStringAsFixed(1).replaceAll('.0', '');
  }

  void _cycleBar() {
    HapticFeedback.lightImpact();
    setState(() {
      int index = _bars.indexWhere((b) => b.name == _currentBar.name);
      _currentBar = _bars[(index + 1) % _bars.length];
      _calculate();
    });
  }

  void _toggleUnit() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isKg = !_isKg;
      double factor = _isKg ? 1 / 2.20462 : 2.20462;
      
      if (_isKg) {
        _inventory = [
          Plate(weight: 25, amount: 4, color: const Color(0xFFE53935)),
          Plate(weight: 20, amount: 12, color: const Color(0xFF1E88E5)),
          Plate(weight: 15, amount: 4, color: const Color(0xFFFFEB3B)),
          Plate(weight: 10, amount: 4, color: const Color(0xFF43A047)),
          Plate(weight: 5, amount: 6, color: Colors.white),
          Plate(weight: 2.5, amount: 6, color: Colors.grey),
          Plate(weight: 1.25, amount: 4, color: const Color(0xFFB0BEC5)),
          Plate(weight: 0.5, amount: 4, color: Colors.amber),
        ];
        _bars = [
          Bar(name: 'Standard Bar', weight: 20.0),
          Bar(name: 'Squat Bar', weight: 25.0),
          Bar(name: 'Women\'s Bar', weight: 15.0),
          Bar(name: 'EZ Bar', weight: 12.0),
          Bar(name: 'Dumbbell', weight: 5.0),
          Bar(name: 'No Bar', weight: 0.0),
        ];
      } else {
        _inventory = [
          Plate(weight: 55, amount: 4, color: const Color(0xFFE53935)),
          Plate(weight: 45, amount: 12, color: const Color(0xFF1E88E5)),
          Plate(weight: 35, amount: 4, color: const Color(0xFFFFEB3B)),
          Plate(weight: 25, amount: 4, color: const Color(0xFF43A047)),
          Plate(weight: 10, amount: 6, color: Colors.white),
          Plate(weight: 5, amount: 6, color: Colors.grey),
          Plate(weight: 2.5, amount: 4, color: const Color(0xFFB0BEC5)),
          Plate(weight: 1, amount: 4, color: Colors.amber),
        ];
        _bars = [
          Bar(name: 'Standard Bar', weight: 45.0),
          Bar(name: 'Squat Bar', weight: 55.0),
          Bar(name: 'Women\'s Bar', weight: 35.0),
          Bar(name: 'EZ Bar', weight: 25.0),
          Bar(name: 'Dumbbell', weight: 10.0),
          Bar(name: 'No Bar', weight: 0.0),
        ];
      }

      _currentBar = _bars.firstWhere((b) => b.name == _currentBar.name, orElse: () => _bars[0]);

      double currentTarget = double.tryParse(_targetController.text) ?? 0;
      _targetController.text = (currentTarget * factor).toStringAsFixed(1).replaceAll('.0', '');
      
      _calculate();
    });
  }

  void _showInventory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    const Text('BARS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    ...List.generate(_bars.length, (index) {
                      final bar = _bars[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center, size: 20),
                        title: Text(bar.name),
                        subtitle: Text('${bar.weight} ${_isKg ? 'kg' : 'lb'}'),
                        onTap: () {
                          setState(() => _currentBar = bar);
                          _calculate();
                          Navigator.pop(context);
                        },
                        selected: _currentBar.name == bar.name,
                      );
                    }),
                    const Divider(height: 40),
                    const Text('PLATES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    ...List.generate(_inventory.length, (index) {
                      final plate = _inventory[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: plate.color, radius: 12),
                        title: Text('${plate.weight} ${_isKg ? 'kg' : 'lb'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove), onPressed: () {
                              setModalState(() { if (plate.amount > 0) plate.amount--; });
                              setState(() => _calculate());
                            }),
                            Text('${plate.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add), onPressed: () {
                              setModalState(() { plate.amount++; });
                              setState(() => _calculate());
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.refresh), onPressed: () {
                      _targetController.text = _currentBar.weight.toStringAsFixed(0);
                      HapticFeedback.vibrate();
                    }),
                    Flexible(
                      child: GestureDetector(
                        onTap: _toggleUnit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isKg ? 'METRIC (KG)' : 'IMPERIAL (LB)', 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.inventory_2_outlined), onPressed: _showInventory),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _quickAdjustButton(Icons.remove, -(_isKg ? 2.5 : 5.0)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _targetController,
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1),
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: '0'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _quickAdjustButton(Icons.add, (_isKg ? 2.5 : 5.0)),
                  ],
                ),
              ),
              Text(_isKg ? 'KILOGRAMS' : 'POUNDS', style: const TextStyle(color: Colors.grey, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              const Text('LOADING PEGS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [1, 2, 4].map((s) => ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    label: Text(s == 1 ? 'SINGLE' : (s == 2 ? 'STANDARD' : 'FOUR-WAY'), style: const TextStyle(fontSize: 12)),
                    selected: _sides == s,
                    onSelected: (val) {
                      if (val) {
                        HapticFeedback.selectionClick();
                        setState(() { _sides = s; _calculate(); });
                      }
                    },
                    selectedColor: const Color(0xFFE53935),
                    backgroundColor: const Color(0xFF1E1E1E),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 40),
              _showVisualBar ? _buildVisualBar() : _buildTextDisplay(),
              const SizedBox(height: 20),
              if (_result != null) 
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: (_result!.isOverloaded ? Colors.red : const Color(0xFFE53935)).withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(10),
                    border: _result!.isOverloaded ? Border.all(color: Colors.red, width: 2) : null,
                  ),
                  child: Text(
                    _result!.message, 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _result!.isOverloaded ? Colors.red : const Color(0xFFE53935), fontWeight: FontWeight.bold)
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        Icons.fitness_center, 
                        'BAR: ${_currentBar.weight.toStringAsFixed(1).replaceAll('.0', '')}', 
                        _cycleBar
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        _showVisualBar ? Icons.list : Icons.image, 
                        _showVisualBar ? 'TEXT' : 'VISUAL', 
                        () => setState(() => _showVisualBar = !_showVisualBar)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAdjustButton(IconData icon, double delta) {
    return GestureDetector(
      onTapDown: (_) {
        _adjustWeight(delta);
        _adjustmentTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
          _adjustWeight(delta);
        });
      },
      onTapUp: (_) => _adjustmentTimer?.cancel(),
      onTapCancel: () => _adjustmentTimer?.cancel(),
      child: Container(padding: const EdgeInsets.all(12), color: Colors.transparent, child: Icon(icon, color: const Color(0xFFE53935), size: 32)),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          ],
        ),
      ),
    );
  }

  Widget _buildTextDisplay() {
    if (_result == null) return const SizedBox(height: 120);
    List<String> plateStrings = [];
    for (int i = 0; i < _inventory.length; i++) {
      int countPerSide = _result!.neededPlates[i] ~/ _sides;
      if (countPerSide > 0) {
        String weight = _inventory[i].weight.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
        plateStrings.add("$countPerSide x $weight");
      }
    }
    return Container(
      height: 120, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center,
      child: plateStrings.isEmpty 
        ? const Text("NO PLATES LOADED", style: TextStyle(color: Colors.grey, letterSpacing: 1))
        : SingleChildScrollView(child: Text(plateStrings.join(" | "), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70))),
    );
  }

  Widget _buildVisualBar() {
    if (_result == null) return const SizedBox(height: 120);
    return Container(
      height: 120, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 8, width: double.infinity, color: const Color(0xFF333333)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(_inventory.length, (i) {
                int countPerSide = _result!.neededPlates[i] ~/ _sides;
                if (countPerSide <= 0) return const SizedBox();
                final color = _inventory[i].color;
                final weight = _inventory[i].weight;
                final isLightColor = color.computeLuminance() > 0.5;
                final weightText = weight.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
                return Row(
                  children: List.generate(countPerSide, (index) => Container(
                    width: 18, height: _getPlateHeight(weight), margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2)]),
                    child: Center(child: Text(weightText, style: TextStyle(color: isLightColor ? Colors.black : Colors.white, fontSize: 7, fontWeight: FontWeight.bold))),
                  )),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  double _getPlateHeight(double weight) {
    if (weight >= 45 || weight >= 20) return 100;
    if (weight >= 25 || weight >= 10) return 80;
    if (weight >= 10 || weight >= 5) return 60;
    return 40;
  }
}
