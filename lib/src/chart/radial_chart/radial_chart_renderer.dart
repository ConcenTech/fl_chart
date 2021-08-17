import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'radial_chart_painter.dart';

/// Low level RadialChart Widget.
class RadialChartLeaf extends MultiChildRenderObjectWidget {
  RadialChartLeaf({
    Key? key,
    required this.data,
    required this.targetData,
    this.touchCallback,
  }) : super(
          key: key,
          children: targetData.sections.map((e) => e.badgeWidget).toList(),
        );

  final RadialChartData data, targetData;

  final RadialTouchCallback? touchCallback;

  @override
  RenderRadialChart createRenderObject(BuildContext context) => RenderRadialChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaleFactor,
        touchCallback,
      );

  @override
  void updateRenderObject(BuildContext context, RenderRadialChart renderObject) {
    renderObject
      ..data = data
      ..targetData = targetData
      ..textScale = MediaQuery.of(context).textScaleFactor
      ..touchCallback = touchCallback;
  }
}

/// Renders our RadialChart, also handles hitTest.
class RenderRadialChart extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData>
    implements MouseTrackerAnnotation {
  RenderRadialChart(
    BuildContext context,
    RadialChartData data,
    RadialChartData targetData,
    double textScale,
    RadialTouchCallback? touchCallback,
  )   : _buildContext = context,
        _data = data,
        _targetData = targetData,
        _textScale = textScale,
        _touchCallback = touchCallback;

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

  RadialTouchCallback? _touchCallback;
  set touchCallback(RadialTouchCallback? value) {
    _touchCallback = value;
  }

  final _painter = RadialChartPainter();

  PaintHolder<RadialChartData> get paintHolder {
    return PaintHolder(data, targetData, textScale);
  }

  RadialTouchedSection? _lastTouchedSpot;

  late bool _validForMouseTracker;

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
  Size computeDryLayout(BoxConstraints constraints) {
    return Size(constraints.maxWidth, constraints.maxHeight);
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
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    _handleEvent(event);
  }

  @override
  PointerExitEventListener? get onExit => (PointerExitEvent event) {
        _handleEvent(event);
      };

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  MouseCursor get cursor => MouseCursor.defer;

  @override
  bool get validForMouseTracker => _validForMouseTracker;

  void _handleEvent(PointerEvent event) {
    if (_touchCallback == null) {
      return;
    }
    var response = RadialTouchResponse(null, event, false);

    var touchedSection = _painter.handleTouch(event, size, paintHolder);
    if (touchedSection == null) {
      _touchCallback?.call(response);
      return;
    }
    response = response.copyWith(touchedSection: touchedSection);

    if (event is PointerDownEvent) {
      _lastTouchedSpot = touchedSection;
    } else if (event is PointerUpEvent) {
      if (_lastTouchedSpot == touchedSection) {
        response = response.copyWith(clickHappened: true);
      }
      _lastTouchedSpot = null;
    }

    _touchCallback?.call(response);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
  }

  @override
  void detach() {
    _validForMouseTracker = false;
    super.detach();
  }
}
