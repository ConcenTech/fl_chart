import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/material.dart';

import '../base/base_chart/base_chart_data.dart';
import 'radial_chart.dart';

/// [RadialChart] needs this class to render itself.
///
/// It holds data needed to draw a radial chart,
/// including radial sections, colors, ...
class RadialChartData extends BaseChartData with EquatableMixin {
  /// Defines showing sections of the [RadialChart].
  final List<RadialChartSectionData> sections;

  /// Radius of free space in center of the circle.
  final double centerSpaceRadius;

  /// Defines the thickness of all sections.
  final double sectionThickness;

  /// Color of free space in center of the circle.
  final Color centerSpaceColor;

  /// Defines gap between sections.
  final double sectionsSpace;

  final bool showSectionsSpace;

  /// Defines the curve of the end of sections
  final double sectionEndRadius;

  /// [RadialChart] draws [sections] from zero degree (right side of the circle) clockwise.
  final double startDegreeOffset;

  /// Handles touch behaviors and responses.
  final RadialTouchData radialTouchData;

  /// We hold this value to determine weight of each [RadialChartSectionData.value].
  double get sumValue =>
      sections.map((data) => data.value).reduce((first, second) => first + second);

  /// [RadialChart] draws some [sections] in a circle,
  /// and applies free space with radius [centerSpaceRadius],
  /// and color [centerSpaceColor] in the center of the circle,
  /// if you don't want it, set [centerSpaceRadius] to zero.
  ///
  /// It draws [sections] from zero degree (right side of the circle) clockwise,
  /// you can change the starting point, by changing [startDegreeOffset] (in degrees).
  ///
  /// You can define a gap between [sections] by setting [sectionsSpace].
  ///
  /// You can modify [radialTouchData] to customize touch behaviors and responses.
  RadialChartData({
    List<RadialChartSectionData>? sections,
    double? centerSpaceRadius,
    double? sectionEndRadius,
    Color? centerSpaceColor,
    double? sectionsSpace,
    bool? showSectionsSpace,
    double? sectionThickness,
    double? startDegreeOffset,
    RadialTouchData? radialTouchData,
    FlBorderData? borderData,
  })  : sections = sections ?? const [],
        centerSpaceRadius = centerSpaceRadius ?? double.infinity,
        showSectionsSpace = showSectionsSpace ?? false,
        sectionEndRadius = sectionEndRadius ?? 10,
        centerSpaceColor = centerSpaceColor ?? Colors.transparent,
        sectionsSpace = sectionsSpace ?? 2,
        sectionThickness = sectionThickness ?? 40,
        startDegreeOffset = startDegreeOffset ?? 0,
        radialTouchData = radialTouchData ?? RadialTouchData(),
        super(
          borderData: borderData ?? FlBorderData(show: false),
          touchData: radialTouchData ?? RadialTouchData(),
        );

  /// Coradials current [RadialChartData] to a new [RadialChartData],
  /// and replaces provided values.
  RadialChartData copyWith({
    List<RadialChartSectionData>? sections,
    double? centerSpaceRadius,
    Color? centerSpaceColor,
    double? sectionsSpace,
    double? startDegreeOffset,
    RadialTouchData? radialTouchData,
    FlBorderData? borderData,
  }) {
    return RadialChartData(
      sections: sections ?? this.sections,
      centerSpaceRadius: centerSpaceRadius ?? this.centerSpaceRadius,
      centerSpaceColor: centerSpaceColor ?? this.centerSpaceColor,
      sectionsSpace: sectionsSpace ?? this.sectionsSpace,
      startDegreeOffset: startDegreeOffset ?? this.startDegreeOffset,
      radialTouchData: radialTouchData ?? this.radialTouchData,
      borderData: borderData ?? this.borderData,
    );
  }

  /// Lerps a [BaseChartData] based on [t] value, check [Tween.lerp].
  @override
  RadialChartData lerp(BaseChartData a, BaseChartData b, double t) {
    if (a is RadialChartData && b is RadialChartData) {
      return RadialChartData(
        borderData: FlBorderData.lerp(a.borderData, b.borderData, t),
        centerSpaceColor: Color.lerp(a.centerSpaceColor, b.centerSpaceColor, t),
        centerSpaceRadius:
            lerpDoubleAllowInfinity(a.centerSpaceRadius, b.centerSpaceRadius, t) ?? 20.0,
        radialTouchData: b.radialTouchData,
        sectionsSpace: lerpDouble(a.sectionsSpace, b.sectionsSpace, t),
        startDegreeOffset: lerpDouble(a.startDegreeOffset, b.startDegreeOffset, t),
        sections: lerpRadialChartSectionDataList(a.sections, b.sections, t),
      );
    } else {
      throw Exception('Illegal State');
    }
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        sections,
        centerSpaceRadius,
        centerSpaceColor,
        radialTouchData,
        sectionsSpace,
        startDegreeOffset,
        borderData,
      ];
}

