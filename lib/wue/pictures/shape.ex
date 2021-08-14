defmodule WUE.Pictures.Shape do
  @moduledoc """
  Defines a type for a field which could be one of several different shapes

  Depending on an indentifier field within the params, it will cast the
  remaining params using one of several different embedded schemas.

  # Advantages of this method

  - the shape type is easily customizable, and simple to implement
  - adding more shapes is as straight forward as a new `cast/1` clause

  # Disadvantages of this method

  - There can only be a single error on the shape field
  - It's not possible to nest errors

  # Conclusion

  - This approach is good for a technically oriented API, but not great if we
    need to support user-friendly, per subfield errors out of the box
  - It's always possible to "decide" the error field is actually an encounted,
    more complex error map, or list, etc.
  """
  use Ecto.Type
  alias WUE.Pictures.Shape

  @shapes ["box", "line", "point", "polygon"]

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(%{"type" => type} = data) when type in @shapes do
    do_cast(data, type)
  end

  def cast(%{type: type} = data) when type in @shapes do
    do_cast(data, type)
  end

  def cast(%{}) do
    {:error,
     message:
       "requires a `:type` field which is one of #{Enum.join(@shapes, ", ")}"}
  end

  def cast(_other) do
    {:error, message: "must be a map"}
  end

  defp do_cast(data, type) do
    module = schema_module(type)

    module
    |> Kernel.apply(:cast, [data])
    |> put_type(type)
  end

  defp schema_module("box"), do: Shape.Box
  defp schema_module("line"), do: Shape.Line
  defp schema_module("point"), do: Shape.Point
  defp schema_module("polygon"), do: Shape.Polygon

  @impl Ecto.Type
  def dump(%module{} = data) do
    module.dump(data)
  end

  def dump(%{type: _} = data) when is_map(data) do
    {:ok, data}

    data =
      data
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, data}
  end

  @impl Ecto.Type
  def load(data) when is_struct(data) do
    {:ok, data}
  end

  def load(%{"type" => "point"} = data) do
    {:ok, Shape.Point.load(data)}
  end

  def load(%{"type" => "line"} = data) do
    {:ok, Shape.Line.load(data)}
  end

  def load(%{"type" => "box"} = data) do
    {:ok, Shape.Box.load(data)}
  end

  def load(%{"type" => "polygon"} = data) do
    {:ok, Shape.Polygon.load(data)}
  end

  def load(%{type: "point"} = data) do
    {:ok, data |> Jason.encode!() |> Jason.decode!() |> Shape.Point.load()}
  end

  def load(%{type: "line"} = data) do
    {:ok, data |> Jason.encode!() |> Jason.decode!() |> Shape.Line.load()}
  end

  def load(%{type: "box"} = data) do
    {:ok, data |> Jason.encode!() |> Jason.decode!() |> Shape.Box.load()}
  end

  def load(%{type: "polygon"} = data) do
    {:ok, data |> Jason.encode!() |> Jason.decode!() |> Shape.Polygon.load()}
  end

  defp put_type({:ok, %{} = data}, type), do: {:ok, Map.put(data, :type, type)}
  defp put_type({:error, _} = error, _type), do: error
end
