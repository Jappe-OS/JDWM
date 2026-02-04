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

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'window.dart';
import 'window_entry.dart';
import 'window_hierarchy.dart';

class DefaultWindowToolbar extends StatelessWidget {
  const DefaultWindowToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final entry = context.watch<WindowEntry>();
    final callbacks = TitlebarDragCallbacks.of(context);

    final entriesByFocus = context.read<WindowHierarchyState>().entriesByFocus;
    final isFocused
        = entriesByFocus.isNotEmpty && entriesByFocus.last == entry;

    void onMaximizeOrRestore() {
      context
          .read<WindowHierarchyState>()
          .requestWindowFocus(entry);
      entry.toggleMaximize();
      if (!entry.maximized) {
        entry.windowDock = WindowDock.normal;
      }
    }

    return HeaderBar(
      title: entry.title,
      isActive: isFocused,
      isDraggable: true,
      isMinimizable: true,
      isMaximizable: !entry.maximized,
      isRestorable: entry.maximized,
      isClosable: true,
      onDragStart: (_, p0) => callbacks?.onDragStart(p0),
      onDrag: (_, p0) => callbacks?.onDrag(p0),
      onDragEnd: (_, p0) => callbacks?.onDragEnd(p0),
      onMinimize: (_) {
        final hierarchy =
            context.read<WindowHierarchyState>();
        final windows = hierarchy.entriesByFocus;
        entry.minimized = true;
        if (windows.length > 1) {
          hierarchy.requestWindowFocus(
              windows[windows.length - 2]);
        }
      },
      onMaximize: (_) => onMaximizeOrRestore(),
      onRestore: (_) => onMaximizeOrRestore(),
      onClose: (_) {
        context
            .read<WindowHierarchyState>()
            .popWindowEntry(entry);
      },
    );
  }
}