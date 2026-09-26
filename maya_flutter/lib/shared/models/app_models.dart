import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

class RectConverter implements JsonConverter<Rect, Map<String, double>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, double> json) {
    return Rect.fromLTRB(
      json['left'] ?? 0,
      json['top'] ?? 0,
      json['right'] ?? 0,
      json['bottom'] ?? 0,
    );
  }

  @override
  Map<String, double> toJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }
}