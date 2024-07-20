//  jdwm_flutter, The Flutter UI library for the JDWM window manager.
//  Copyright (C) 2024  The JappeOS team.
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

part of jdwm_flutter;

class WindowWidget extends StatefulWidget {
  final WindowContent content;

  final BackgroundMode windowBackgroundMode;
  final bool windowIsFocused;
  final bool windowIsResizable;
  final Vector2 windowPos;
  final Vector2 windowMinSize;
  final Vector2 windowSize;
  final WindowState windowState;

  final Function(bool newVal) focusCallback;
  final Function(Vector2 newVal) resizeCallback;
  final Function(Vector2 newVal) posCallback;
  final Function(WindowState newVal) stateCallback;
  final Function() closeCallback;

  const WindowWidget(
      {Key? key,
      required this.content,
      required this.windowBackgroundMode,
      required this.windowIsFocused,
      required this.windowIsResizable,
      required this.windowPos,
      required this.windowMinSize,
      required this.windowSize,
      required this.windowState,
      required this.focusCallback,
      required this.resizeCallback,
      required this.posCallback,
      required this.stateCallback,
      required this.closeCallback})
      : super(key: key);

  @override
  _WindowWidgetState createState() => _WindowWidgetState();
}

class _WindowWidgetState extends State<WindowWidget> {
  static const kResizeAreaThickness = 5.0;

  Vector2 oldWindowPos = Vector2.zero();
  Vector2 oldWindowSize = Vector2.zero();
  Offset? _dragOffset;

