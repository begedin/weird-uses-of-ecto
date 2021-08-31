defmodule WUE.Pictures.PictureV2 do
  @moduledoc """
  Alternative approach to polymorphic embed, bot with pros as well as cons
  compared to a custom ecto type approach.

  In this approach, the field is defined as a plain map, so works with plain
  string (or atom) keys.

  However, internally, we use the same shape embedded schema structs and
  changesets to cast and eventually save the data.

  The advantage is, other than the plain error message, we are also able to
  store additionall information onto the validation error, inside an `:error`
  key of the validation error options field.

  We can then use this additional information to render more complex error
  messages to the frontend, using `Ecto.Changeset.traverse_errors`.

  ## Examples

    iex>
    ...>  %{shape: %{type: "box", x: "a", w: "b"}}
    ...>  |> WUE.Pictures.PictureV2.changeset()
    ...>  |> WUE.Pictures.PictureV2.traverse_errors()

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
    field(:shape, :map, read_after_writes: true)
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
        Changeset.add_error(changeset, :shape, "is invalid", errors: errors)

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

  @doc """
  Error traversal function specifically designed to convert the extra :errors
  key which is attached as an option to the shape field error of the PictureV2
  changeset, into a typical map used to render errors via an API response.

  The error view should match on the struct of the changeset.data field and
  call this function if the struct is `WUE.Pictures.PictureV2`.
  """
  @spec traverse_errors(Changeset.t()) :: map
  def traverse_errors(%Changeset{} = changeset) do
    traversed =
      Changeset.traverse_errors(changeset, fn
        {_msg, errors: errors} ->
          errors |> Enum.map(&do_traverse_errors/1) |> Map.new()

        {msg, opts} ->
          WUEWeb.ErrorHelpers.translate_error({msg, opts})
      end)

    case Map.get(traversed, :shape) do
      nil -> traversed
      [shape_errors] -> Map.put(traversed, :shape, shape_errors)
    end
  end

  @spec do_traverse_errors(
          {atom, map}
          | {atom, list}
          | map
          | {String.t(), Keyword.t()}
        ) ::
          {atom, map}
          | {atom, list}
          | map
          | {String.t(), Keyword.t()}
  defp do_traverse_errors({field, value})
       when is_atom(field) and is_map(value) do
    {field, value |> Enum.map(&do_traverse_errors/1) |> Map.new()}
  end

  defp do_traverse_errors({field, value})
       when is_atom(field) and is_list(value) do
    {field, Enum.map(value, &do_traverse_errors/1)}
  end

  defp do_traverse_errors(%{} = errors), do: errors

  defp do_traverse_errors({msg, opts}) when is_binary(msg) and is_list(opts) do
    WUEWeb.ErrorHelpers.translate_error({msg, opts})
  end
end
