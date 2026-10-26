import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'rooz_calendar_controller.dart';
import 'rooz_calendar_flutter.dart';

/// Optional editing of both range endpoints. Only visible day cells are drop
/// targets; dragging one endpoint holds the other fixed and never navigates months.
@immutable
class RoozCalendarMotion {
  final bool dragRangeStart, dragRangeEnd, hapticFeedback, immediateMouseDrag;
  final Duration holdDelay, duration;
  final double hoverScale;
  final Curve curve;
  final String startHandleHint, endHandleHint;
  const RoozCalendarMotion({
    this.dragRangeStart = true,
    this.dragRangeEnd = true,
    this.startHandleHint =
        'برای تغییر شروع بازه بکشید؛ روی صفحهٔ لمسی ابتدا نگه دارید',
    this.immediateMouseDrag = true,
    this.hapticFeedback = false,
    this.holdDelay = const Duration(milliseconds: 350),
    this.duration = const Duration(milliseconds: 160),
    this.hoverScale = 1.06,
    this.curve = Curves.easeOutCubic,
    this.endHandleHint =
        'برای تغییر پایان بازه نگه دارید و روی روز دیگری رها کنید',
  }) : assert(hoverScale >= 1 && hoverScale <= 1.5);
}

class _RangeDrag {
  final bool start, end;
  final RoozCalendarController controller;
  final DateSelection selection;
  final RoozSelectionPolicy policy;
  _RangeDrag(this.controller, {required this.start, required this.end})
      : selection = controller.selection,
        policy = controller.policy;
  bool editsStart(CivilDate date) =>
      start && (!end || date.epochDay < selection.start!.epochDay);
  bool canDrop(CivilDate date) => editsStart(date)
      ? controller.canResizeStart(date)
      : controller.canResizeEnd(date);
  bool commit(CivilDate date) => editsStart(date)
      ? controller.resizeStart(date)
      : controller.resizeEnd(date);
  bool get current =>
      identical(selection, controller.selection) &&
      identical(policy, controller.policy);
}

/// Internal presentation adapter shared by default and custom day builders.
class RoozRangeEndTarget extends StatelessWidget {
  final RoozCalendarController controller;
  final RoozCalendarMotion motion;
  final CivilDate date;
  final String label;
  final Widget child;
  const RoozRangeEndTarget(
      {super.key,
      required this.controller,
      required this.motion,
      required this.date,
      required this.label,
      required this.child});

  @override
  Widget build(BuildContext context) {
    assert(!motion.holdDelay.isNegative && !motion.duration.isNegative);
    if ((!motion.dragRangeEnd && !motion.dragRangeStart) ||
        controller.policy.mode != SelectionMode.range) return child;
    final start = motion.dragRangeStart &&
        controller.selection.isComplete &&
        controller.selection.start?.epochDay == date.epochDay;
    final end = motion.dragRangeEnd &&
        controller.selection.isComplete &&
        controller.selection.end?.epochDay == date.epochDay;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : motion.duration;
    final colors = Theme.of(context).colorScheme;
    Widget target = DragTarget<_RangeDrag>(
        onWillAcceptWithDetails: (details) =>
            identical(details.data.controller, controller) &&
            details.data.current &&
            details.data.canDrop(date),
        onAcceptWithDetails: (details) {
          if (details.data.current &&
              details.data.commit(date) &&
              motion.hapticFeedback) HapticFeedback.selectionClick();
        },
        builder: (context, candidates, rejected) {
          final active = candidates.isNotEmpty;
          final invalid =
              rejected.any((d) => identical(d?.controller, controller));
          return AnimatedScale(
              scale: active ? motion.hoverScale : 1,
              duration: duration,
              curve: motion.curve,
              child: AnimatedContainer(
                  key: ValueKey('range-drop-${date.epochDay}'),
                  duration: duration,
                  curve: motion.curve,
                  foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          width: 2,
                          color: active
                              ? colors.primary
                              : invalid
                                  ? colors.error
                                  : Colors.transparent)),
                  child: child));
        });
    if (!start && !end) return target;
    final edge = start && end
        ? "both"
        : start
            ? "start"
            : "end";
    final drag = _EndpointDraggable(
        key: ValueKey(
            'range-$edge-${date.epochDay}-${motion.immediateMouseDrag}-${motion.holdDelay.inMicroseconds}'),
        mouseOnly: false,
        immediateMouseDrag: motion.immediateMouseDrag,
        data: _RangeDrag(controller, start: start, end: end),
        delay: motion.holdDelay,
        maxSimultaneousDrags: 1,
        onDragStarted:
            motion.hapticFeedback ? HapticFeedback.selectionClick : null,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
            color: colors.primary,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(label, style: TextStyle(color: colors.onPrimary)))),
        child: target);
    return Semantics(
        hint: start && end
            ? '${motion.startHandleHint}؛ ${motion.endHandleHint}'
            : start
                ? motion.startHandleHint
                : motion.endHandleHint,
        child: motion.immediateMouseDrag
            ? MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: _EndpointDraggable(
                    key: ValueKey('range-mouse-$edge-${date.epochDay}'),
                    mouseOnly: true,
                    immediateMouseDrag: true,
                    delay: Duration.zero,
                    data: _RangeDrag(controller, start: start, end: end),
                    maxSimultaneousDrags: 1,
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: drag.feedback,
                    onDragStarted: motion.hapticFeedback
                        ? HapticFeedback.selectionClick
                        : null,
                    child: drag))
            : drag);
  }
}

/// Each input kind participates in exactly one gesture arena recognizer.
/// A pointer-kind switch during onPointerDown would recreate the recognizer
/// mid-gesture and lose the initial event; separate recognizers avoid that race.
class _EndpointDraggable extends Draggable<_RangeDrag> {
  final bool mouseOnly, immediateMouseDrag;
  final Duration delay;
  const _EndpointDraggable(
      {super.key,
      required super.child,
      required super.feedback,
      required super.data,
      required this.mouseOnly,
      required this.immediateMouseDrag,
      required this.delay,
      super.maxSimultaneousDrags,
      super.dragAnchorStrategy,
      super.onDragStarted});
  @override
  MultiDragGestureRecognizer createRecognizer(
      GestureMultiDragStartCallback onStart) {
    if (mouseOnly) {
      return ImmediateMultiDragGestureRecognizer(
          supportedDevices: const {PointerDeviceKind.mouse},
          allowedButtonsFilter: (buttons) => buttons == kPrimaryButton)
        ..onStart = onStart;
    }
    return DelayedMultiDragGestureRecognizer(
        delay: delay,
        supportedDevices: immediateMouseDrag
            ? PointerDeviceKind.values
                .where((kind) => kind != PointerDeviceKind.mouse)
                .toSet()
            : null,
        allowedButtonsFilter: (buttons) => buttons == kPrimaryButton)
      ..onStart = onStart;
  }
}
