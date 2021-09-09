defmodule WUE.Pictures.Picture do
  @moduledoc """
  Example of using a custom ecto type to achieve a polymorphic embed

  The picture is a record with just one field, `:shape` which is defined using
  a custom ecto type.

  This approach allows us to

  - load the data from the db into one of several potentional structs, depending
    on the polymorphic type
  - automatically cast the data s the correct type by simply relying on regular
    casting infrastructure
  - render custom, deeply nested errors, for individual fields within the
    polymorphic embed

  On the surface, this seems like the superior approach to ne defined in
  `WUE.Pictures.PictureV2`. If the opposite turns out to be true, this
  documentation will be updated.

  The only disadvantage seems to be the need for `:read_after_writes` explained
  in it's own section here. Even if we were to remove that feature, we would
  still end up with something that is functionally equivalent to the v2
  approach.

  ## Database format

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

  # Runtime format

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

  ## Examples

    iex>
    ...>  %{shape: %{type: "box", x: "a", w: "b"}}
    ...>  |> WUE.Pictures.Picture.changeset()
    ...>  |> WUEWeb.ErrorView.traverse_errors()

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
