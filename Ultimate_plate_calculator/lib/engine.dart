import 'package:flutter/material.dart';

class Plate {
  double weight;
  int amount;
  Color color;

  Plate({required this.weight, required this.amount, required this.color});

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'amount': amount,
    'color': color.value,
  };

  factory Plate.fromJson(Map<String, dynamic> json) => Plate(
    weight: (json['weight'] as num).toDouble(),
    amount: json['amount'] as int,
    color: Color(json['color'] as int),
  );
}

class Bar {
  String name;
  double weight;

  Bar({required this.name, required this.weight});

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
  };

  factory Bar.fromJson(Map<String, dynamic> json) => Bar(
    name: json['name'] as String,
    weight: (json['weight'] as num).toDouble(),
  );
}

class CalculationResult {
  final List<int> neededPlates;
  final String message;
  final double remainingWeight;
  final double totalWeightReached;
  final bool isOverloaded;

  CalculationResult({
    required this.neededPlates,
    required this.message,
    required this.remainingWeight,
    required this.totalWeightReached,
    this.isOverloaded = false,
  });

  Map<String, dynamic> toJson() => {
    'neededPlates': neededPlates,
    'message': message,
  };
}

CalculationResult plateCalculator({
  required List<Plate> plates,
  required double barWeight,
  required double objectiveWeight,
  required int sides,
  int maxPlatesPerSide = 12,
}) {
  double originalObjectiveWeight = objectiveWeight;
  double currentObjective = objectiveWeight - barWeight;

  List<int> neededPlates = List.filled(plates.length, 0);
  List<int> tempAmounts = plates.map((p) => p.amount).toList();
  
  int totalPlatesPerSide = 0;
  bool isOverloaded = false;

  if (currentObjective < -0.01) {
    return CalculationResult(
      neededPlates: neededPlates,
      message: "Target is lighter than the bar.",
      remainingWeight: currentObjective,
      totalWeightReached: barWeight,
    );
  }

  for (int i = 0; i < plates.length; i++) {
    if (currentObjective <= 0) break;
    if (tempAmounts[i] <= 0) continue;

    double weightPerSideGroup = plates[i].weight * sides;
    int possibleGroups = (currentObjective / weightPerSideGroup).floor();
    int availableGroups = tempAmounts[i] ~/ sides;
    
    int groupsToUse = (possibleGroups < availableGroups) ? possibleGroups : availableGroups;
    
    if (totalPlatesPerSide + groupsToUse > maxPlatesPerSide) {
      groupsToUse = maxPlatesPerSide - totalPlatesPerSide;
      isOverloaded = true;
    }

    if (groupsToUse > 0) {
      neededPlates[i] = groupsToUse * sides;
      currentObjective -= (neededPlates[i] * plates[i].weight).roundToDouble();
      tempAmounts[i] -= neededPlates[i];
      totalPlatesPerSide += groupsToUse;
    }
    
    if (isOverloaded) break;
  }

  String message = "";
  if (isOverloaded) {
    message = "MAX CAPACITY REACHED. Bar is full.";
  } else if (currentObjective > 0.01) {
    message = "Short ${currentObjective.toStringAsFixed(1)}. Reached ${(originalObjectiveWeight - currentObjective).toStringAsFixed(1)}";
  } else {
    message = "Target reached exactly.";
  }

  return CalculationResult(
    neededPlates: neededPlates,
    message: message,
    remainingWeight: currentObjective,
    totalWeightReached: originalObjectiveWeight - currentObjective,
    isOverloaded: isOverloaded,
  );
}
