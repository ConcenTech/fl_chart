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

  RadialChartData _dataWithSpacesIfRequired() {
    if (widget.data.showSectionsSpace) {
      var newData = <RadialChartSectionData>[];
      for (var section in widget.data.sections) {
        newData.add(section);
        if (section.value > 0) {
          newData.add(_emptySection);
        }
      }
      return widget.data.copyWith(sections: newData);
    }
    return widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final showingData = _getData();

    /// Wr wrapped our chart with [GestureDetector], and onLongPressStart callback.
    /// because we wanted to lock the widget from being scrolled when user long presses on it.
    /// If we found a solution for solve this issue, then we can remove this undoubtedly.
    return GestureDetector(
      onLongPressStart: (details) {},
      child: RadialChartLeaf(
        data: _radialChartDataTween!.evaluate(animation),
        targetData: showingData,
        touchCallback: (response) {
          showingData.radialTouchData.touchCallback?.call(response);
        },
      ),
    );
  }

  /// if builtIn touches are enabled, we should recreate our [radialChartData]
  /// to handle built in touches
  RadialChartData _getData() {
    return _dataWithSpacesIfRequired();
  }

  RadialChartSectionData get _emptySection {
    return RadialChartSectionData(
      value: 0.5,
      showTitle: false,
      color: Colors.transparent,
    );
  }

  @override
  void forEachTween(visitor) {
    _radialChartDataTween = visitor(
      _radialChartDataTween,
      _dataWithSpacesIfRequired(),
      (dynamic value) => RadialChartDataTween(begin: value, end: _dataWithSpacesIfRequired()),
    ) as RadialChartDataTween;
  }
}
