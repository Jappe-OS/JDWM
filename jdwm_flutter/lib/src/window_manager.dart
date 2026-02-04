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

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'client_cursor.dart';
import 'monitor_region.dart';
import 'window_entry.dart';
import 'window_hierarchy.dart';

class WindowManager extends StatefulWidget {
  final List<MonitorConfig> monitors;
  final Widget Function(BuildContext context, MonitorConfig monitor)? monitorBuilder;
  final Widget Function(BuildContext context, MonitorConfig monitor)? monitorOverlayBuilder;

  const WindowManager({
    super.key,
    required this.monitors,
    this.monitorBuilder,
    this.monitorOverlayBuilder,
  });

  @override
  State<WindowManager> createState() => WindowManagerState();

  static WindowManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<WindowManagerState>();
  }
}

class WindowManagerState extends State<WindowManager> {
  final GlobalKey<WindowHierarchyState> _hierarchyKey = GlobalKey();
  final Map<String, GlobalKey> _regionKeys = {};

  Widget? _clientCursor;

  @override
  void initState() {
    super.initState();
    for (final monitor in widget.monitors) {
      _regionKeys[monitor.id] = GlobalKey();
    }
  }

  /// Returns the [MonitorConfig] whose bounds contain [position], or null.
  MonitorConfig? getMonitorAtPosition(Offset position) {
    for (final monitor in widget.monitors) {
      if (monitor.bounds.contains(position)) {
        return monitor;
      }
    }
    return null;
  }

  /// Look up a [MonitorConfig] by id.
  MonitorConfig? getMonitorById(String id) {
    try {
      return widget.monitors.firstWhere((m) => m.id == id);
    } on StateError {
      return null;
    }
  }

  /// Returns the [GlobalKey] for the [MonitorRegion] widget of the given
  /// monitor.
  GlobalKey? getRegionKey(String monitorId) => _regionKeys[monitorId];

  void setClientCursor(SystemMouseCursor cursor, Offset globalPosition) {
    setState(() => _clientCursor = Positioned(
      left: globalPosition.dx,
      top: globalPosition.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: ClientCursor.get(cursor),
      ),
    ));
  }

  void endClientCursor() {
    setState(() => _clientCursor = null);
  }

  void pushWindow(WindowEntry entry, {String? monitorId}) {
    final targetMonitorId = monitorId ?? widget.monitors.first.id;
    entry.monitorId = targetMonitorId;
    _hierarchyKey.currentState?.pushWindowEntry(entry);
  }

  void popWindow(WindowEntry entry) {
    _hierarchyKey.currentState?.popWindowEntry(entry);
  }

  List<WindowEntry> getAllWindows() {
    return _hierarchyKey.currentState?.windows ?? [];
  }

  List<WindowEntry> getWindowsOnMonitor(String monitorId) {
    return _hierarchyKey.currentState?.windows
            .where((e) => e.monitorId == monitorId)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: per-monitor background (rootWindow)
        if (widget.monitorBuilder != null) ... [
          ...widget.monitors.map((monitor) {
            return Positioned(
              left: monitor.bounds.left,
              top: monitor.bounds.top,
              width: monitor.bounds.width,
              height: monitor.bounds.height,
              child: widget.monitorBuilder!(context, monitor),
            );
          }),
        ],

        // Layer 2: per-monitor regions (spatial anchors for coordinate
        // conversion; no window state lives here)
        for (final monitor in widget.monitors)
          Positioned(
            left: monitor.bounds.left,
            top: monitor.bounds.top,
            child: MonitorRegion(
              config: monitor,
              regionKey: _regionKeys[monitor.id]!,
              child: const SizedBox.shrink(),
            ),
          ),

        // Layer 3: the single window stack, sized to the full global area
        Positioned.fill(
          child: WindowHierarchy(
            key: _hierarchyKey,
          ),
        ),

        // Layer 4: per-monitor overlays (e.g. monitor-specific toolbars)
        if (widget.monitorOverlayBuilder != null) ... [
          ...widget.monitors.map((monitor) {
            return Positioned(
              left: monitor.bounds.left,
              top: monitor.bounds.top,
              width: monitor.bounds.width,
              height: monitor.bounds.height,
              child: widget.monitorOverlayBuilder!(context, monitor),
            );
          }),
        ],

        // Layer 5: client cursor overlay
        if (_clientCursor != null) ... [
          _clientCursor!,
          const Positioned.fill(
            child: MouseRegion(
              opaque: false,
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.none,
            ),
          ),
        ]
      ],
    );
  }
}

/// Immutable description of one physical monitor.
class MonitorConfig {
  final String id;
  final Rect bounds; // Position and size in global coordinates
  final EdgeInsets? margin;

  const MonitorConfig({
    required this.id,
    required this.bounds,
    this.margin,
  });

  /// The usable area inside [bounds] after applying [margin].
  Rect get usableBounds {
    final m = margin ?? EdgeInsets.zero;
    return Rect.fromLTRB(
      bounds.left + m.left,
      bounds.top + m.top,
      bounds.right - m.right,
      bounds.bottom - m.bottom,
    );
  }

  /// Usable size (convenience).
  Size get usableSize => usableBounds.size;
}