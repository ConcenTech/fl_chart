import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../fl_chart.dart';
import '../../utils/canvas_wrapper.dart';
import '../base/base_chart/base_chart_painter.dart';
import '../base/base_chart/render_base_chart.dart';
import 'radial_chart_painter.dart';

/// Low level RadialChart Widget.
class RadialChartLeaf extends MultiChildRenderObjectWidget {
  RadialChartLeaf({
    Key? key,
    required this.data,
    required this.targetData,
  }) : super(
          key: key,
          children: targetData.sections.map((e) => e.badgeWidget).toList(),
        );

  final RadialChartData data, targetData;

  @override
  RenderRadialChart createRenderObject(BuildContext context) => RenderRadialChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaleFactor,
      );

  @override
  void updateRenderObject(BuildContext context, RenderRadialChart renderObject) {
    renderObject
      ..data = data
      ..targetData = targetData
      ..textScale = MediaQuery.of(context).textScaleFactor;
  }
}

/// Renders our RadialChart, also handles hitTest.
class RenderRadialChart extends RenderBaseChart<RadialTouchResponse>
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData>
    implements MouseTrackerAnnotation {
  RenderRadialChart(
    BuildContext context,
    RadialChartData data,
    RadialChartData targetData,
    double textScale,
  )   : _buildContext = context,
        _data = data,
        _targetData = targetData,
        _textScale = textScale,
        super(targetData.radialTouchData.touchCallback);

  final BuildContext _buildContext;

  RadialChartData get data => _data;
  RadialChartData _data;
  set data(RadialChartData value) {
    if (_data == value) return;
    _data = value;
    // We must update layout to draw badges correctly!
    markNeedsLayout();
  }

  RadialChartData get targetData => _targetData;
  RadialChartData _targetData;
  set targetData(RadialChartData value) {
    if (_targetData == value) return;
    _targetData = value;
    // We must update layout to draw badges correctly!
    markNeedsLayout();
  }

  double get textScale => _textScale;
  double _textScale;
  set textScale(double value) {
    if (_textScale == value) return;
    _textScale = value;
    markNeedsPaint();
  }

  final _painter = RadialChartPainter();

  PaintHolder<RadialChartData> get paintHolder {
    return PaintHolder(data, targetData, textScale);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    var child = firstChild;
    size = computeDryLayout(constraints);

    final childConstraints = constraints.loosen();

    var counter = 0;
    var badgeOffsets = _painter.getBadgeOffsets(size, paintHolder);
    while (child != null) {
      if (counter >= badgeOffsets.length) {
        break;
      }
      child.layout(childConstraints, parentUsesSize: true);
      final childParentData = child.parentData! as MultiChildLayoutParentData;
      final sizeOffset = Offset(child.size.width / 2, child.size.height / 2);
      childParentData.offset = badgeOffsets[counter]! - sizeOffset;
      child = childParentData.nextSibling;
      counter++;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _painter.paint(_buildContext, CanvasWrapper(canvas, size), paintHolder);
    canvas.restore();
    defaultPaint(context, offset);
  }

  @override
  RadialTouchResponse getResponseAtLocation(Offset localPosition) {
    final section = _painter.handleTouch(localPosition, size, paintHolder);
    return RadialTouchResponse(section);
  }
}
