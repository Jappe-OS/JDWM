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

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'window_toolbar.dart';

class WindowEntry extends ChangeNotifier {
  final WindowEntryId id;
  String? _monitorId;
  String _title;
  ImageProvider _icon;
  final Widget content;
  late bool _usesToolbar;
  final Size minSize;
  late Rect _windowRect;
  Widget? _toolbar;
  bool _maximized = false;
  bool _minimized = false;
  WindowDock _windowDock = WindowDock.normal;
  final bool allowResize;

  final GlobalKey repaintBoundaryKey = GlobalKey();

  String? get monitorId => _monitorId;
  String get title => _title;
  ImageProvider get icon => _icon;
  bool get usesToolbar => _usesToolbar;
  Rect get windowRect => _windowRect;
  Widget? get toolbar => _toolbar;
  bool get maximized => _maximized;
  bool get minimized => _minimized;
  WindowDock get windowDock => _windowDock;

  set monitorId(String? value) {
    _monitorId = value;
    notifyListeners();
  }

  set title(String value) {
    _title = value;
    notifyListeners();
  }

  set icon(ImageProvider value) {
    _icon = value;
    notifyListeners();
  }

  set usesToolbar(bool value) {
    _usesToolbar = value;
    notifyListeners();
  }

  set windowRect(Rect value) {
    _windowRect = value;
    notifyListeners();
  }

  set toolbar(Widget? value) {
    _toolbar = value;
    notifyListeners();
  }

  set maximized(bool value) {
    _maximized = value;
    notifyListeners();
  }

  set minimized(bool value) {
    _minimized = value;
    notifyListeners();
  }

  set windowDock(WindowDock value) {
    _windowDock = value;
    notifyListeners();
  }

  WindowEntry({
    String title = "",
    required ImageProvider icon,
    required this.content,
    bool usesToolbar = true,
    Size initialSize = const Size(600, 480),
    this.minSize = const Size.square(100),
    this.allowResize = true,
  })  : id = WindowEntryId(),
        _title = title,
        _icon = icon,
        _usesToolbar = usesToolbar {
    windowRect = Rect.fromLTWH(
      0,
      0,
      initialSize.width,
      initialSize.height,
    );
    if (usesToolbar) {
      toolbar = const DefaultWindowToolbar();
    }
  }

  void toggleMaximize() {
    maximized = !maximized;
  }

  Future<Uint8List> getScreenshot() async {
    final box = repaintBoundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await box.toImage();
    final byteData = await image.toByteData(
      format: ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }
}

/// Stable, unique identifier for a [WindowEntry].
///
/// Uses a monotonically incrementing integer so that [==] and [hashCode]
/// are consistent and unique for the lifetime of the process - safe to use
/// as a [Map] key.
class WindowEntryId {
  static int _nextId = 0;
  final int _id = _nextId++;

  @override
  bool operator ==(Object other) =>
      other is WindowEntryId && _id == other._id;

  @override
  int get hashCode => _id;

  int compareTo(WindowEntryId other) => _id.compareTo(other._id);

  @override
  String toString() => _id.toString();
}

enum WindowDock {
  normal,
  topLeft,
  top,
  topRight,
  right,
  left,
  bottomLeft,
  bottom,
  bottomRight,
}