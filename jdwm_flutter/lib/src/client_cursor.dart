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

sealed class ClientCursor {
  static Image get(SystemMouseCursor cursor) {
    String? asset;
    switch (cursor) {
      case SystemMouseCursors.grabbing:
        asset = 'assets/cursor/grabbing.png';
        break;
      case SystemMouseCursors.resizeUpDown:
        asset = 'assets/cursor/sb_v_double_arrow.png';
        break;
      case SystemMouseCursors.resizeLeftRight:
        asset = 'assets/cursor/sb_h_double_arrow.png';
        break;
      case SystemMouseCursors.resizeUpLeftDownRight:
        asset = 'assets/cursor/bd_double_arrow.png';
        break;
      case SystemMouseCursors.resizeUpRightDownLeft:
        asset = 'assets/cursor/fd_double_arrow.png';
        break;
      default:
        asset = null;
    }

    if (asset == null) {
      return Image.memory(Uint8List(0));
    }

    return Image.asset(
      asset,
      package: 'jdwm_flutter',
      width: 24,
      height: 24,
    );
  }
}