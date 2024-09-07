import 'package:flutter/material.dart';

extension SpaceExtension on num{
  SizedBox get height => SizedBox(height: toDouble());
  SizedBox get Widget => SizedBox(width: toDouble());
}