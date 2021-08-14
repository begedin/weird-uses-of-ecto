defmodule WUE.Pictures.Transpose do
  alias WUE.Pictures

  def call(%Pictures.Shape.Box{} = box) do
    %Pictures.Shape.Box{
      x: box.y,
      y: box.x,
      w: box.h,
      h: box.w
    }
  end

  def call(%Pictures.Shape.Line{} = line) do
    %Pictures.Shape.Line{
      a: call(line.a),
      b: call(line.b)
    }
  end

  def call(%Pictures.Shape.Point{} = point) do
    %Pictures.Shape.Point{
      x: point.y,
      y: point.x
    }
  end

  def call(%Pictures.Shape.Polygon{} = polygon) do
    %Pictures.Shape.Polygon{path: Enum.map(polygon.path, &call/1)}
  end
end