  @override
  Widget build(BuildContext context) {
    WindowHeader header = WindowHeader(
        maximizeButton: widget.windowIsResizable,
        windowPos: widget.windowPos,
        windowState: widget.windowState,
        focusCallback: widget.focusCallback,
        posCallback: widget.posCallback,
        stateCallback: widget.stateCallback,
        closeCallback: widget.closeCallback);

    // The window base widget, anything can be added on top later on
    Widget base(Widget child) {
      if (widget.windowBackgroundMode == BackgroundMode.blurredTransp) {
        // Blurred window background
        return AdvancedContainer(
          background: AdvancedContainerBackground.transparentBackground,
          borderRadius: BPPresets.medium,
          borderStyle: AdvancedContainerBorder.double,
          blur: true,
          child: child,
        );
      } else {
        // Solid window background
        return AdvancedContainer(
          background: AdvancedContainerBackground.solidBackground,
          borderRadius: BPPresets.medium,
          borderStyle: AdvancedContainerBorder.double,
          child: child,
        );
      }
    }

    List<Widget> resizeAreas = !widget.windowIsResizable || widget.windowState != WindowState.normal
        ? []
        : [
            // Right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x + _dragOffset!.dx,
                    widget.windowSize.y,
                  ));
                },
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  opaque: true,
                  child: Container(
                    width: kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // Left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);
                  bool sizeXIsMin = widget.windowMinSize.x >= oldWindowSize.x - _dragOffset!.dx;

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x - _dragOffset!.dx,
                    widget.windowSize.y,
                  ));

                  widget.posCallback(Vector2(
                    oldWindowPos.x + (!sizeXIsMin ? _dragOffset!.dx : 0),
                    widget.windowPos.y,
                  ));
                },
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  opaque: true,
                  child: Container(
                    width: kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // Top
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);
                  bool sizeYIsMin = widget.windowMinSize.y >= oldWindowSize.y - _dragOffset!.dy;

                  widget.resizeCallback(Vector2(
                    widget.windowSize.x,
                    oldWindowSize.y - _dragOffset!.dy,
                  ));

                  widget.posCallback(Vector2(
                    widget.windowPos.x,
                    oldWindowPos.y + (!sizeYIsMin ? _dragOffset!.dy : 0),
                  ));
                },
                MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  opaque: true,
                  child: Container(
                    height: kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // Bottom
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);

                  widget.resizeCallback(Vector2(
                    widget.windowSize.x,
                    oldWindowSize.y + _dragOffset!.dy,
                  ));
                },
                MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  opaque: true,
                  child: Container(
                    height: kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // BottomRight
            Positioned(
              bottom: 0,
              right: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x + _dragOffset!.dx,
                    oldWindowSize.y + _dragOffset!.dy,
                  ));
                },
                const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  opaque: true,
                  child: SizedBox(
                    height: 1.5 * kResizeAreaThickness,
                    width: 1.5 * kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // BottomLeft
            Positioned(
              bottom: 0,
              left: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);
                  bool sizeXIsMin = widget.windowMinSize.x >= oldWindowSize.x - _dragOffset!.dx;

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x - _dragOffset!.dx,
                    oldWindowSize.y + _dragOffset!.dy,
                  ));

                  widget.posCallback(Vector2(
                    oldWindowPos.x + (!sizeXIsMin ? _dragOffset!.dx : 0),
                    widget.windowPos.y,
                  ));
                },
                const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  opaque: true,
                  child: SizedBox(
                    height: 1.5 * kResizeAreaThickness,
                    width: 1.5 * kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // TopRight
            Positioned(
              top: 0,
              right: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);
                  bool sizeYIsMin = widget.windowMinSize.y >= oldWindowSize.y - _dragOffset!.dy;

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x + _dragOffset!.dx,
                    oldWindowSize.y - _dragOffset!.dy,
                  ));

                  widget.posCallback(Vector2(
                    widget.windowPos.x,
                    oldWindowPos.y + (!sizeYIsMin ? _dragOffset!.dy : 0),
                  ));
                },
                const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  opaque: true,
                  child: SizedBox(
                    height: 1.5 * kResizeAreaThickness,
                    width: 1.5 * kResizeAreaThickness,
                  ),
                ),
              ),
            ),
            // TopLeft
            Positioned(
              left: 0,
              top: 0,
              child: _resizeArea(
                (p) {
                  _dragOffset = Offset(_dragOffset!.dx + p.delta.dx, _dragOffset!.dy + p.delta.dy);
                  bool sizeXIsMin = widget.windowMinSize.x >= oldWindowSize.x - _dragOffset!.dx;
                  bool sizeYIsMin = widget.windowMinSize.y >= oldWindowSize.y - _dragOffset!.dy;

                  widget.resizeCallback(Vector2(
                    oldWindowSize.x - _dragOffset!.dx,
                    oldWindowSize.y - _dragOffset!.dy,
                  ));

                  widget.posCallback(Vector2(
                    oldWindowPos.x + (!sizeXIsMin ? _dragOffset!.dx : 0),
                    oldWindowPos.y + (!sizeYIsMin ? _dragOffset!.dy : 0),
                  ));
                },
                const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  opaque: true,
                  child: SizedBox(
                    height: 1.5 * kResizeAreaThickness,
                    width: 1.5 * kResizeAreaThickness,
                  ),
                ),
              ),
            ),
          ];

    return Stack(
      children: [
        Positioned(
          top: widget.windowState == WindowState.normal ? kResizeAreaThickness : 0,
          left: widget.windowState == WindowState.normal ? kResizeAreaThickness : 0,
          bottom: widget.windowState == WindowState.normal ? kResizeAreaThickness : 0,
          right: widget.windowState == WindowState.normal ? kResizeAreaThickness : 0,
          child: base(
            Column(
              children: [
                header,
                Expanded(child: widget.content),
              ],
            ),
          ),
        ),
        ...resizeAreas
      ],
    );
  }

  Widget _resizeArea(void Function(PointerMoveEvent) onPointerMove, Widget child) {
    return Listener(
      onPointerMove: onPointerMove,
      onPointerDown: (p) {
        _dragOffset = Offset.zero;
        oldWindowSize = widget.windowSize;
        oldWindowPos = widget.windowPos;
      },
      onPointerUp: (p) {
        _dragOffset = null;
        oldWindowSize = Vector2.zero();
        oldWindowPos = Vector2.zero();
      },
      child: child,
    );
  }
}