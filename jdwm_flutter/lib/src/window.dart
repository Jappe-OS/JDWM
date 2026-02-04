//  jdwm_flutter, The Flutter UI library for the JDWM window manager.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'window_manager.dart';
import 'window_entry.dart';
import 'window_hierarchy.dart';
import 'window_resize_gesture_detector.dart';

class TitlebarDragCallbacks extends InheritedWidget {
  final void Function(DragDownDetails) onDragStart;
  final void Function(DragUpdateDetails) onDrag;
  final void Function(DragEndDetails) onDragEnd;

  const TitlebarDragCallbacks({
    super.key,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required super.child,
  });

  static TitlebarDragCallbacks? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TitlebarDragCallbacks>();
  }

  @override
  bool updateShouldNotify(TitlebarDragCallbacks oldWidget) => true;
}

class Window extends StatefulWidget {
  final WindowEntry entry;

  const Window({
    required super.key,
    required this.entry,
  });

  @override
  _WindowState createState() => _WindowState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      entry.title;
}

class _WindowState extends State<Window> {
  static const double _resizingSpacing = 8;

  final GlobalKey _mainContainerKey = GlobalKey();
  DragUpdateDetails? _lastDragDetails;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WindowEntry>.value(
      value: widget.entry,
      builder: (context, child) {
        final entry = context.watch<WindowEntry>();
        final hierarchy = context.watch<WindowHierarchyState>();

        if (entry.minimized) return const SizedBox.shrink();

        final manager = WindowManager.of(context);
        final monitor = manager?.getMonitorById(entry.monitorId ?? '');
        final usable = monitor?.usableBounds;

        final docked =
            entry.maximized || entry.windowDock != WindowDock.normal;

        final Rect windowRect;
        if (entry.maximized && usable != null) {
          windowRect = usable;
        } else if (usable != null) {
          windowRect = _getDockedRect(entry, usable);
        } else {
          windowRect = entry.windowRect;
        }

        return Positioned.fromRect(
          rect: windowRect,
          child: Stack(
            children: [
              GestureDetector(
                onPanStart: (details) {
                  hierarchy.requestWindowFocus(entry);
                  setState(() {});
                },
                onTapDown: (details) {
                  hierarchy.requestWindowFocus(entry);
                  setState(() {});
                },
                behavior: HitTestBehavior.translucent,
                child: _buildContainer(
                  hasBorder: !docked,
                  child: Column(
                    children: [
                      Visibility(
                        visible: entry.usesToolbar,
                        child: TitlebarDragCallbacks(
                          onDragStart: _onTitlebarDragStart,
                          onDrag: _onTitlebarDrag,
                          onDragEnd: _onTitlebarDragEnd,
                          child:
                              entry.toolbar ?? const SizedBox.shrink(),
                        ),
                      ),
                      Expanded(
                        child: RepaintBoundary(
                          key: entry.repaintBoundaryKey,
                          child: MediaQuery(
                            data: MediaQueryData(
                              size: Size(
                                windowRect.width,
                                windowRect.height - entry.minSize.height,
                              ),
                            ),
                            child: ClipRect(
                              child: entry.content,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: !docked && entry.allowResize,
                child: WindowResizeGestureDetector(
                  borderThickness: _resizingSpacing,
                  listeners: _resizeListeners,
                  dragWithCursor: _onResizePanWithCursor,
                  onPanEnd: (details) {
                    entry.windowRect = Rect.fromLTWH(
                      entry.windowRect.left,
                      entry.windowRect.top,
                      max(entry.minSize.width, entry.windowRect.width),
                      max(entry.minSize.height, entry.windowRect.height),
                    );
                    final manager = WindowManager.of(context);
                    manager?.endClientCursor();
                    _updateMonitorFromRect(entry, manager);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer({bool hasBorder = false, required Widget child}) {
    if (hasBorder) {
      return DualBorderOutlinedContainer(
        key: _mainContainerKey,
        borderRadius: Theme.of(context).borderRadiusLg,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    } else {
      return DualBorderOutlinedContainer(
        key: _mainContainerKey,
        borderRadius: BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        hasBorder: false,
        child: child,
      );
    }
  }

  void _onTitlebarDragStart(DragDownDetails details) {
    Provider.of<WindowHierarchyState>(context, listen: false)
        .requestWindowFocus(widget.entry);
  }

  void _onTitlebarDrag(DragUpdateDetails details) {
    _lastDragDetails = details;
    final entry = widget.entry;
    final hierarchy =
        Provider.of<WindowHierarchyState>(context, listen: false);
    final manager = WindowManager.of(context);
    final docked =
        entry.maximized || entry.windowDock != WindowDock.normal;

    if (manager != null) {
      final newMonitor =
          manager.getMonitorAtPosition(details.globalPosition);
      if (newMonitor != null && newMonitor.id != entry.monitorId) {
        entry.monitorId = newMonitor.id;
      }
      manager.setClientCursor(
        SystemMouseCursors.grabbing,
        details.globalPosition,
      );
    }

    final Rect base;
    if (docked) {
      base = Rect.fromLTWH(
        details.globalPosition.dx - entry.windowRect.width / 2,
        0,
        entry.windowRect.width,
        entry.windowRect.height,
      );
    } else {
      base = entry.windowRect;
    }

    hierarchy.requestWindowFocus(entry);
    entry.maximized = false;
    entry.windowDock = WindowDock.normal;

    entry.windowRect = base.translate(
      details.delta.dx,
      details.delta.dy,
    );

    setState(() {});
  }

  void _onTitlebarDragEnd(DragEndDetails details) {
    final entry = widget.entry;
    final manager = WindowManager.of(context);
    if (manager == null || _lastDragDetails == null) return;

    final monitor = manager.getMonitorById(entry.monitorId ?? '');
    if (monitor == null) return;

    final regionKey = manager.getRegionKey(monitor.id);
    if (regionKey == null) return;

    manager.endClientCursor();

    final RenderBox? regionBox =
        regionKey.currentContext?.findRenderObject() as RenderBox?;
    if (regionBox == null) return;

    final localPosition =
        regionBox.globalToLocal(_lastDragDetails!.globalPosition);
    final localUsableWidth = monitor.usableBounds.width;

    if ((localPosition.dy <= 2 && localPosition.dx <= 50) ||
        (localPosition.dy <= 50 && localPosition.dx <= 2)) {
      entry.windowDock = WindowDock.topLeft;
      return;
    }
    if ((localPosition.dy <= 2 &&
            localPosition.dx >= localUsableWidth - 50) ||
        (localPosition.dy <= 50 &&
            localPosition.dx >= localUsableWidth - 2)) {
      entry.windowDock = WindowDock.topRight;
      return;
    }
    if (localPosition.dy <= 2) {
      entry.maximized = true;
      return;
    }
    if (localPosition.dx <= 2) {
      entry.windowDock = WindowDock.left;
      return;
    }
    if (localPosition.dx >= localUsableWidth - 2) {
      entry.windowDock = WindowDock.right;
      return;
    }
  }

  Rect _getDockedRect(WindowEntry entry, Rect usable) {
    switch (entry.windowDock) {
      case WindowDock.topLeft:
        return Rect.fromLTWH(usable.left, usable.top, usable.width / 2,
            usable.height / 2);
      case WindowDock.top:
        return Rect.fromLTWH(
            usable.left, usable.top, usable.width, usable.height / 2);
      case WindowDock.topRight:
        return Rect.fromLTWH(usable.left + usable.width / 2, usable.top,
            usable.width / 2, usable.height / 2);
      case WindowDock.left:
        return Rect.fromLTWH(
            usable.left, usable.top, usable.width / 2, usable.height);
      case WindowDock.right:
        return Rect.fromLTWH(usable.left + usable.width / 2, usable.top,
            usable.width / 2, usable.height);
      case WindowDock.bottomLeft:
        return Rect.fromLTWH(usable.left, usable.top + usable.height / 2,
            usable.width / 2, usable.height / 2);
      case WindowDock.bottom:
        return Rect.fromLTWH(usable.left, usable.top + usable.height / 2,
            usable.width, usable.height / 2);
      case WindowDock.bottomRight:
        return Rect.fromLTWH(usable.left + usable.width / 2,
            usable.top + usable.height / 2, usable.width / 2,
            usable.height / 2);
      case WindowDock.normal:
      default:
        return Rect.fromLTWH(
          entry.windowRect.left,
          max(usable.top, entry.windowRect.top),
          max(entry.minSize.width, entry.windowRect.width),
          max(entry.minSize.height, entry.windowRect.height),
        );
    }
  }

  Map<Alignment, GestureDragUpdateCallback> get _resizeListeners => {
        Alignment.topLeft: (details) =>
            _onResizePanUpdate(details, top: true, left: true),
        Alignment.topCenter: (details) =>
            _onResizePanUpdate(details, top: true),
        Alignment.topRight: (details) =>
            _onResizePanUpdate(details, top: true, right: true),
        Alignment.centerLeft: (details) =>
            _onResizePanUpdate(details, left: true),
        Alignment.centerRight: (details) =>
            _onResizePanUpdate(details, right: true),
        Alignment.bottomLeft: (details) =>
            _onResizePanUpdate(details, bottom: true, left: true),
        Alignment.bottomCenter: (details) =>
            _onResizePanUpdate(details, bottom: true),
        Alignment.bottomRight: (details) =>
            _onResizePanUpdate(details, bottom: true, right: true),
      };

  void _onResizePanUpdate(
    DragUpdateDetails details, {
    bool left = false,
    bool top = false,
    bool right = false,
    bool bottom = false,
  }) {
    Provider.of<WindowHierarchyState>(context, listen: false)
        .requestWindowFocus(widget.entry);

    double delta(bool apply, Axis axis) {
      final d =
          axis == Axis.horizontal ? details.delta.dx : details.delta.dy;
      return apply ? d : 0;
    }

    widget.entry.windowRect = Rect.fromLTRB(
      widget.entry.windowRect.left + delta(left, Axis.horizontal),
      widget.entry.windowRect.top + delta(top, Axis.vertical),
      widget.entry.windowRect.right + delta(right, Axis.horizontal),
      widget.entry.windowRect.bottom + delta(bottom, Axis.vertical),
    );

    setState(() {});
  }

  void _onResizePanWithCursor(
    SystemMouseCursor cursor,
    DragUpdateDetails details,
  ) {
    final manager = WindowManager.of(context);
    manager?.setClientCursor(cursor, details.globalPosition);
  }

  void _updateMonitorFromRect(WindowEntry entry, WindowManagerState? manager) {
    if (manager == null) return;
    final centre = entry.windowRect.center;
    final monitor = manager.getMonitorAtPosition(centre);
    if (monitor != null && monitor.id != entry.monitorId) {
      entry.monitorId = monitor.id;
    }
  }
}