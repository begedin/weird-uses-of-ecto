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
  @spec cast(map) :: {:ok, Pictures.shape()} | {:error, Keyword.t()}
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
  def load(%{"type" => type} = data) when type in @shapes do
    module = schema_module(type)
    {:ok, module.load(data)}
  end

  @spec schema_module(String.t()) :: module
  defp schema_module("box"), do: Shape.Box
  defp schema_module("line"), do: Shape.Line
  defp schema_module("point"), do: Shape.Point
  defp schema_module("polygon"), do: Shape.Polygon
end
