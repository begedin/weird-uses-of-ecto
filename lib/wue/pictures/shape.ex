defmodule WUE.Pictures.Shape do
  @moduledoc """
  Defines a type for a field which could be one of several different shapes

  Depending on an indentifier field within the params, it will cast the
  remaining params using one of several different embedded schemas.

  It initially seemed only simple error messages were possible with this
  approach, but in the current form, we are able to do anythign we are doing
  in the approach described in `WUE.Pictures.PictureV2`.
  """
  use Ecto.Type

  alias Ecto.Changeset
  alias WUE.{Pictures, Pictures.Shape}

  @shapes ["box", "line", "point", "polygon"]

  @type t ::
          Shape.Box.t()
          | Shape.Line.t()
          | Shape.Point.t()
          | Shape.Polygon.t()

  @doc """
  The underlying base type of a polymorphic embed is a map, which, at the db
  level, is treated as a jsonb column.
  """
  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  @doc """
  Used when params are cast via Ecto.Changeset, or when arguments are passed in
  to Ecto.Query.

  For ease of use, we have an atom and string variant, so any of the two
  potential params shapes are supported.
  """
  @spec cast(map) :: {:ok, Pictures.shape()} | {:error, messsage: String.t()}
  def cast(%{"type" => type} = data) when type in @shapes do
    module = schema_module(type)
    module.cast(data)
  end

  def cast(%{type: _} = data) do
    data |> Jason.encode!() |> Jason.decode!() |> cast
  end

  def cast(%{}) do
    {:error,
     message:
       "requires a `:type` field which is one of #{Enum.join(@shapes, ", ")}"}
  end

  def cast(_other) do
    {:error, message: "must be a map"}
  end

  @spec schema_module(String.t()) :: module
  defp schema_module("box"), do: Shape.Box
  defp schema_module("line"), do: Shape.Line
  defp schema_module("point"), do: Shape.Point
  defp schema_module("polygon"), do: Shape.Polygon

  @doc """
  Used when the data needs to be validated against a native type, for example,
  when finally saving the struct to the db.
  """
  @impl Ecto.Type
  @spec dump(Pictures.shape()) :: {:ok, map}
  def dump(%module{} = data) do
    {:ok, module.dump(data)}
  end

  @doc """
  Used when the data from the db needs to be loaded into this type.

  This is effectively the reverse of `dump/1`
  """
  @impl Ecto.Type
  @spec load(map) :: {:ok, Pictures.shape()}
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

  @doc """
  Error traversal function specifically designed to convert the :extra_errors
  key of a `WUE.Pictures.{Picture,PictureV2}` changeset.

  The `WUEWeb.ErrorView` is in charge of calling this when necessary.

  This is what renders the :extra_errors conent in the same way one would
  regularly render errors on a normal ecto embed.
  """
  @spec traverse_errors(Changeset.t()) :: map
  def traverse_errors(%Changeset{} = changeset) do
    traversed =
      Changeset.traverse_errors(changeset, fn {msg, opts} ->
        if opts[:extra_errors] do
          opts[:extra_errors]
          |> Enum.map(&do_traverse_errors/1)
          |> Map.new()
        else
          WUEWeb.ErrorHelpers.translate_error({msg, opts})
        end
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
  defp do_traverse_errors(error) do
    case error do
      {field, %{} = value} when is_atom(field) ->
        {field, value |> Enum.map(&do_traverse_errors/1) |> Map.new()}

      {field, [msg]} when is_atom(field) and is_binary(msg) ->
        {field, [msg]}

      {field, value} when is_atom(field) and is_list(value) ->
        {field, Enum.map(value, &do_traverse_errors/1)}

      %{} = errors ->
        errors |> Enum.map(&do_traverse_errors/1) |> Map.new()

      {msg, opts} when is_binary(msg) ->
        WUEWeb.ErrorHelpers.translate_error({msg, opts})
    end
  end
end