class RadialChartStack {
  final List<RadialChartData> chartData;

  RadialChartStack({required this.chartData});
}

/// Holds data related to drawing each [RadialChart] section.
class RadialChartSectionData {
  /// It determines how much space it should occupy around the circle.
  ///
  /// This is depends on sum of all sections, each section should
  /// occupy ([value] / sumValues) * 360 degrees.
  ///
  /// value can not be null.
  final double value;

  /// Defines the color of section.
  final Color color;

  /// Defines show or hide the title of section.
  final bool showTitle;

  /// Defines style of showing title of section.
  final TextStyle? titleStyle;

  /// Defines text of showing title at the middle of section.
  final String title;

  /// Defines border stroke around the section
  final BorderSide borderSide;

  /// Defines a widget that represents the section.
  ///
  /// This can be anything from a text, an image, an animation, and even a combination of widgets.
  /// Use AnimatedWidgets to animate this widget.
  final Widget badgeWidget;

  /// Defines position of showing title in the section.
  ///
  /// It should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [RadialChart].
  final double titlePositionPercentageOffset;

  /// Defines position of badge widget in the section.
  ///
  /// It should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [RadialChart].
  final double badgePositionPercentageOffset;

  /// [RadialChart] draws section from right side of the circle (0 degrees),
  /// each section have a [value] that determines how much it should occupy,
  /// this is depends on sum of all sections, each section should
  /// occupy ([value] / sumValues) * 360 degrees.
  ///
  /// It draws this section with filled [color], and [radius].
  ///
  /// If [showTitle] is true, it draws a title at the middle of section,
  /// you can set the text using [title], and set the style using [titleStyle],
  /// by default it draws texts at the middle of section, but you can change the
  /// [titlePositionPercentageOffset] to have your desire design,
  /// it should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [RadialChart].
  ///
  /// If [badgeWidget] is not null, it draws a widget at the middle of section,
  /// by default it draws the widget at the middle of section, but you can change the
  /// [badgePositionPercentageOffset] to have your desire design,
  /// the value works the same way as [titlePositionPercentageOffset].
  RadialChartSectionData({
    double? value,
    Color? color,
    bool? showTitle,
    TextStyle? titleStyle,
    String? title,
    BorderSide? borderSide,
    Widget? badgeWidget,
    double? titlePositionPercentageOffset,
    double? badgePositionPercentageOffset,
  })  : value = value ?? 10,
        color = color ?? Colors.cyan,
        showTitle = showTitle ?? true,
        titleStyle = titleStyle,
        title = title ?? value.toString(),
        borderSide = borderSide ?? BorderSide(width: 0),
        badgeWidget = badgeWidget ?? Container(),
        titlePositionPercentageOffset = titlePositionPercentageOffset ?? 0.5,
        badgePositionPercentageOffset = badgePositionPercentageOffset ?? 0.5;

  /// Coradials current [RadialChartSectionData] to a new [RadialChartSectionData],
  /// and replaces provided values.
  RadialChartSectionData copyWith({
    double? value,
    Color? color,
    double? radius,
    bool? showTitle,
    TextStyle? titleStyle,
    String? title,
    BorderSide? borderSide,
    Widget? badgeWidget,
    double? titlePositionPercentageOffset,
    double? badgePositionPercentageOffset,
  }) {
    return RadialChartSectionData(
      value: value ?? this.value,
      color: color ?? this.color,
      showTitle: showTitle ?? this.showTitle,
      titleStyle: titleStyle ?? this.titleStyle,
      title: title ?? this.title,
      borderSide: borderSide ?? this.borderSide,
      badgeWidget: badgeWidget ?? this.badgeWidget,
      titlePositionPercentageOffset:
          titlePositionPercentageOffset ?? this.titlePositionPercentageOffset,
      badgePositionPercentageOffset:
          badgePositionPercentageOffset ?? this.badgePositionPercentageOffset,
    );
  }

