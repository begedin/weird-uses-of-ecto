defmodule WUE.Pictures.Transpose do
  @moduledoc """
  Use-case module.

  Does a naive "transpose" operation depending on the type of shape given to it.

  Not necesarily accurate, just exists to be an example of a relatively complex
  operation being done on an item.
  """
  alias WUE.Pictures

  @doc false
  @spec call(Pictures.shape()) :: Pictures.shape()
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
