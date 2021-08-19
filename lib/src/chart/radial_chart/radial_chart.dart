import 'package:fl_chart/src/chart/radial_chart/radial_chart_renderer.dart';
import 'package:flutter/material.dart';

import 'radial_chart_data.dart';

/// Renders a radial chart as a widget, using provided [RadialChartData].
class RadialChart extends ImplicitlyAnimatedWidget {
  /// Default duration to reuse externally.
  static const defaultDuration = Duration(milliseconds: 150);

  /// Determines how the [RadialChart] should be look like.
  final RadialChartData data;

  /// [data] determines how the [RadialChart] should be look like,
  /// when you make any change in the [RadialChartData], it updates
  /// new values with animation, and duration is [swapAnimationDuration].
  /// also you can change the [swapAnimationCurve]
  /// which default is [Curves.linear].
  const RadialChart(
    this.data, {
    Duration swapAnimationDuration = defaultDuration,
    Curve swapAnimationCurve = Curves.linear,
  }) : super(duration: swapAnimationDuration, curve: swapAnimationCurve);

  /// Creates a [_RadialChartState]
  @override
  _RadialChartState createState() => _RadialChartState();
}

class _RadialChartState extends AnimatedWidgetBaseState<RadialChart> {
  /// We handle under the hood animations (implicit animations) via this tween,
  /// it lerps between the old [RadialChartData] to the new one.
  RadialChartDataTween? _radialChartDataTween;

  @override
  void initState() {
    /// Make sure that [_widgetsPositionHandler] is updated.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final showingData = _getData();

    return RadialChartLeaf(
      data: _radialChartDataTween!.evaluate(animation),
      targetData: showingData,
    );
  }

  /// if builtIn touches are enabled, we should recreate our [radialChartData]
  /// to handle built in touches
  RadialChartData _getData() {
    return widget.data;
  }

  @override
  void forEachTween(visitor) {
    _radialChartDataTween = visitor(
      _radialChartDataTween,
      widget.data,
      (dynamic value) => RadialChartDataTween(begin: value, end: widget.data),
    ) as RadialChartDataTween;
  }
}
