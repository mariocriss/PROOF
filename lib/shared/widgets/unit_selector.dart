import 'package:flutter/material.dart';
import 'package:proof/core/constants/measurement_units.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/models/measurement_type.dart';

class UnitSelector extends StatelessWidget {
  const UnitSelector({
    super.key,
    required this.allowedUnits,
    required this.selectedUnit,
    required this.onChanged,
    this.label = 'Unit',
  });

  final List<String> allowedUnits;
  final String selectedUnit;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (allowedUnits.length <= 1) {
      final unit = allowedUnits.first;
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceElevated,
        ),
        child: Text(
          MeasurementUnits.label(unit),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedUnit,
      decoration: InputDecoration(labelText: label),
      items: allowedUnits
          .map(
            (u) => DropdownMenuItem(
              value: u,
              child: Text(MeasurementUnits.label(u)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class ResultInputField extends StatelessWidget {
  const ResultInputField({
    super.key,
    required this.controller,
    required this.measurementType,
    required this.unit,
    this.label = 'Result',
    this.validator,
  });

  final TextEditingController controller;
  final MeasurementType measurementType;
  final String unit;
  final String label;
  final String? Function(String?)? validator;

  String get _hint {
    switch (measurementType) {
      case MeasurementType.count:
      case MeasurementType.calories:
        return 'e.g. 52';
      case MeasurementType.weight:
        return 'e.g. 180';
      case MeasurementType.duration:
        return 'e.g. 21:35 or 1:23:45';
      case MeasurementType.distance:
        return 'e.g. 5.2';
      case MeasurementType.score:
        return 'e.g. 850';
      case MeasurementType.percentage:
        return 'e.g. 92';
    }
  }

  TextInputType get _keyboardType {
    if (measurementType == MeasurementType.duration &&
        MeasurementUnits.isTimeUnit(unit)) {
      return TextInputType.text;
    }
    if (measurementType == MeasurementType.score) {
      return TextInputType.text;
    }
    return const TextInputType.numberWithOptions(decimal: true);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: _keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: _hint,
        suffixText: _suffix(unit),
      ),
    );
  }

  static String? _suffix(String unit) {
    if (MeasurementUnits.isTimeUnit(unit)) return null;
    return MeasurementUnits.label(unit);
  }
}

String? validateResult(String? value, {String field = 'Result'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field is required';
  }
  return null;
}

String? validateOptionalResult(String? value) => null;