  /// Lerps a [RadialChartSectionData] based on [t] value, check [Tween.lerp].
  static RadialChartSectionData lerp(RadialChartSectionData a, RadialChartSectionData b, double t) {
    return RadialChartSectionData(
      value: lerpDouble(a.value, b.value, t),
      color: Color.lerp(a.color, b.color, t),
      showTitle: b.showTitle,
      titleStyle: TextStyle.lerp(a.titleStyle, b.titleStyle, t),
      title: b.title,
      borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
      badgeWidget: b.badgeWidget,
      titlePositionPercentageOffset:
          lerpDouble(a.titlePositionPercentageOffset, b.titlePositionPercentageOffset, t),
      badgePositionPercentageOffset:
          lerpDouble(a.badgePositionPercentageOffset, b.badgePositionPercentageOffset, t),
    );
  }
}

/// [RadialChart]'s touch callback.
typedef RadialTouchCallback = void Function(RadialTouchResponse);

/// Holds data to handle touch events, and touch responses in the [RadialChart].
///
/// There is a touch flow, explained [here](https://github.com/imaNNeoFighT/fl_chart/blob/master/repo_files/documentations/handle_touches.md)
/// in a simple way, each chart's renderer captures the touch events, and passes the pointerEvent
/// to the painter, and gets touched spot, and wraps it into a concrete [RadialTouchResponse].
class RadialTouchData extends FlTouchData with EquatableMixin {
  /// you can implement it to receive touches callback
  final Function(RadialTouchResponse)? touchCallback;

  /// You can disable or enable the touch system using [enabled] flag,
  ///
  /// You can listen to touch events using [touchCallback],
  /// It gives you a [RadialTouchResponse] that contains some
  /// useful information about happened touch.
  RadialTouchData({
    bool? enabled,
    RadialTouchCallback? touchCallback,
  })  : touchCallback = touchCallback,
        super(enabled ?? true);

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        enabled,
      ];
}

class RadialTouchedSection with EquatableMixin {
  /// touch happened on this section
  final RadialChartSectionData? touchedSection;

  /// touch happened on this position
  final int touchedSectionIndex;

  /// touch happened with this angle on the [RadialChart]
  final double touchAngle;

  /// touch happened with this radius on the [RadialChart]
  final double touchRadius;

  /// This class Contains [touchedSection], [touchedSectionIndex] that tells
  /// you touch happened on which section,
  /// [touchAngle] gives you angle of touch,
  /// and [touchRadius] gives you radius of the touch.
  RadialTouchedSection(
    RadialChartSectionData? touchedSection,
    int touchedSectionIndex,
    double touchAngle,
    double touchRadius,
  )   : touchedSection = touchedSection,
        touchedSectionIndex = touchedSectionIndex,
        touchAngle = touchAngle,
        touchRadius = touchRadius;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        touchedSection,
        touchedSectionIndex,
        touchAngle,
        touchRadius,
      ];
}

/// Holds information about touch response in the [RadialChart].
///
/// You can override [RadialTouchData.touchCallback] to handle touch events,
/// it gives you a [RadialTouchResponse] and you can do whatever you want.
class RadialTouchResponse extends BaseTouchResponse {
  /// Contains information about touched section, like index, angle, radius, ...
  final RadialTouchedSection? touchedSection;

  /// If touch happens, [RadialChart] processes it internally and passes out a [RadialTouchResponse]
  /// that contains [touchedSection], [touchedSectionIndex] that tells
  /// you touch happened on which section,
  /// [touchAngle] gives you angle of touch,
  /// and [touchRadius] gives you radius of the touch.
  /// [touchInput] is the type of happened touch.
  RadialTouchResponse(
    RadialTouchedSection? touchedSection,
    PointerEvent touchInput,
    bool clickHappened,
  )   : touchedSection = touchedSection,
        super(touchInput, clickHappened);

  /// Coradials current [RadialTouchResponse] to a new [RadialTouchResponse],
  /// and replaces provided values.
  RadialTouchResponse copyWith({
    RadialTouchedSection? touchedSection,
    PointerEvent? touchInput,
    bool? clickHappened,
  }) {
    return RadialTouchResponse(
      touchedSection ?? this.touchedSection,
      touchInput ?? this.touchInput,
      clickHappened ?? this.clickHappened,
    );
  }
}

/// It lerps a [RadialChartData] to another [RadialChartData] (handles animation for updating values)
class RadialChartDataTween extends Tween<RadialChartData> {
  RadialChartDataTween({required RadialChartData begin, required RadialChartData end})
      : super(begin: begin, end: end);

  /// Lerps a [RadialChartData] based on [t] value, check [Tween.lerp].
  @override
  RadialChartData lerp(double t) => begin!.lerp(begin!, end!, t);
}
