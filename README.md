# Resizeable Shape

A Delphi component written in Pascal offering resizeable shapes and also a container where they can be placed and created.

## TResizeShape

Inherits from TGraphicControl, can draw resizing anchors and resize itself (<code>TResizeType = (rtTopLeft, rtTopMiddle, rtTopRight, rtMiddleLeft, rtCenter, rtMiddleRight, rtBottomLeft, rtBottomMiddle, rtBottomRight}</code>).

## TResizeShapeControl

This is a Delphi component, it inherits from TScrollBox and can receive and manage an infinite amount of TResizeShape on itself, store/restore them from a file, it also supports a background image and has a size ratio property which works like a zoom.
If the property AutoCreate is true, the user will be able to create shapes at will.
The component was created to create and manage components like buttons, switches, tables, [...] over an image.
