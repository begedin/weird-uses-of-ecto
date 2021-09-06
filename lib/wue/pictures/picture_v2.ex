defmodule WUE.Pictures.PictureV2 do
  @moduledoc """
  Alternative approach to polymorphic embed. This one defines the shape field as
  a plain map, but uses the same embedded schemas as V1 to cast the params
  depending on the `"type"` field.

  Once the shape is cast and is deemed valid, it is converted back to a map,
  before being persisted to the database.

  Initially, this was thought to be the only way to achieve a custom, deeply
  nested error structure, but as it turns out, this is also possible with the
  custom  type approach defined in

  ```
  WUE.Pictures.Picture
  WUE.Pictures.Shape
  ```



  Thus, for most intents, the custom type approach seems superior.

  The only advantage here is that there is no need for `:read_after_writes`, but
  that also means that at runtime, the field is treated as a plain map.

  ## Examples

    iex>
    ...>  %{shape: %{type: "box", x: "a", w: "b"}}
    ...>  |> WUE.Pictures.PictureV2.changeset()
    ...>  |> WUE.Pictures.Shape.traverse_errors()

    %{
      shape: %{
        h: ["can't be blank"],
        w: ["is invalid"],
        x: ["is invalid"],
        y: ["can't be blank"]
      }
    }
  """
  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures.Shape

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:shape]}
  schema "pictures" do
    field(:name, :string, null: true)
    field(:shape, :map)
  end

  @doc """
  Default changeset used to insert a new picture record
  """
  @spec changeset(map) :: Changeset.t()
  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  @doc """
  Default changeset used to update an existing picture record
  """
  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [:name, :shape])
    |> cast_shape()
    |> Changeset.validate_required([:shape])
  end

  @spec cast_shape(Changeset.t()) :: Changeset.t()
  defp cast_shape(%Changeset{} = changeset) do
    case get_shape_changeset(changeset) do
      %Changeset{valid?: true} = shape_changeset ->
        Changeset.put_change(
          changeset,
          :shape,
          shape_changeset |> Changeset.apply_changes() |> dump()
        )

      %{valid?: false} = shape_changeset ->
        errors = collect_errors(shape_changeset)

        Changeset.add_error(changeset, :shape, "is invalid",
          extra_errors: errors
        )

      _ ->
        Changeset.add_error(changeset, :shape, "is invalid")
    end
  end

  @types ["box", "line", "point", "polygon"]

  @spec get_shape_changeset(Changeset.t()) :: Changeset.t() | nil
  defp get_shape_changeset(%Changeset{} = changeset) do
    case Changeset.get_field(changeset, :shape) do
      %{type: type} = data when type in @types -> do_cast_shape(data, type)
      %{"type" => type} = data when type in @types -> do_cast_shape(data, type)
      _ -> nil
    end
  end

  @spec do_cast_shape(map, String.t()) :: Changeset.t()
  defp do_cast_shape(%{} = data, "point") do
    Shape.Point.changeset(%Shape.Point{}, data)
  end

  defp do_cast_shape(%{} = data, "line") do
    Shape.Line.changeset(%Shape.Line{}, data)
  end

  defp do_cast_shape(%{} = data, "box") do
    Shape.Box.changeset(%Shape.Box{}, data)
  end

  defp do_cast_shape(%{} = data, "polygon") do
    Shape.Polygon.changeset(%Shape.Polygon{}, data)
  end

  @spec dump(Shape.t()) :: map
  defp dump(%Shape.Box{} = box), do: Shape.Box.dump(box)
  defp dump(%Shape.Line{} = line), do: Shape.Line.dump(line)
  defp dump(%Shape.Point{} = point), do: Shape.Point.dump(point)
  defp dump(%Shape.Polygon{} = polygon), do: Shape.Polygon.dump(polygon)

  @spec collect_errors(Changeset.t()) :: map
  defp collect_errors(%Changeset{} = shape_changeset) do
    Changeset.traverse_errors(shape_changeset, fn _c, _field, {msg, opts} ->
      {msg, opts}
    end)
  end
end
