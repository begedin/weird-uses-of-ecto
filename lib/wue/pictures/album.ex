defmodule WUE.Pictures.Album do
  @moduledoc """
  Represents a collection of pictures.

  An album could contain multiple pictures and a picture could be in multiple
  albums.

  An additional, soft-enforced rule is that if a picture is named, that name
  could only ocurr in a given album once.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias WUE.Pictures

  @type t :: %__MODULE__{}

  schema "albums" do
    field(:name, :string, null: false)

    many_to_many(:pictures, Pictures.Picture, join_through: "pictures_albums")
  end

  @spec changeset(map) :: Changeset.t()
  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [:name])
    |> Changeset.validate_required(:name)
    |> Changeset.unique_constraint(:name)
  end
end
