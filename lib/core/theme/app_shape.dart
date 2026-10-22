import 'package:flutter/material.dart';

/// Corner radii, Apple-style: one small scale and continuous (superellipse)
/// corners. Nested content that hugs an edge is clipped by its container, so
/// inner corners stay concentric. Use these instead of literal radii.
abstract final class AppRadius {
  /// Pills, chips, small badges.
  static const xs = 8.0;

  /// Inputs, small tiles, menu rows.
  static const sm = 12.0;

  /// Notes, menus, list groups.
  static const md = 16.0;

  /// Cards and buttons — the default surface.
  static const lg = 20.0;

  /// Hero cards and sheets' outer edge.
  static const xl = 26.0;

  /// Bottom sheets / action sheets.
  static const sheet = 30.0;

  /// Icon tiles round with their size, like app icons (~22.5%).
  static double tile(double size) => size * .27;
}

/// Continuous-corner shapes. `RoundedSuperellipseBorder` is Flutter's
/// equivalent of SwiftUI's `.continuous` corner style: the curvature ramps
/// in, so corners never look "stuck on".
abstract final class AppShape {
  static OutlinedBorder of(double radius,
          {BorderSide side = BorderSide.none}) =>
      RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius), side: side);

  static ShapeDecoration decoration(
          {required double radius,
          Color? color,
          Gradient? gradient,
          BorderSide side = BorderSide.none,
          List<BoxShadow>? shadows}) =>
      ShapeDecoration(
          shape: of(radius, side: side),
          color: color,
          gradient: gradient,
          shadows: shadows);
}
