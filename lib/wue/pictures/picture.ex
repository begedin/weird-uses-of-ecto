defmodule WUE.Pictures.Picture do
  @moduledoc """
  Example of using ecto to achieve a polymorphic embed

  The picture is a record with just one field, `:shape` which is defined using
  a custom ecto type.

  In the database, this field is stored as one of the following

  ```
  %{"type" => "point", "x" => integer, "y" => integer}

  %{
    "type" => "line",
    "a" => %{"x" => integer, "y" => integer},
    "b" => %{"x" => integer, "y" => integer}
  }

  %{
    "type" => "box",
    "x" => integer, "y" => integer,
    "w" => integer, "h" => integer
  }

  %{
    "type" => "polygon",
    "path" => list(%{"x" => integer, "y" => integer})
  }
  ```


  When the record is loaded, however, the field exists as a clearly typed struct.

  ```
  %Pictures.Shape.Point{x: integer, y: integer}

  %Pictures.Shape.Line{
    a: %Pictures.Shape.Point{x: integer, y: integer},
    b: %Pictures.Shape.Point{x: integer, y: integer}
  }

  %Pictures.Shape.Box{x: integer, y: integer, w: integer, h: integer}

  %Pictures.Shape.Polygon{
    path: list(%Pictures.Shape.Point{x: integer, y: integer})
  }
  ```

  ## Note on `read_after_writes: true`

  This is needed to ensure the record is reloaded as a struct upon insert or
  update. Without this option, after those actions execute, the shape field will
  stay as the original map, with a type field.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:shape]}
  schema "pictures" do
    field(:name, :string, null: true)
    field(:shape, Pictures.Shape, read_after_writes: true)

    belongs_to(:artist, Pictures.Artist)
    many_to_many(:albums, Pictures.Album, join_through: "pictures_albums")
  end

  @doc """
  Default changeset used to insert a new picture record
  """
  @spec changeset(map) :: Changeset.t()
  def changeset(%{} = params) do
    changeset(%__MODULE__{artist: nil}, params)
  end

  @doc """
  Default changeset used to update an existing picture record
  """
  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [:name, :shape])
    |> Changeset.validate_required([:shape])
  end
end
