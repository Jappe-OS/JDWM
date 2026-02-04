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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowResizeGestureDetector extends StatelessWidget {
  final double borderThickness;
  final Map<Alignment, GestureDragUpdateCallback> listeners;
  final void Function(SystemMouseCursor, DragUpdateDetails) dragWithCursor;
  final GestureDragEndCallback onPanEnd;

  const WindowResizeGestureDetector({
    super.key,
    required this.borderThickness,
    required this.listeners,
    required this.dragWithCursor,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            buildGestureDetector(
              borderThickness,
              borderThickness,
              listeners[Alignment.topLeft]!,
              SystemMouseCursors.resizeUpLeftDownRight,
            ),
            Expanded(
              child: buildGestureDetector(
                null,
                borderThickness,
                listeners[Alignment.topCenter]!,
                SystemMouseCursors.resizeUpDown,
              ),
            ),
            buildGestureDetector(
              borderThickness,
              borderThickness,
              listeners[Alignment.topRight]!,
              SystemMouseCursors.resizeUpRightDownLeft,
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              buildGestureDetector(
                borderThickness,
                null,
                listeners[Alignment.centerLeft]!,
                SystemMouseCursors.resizeLeftRight,
              ),
              const Spacer(),
              buildGestureDetector(
                borderThickness,
                null,
                listeners[Alignment.centerRight]!,
                SystemMouseCursors.resizeLeftRight,
              ),
            ],
          ),
        ),
        Row(
          children: [
            buildGestureDetector(
              borderThickness,
              borderThickness,
              listeners[Alignment.bottomLeft]!,
              SystemMouseCursors.resizeUpRightDownLeft,
            ),
            Expanded(
              child: buildGestureDetector(
                null,
                borderThickness,
                listeners[Alignment.bottomCenter]!,
                SystemMouseCursors.resizeUpDown,
              ),
            ),
            buildGestureDetector(
              borderThickness,
              borderThickness,
              listeners[Alignment.bottomRight]!,
              SystemMouseCursors.resizeUpLeftDownRight,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildGestureDetector(
    double? width,
    double? height,
    GestureDragUpdateCallback onPanUpdate,
    SystemMouseCursor cursor,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanUpdate: (details) {
            dragWithCursor(cursor, details);
            onPanUpdate(details);
          },
          onPanEnd: onPanEnd,
        ),
      ),
    );
  }
}
