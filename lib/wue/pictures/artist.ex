defmodule WUE.Pictures.Artist do
  @moduledoc """
  Schema module representing an artist of a picture. A picture can optionally
  belong to a single artist.

  An artist can have multiple pictures.

  We need a basic association to better depict the advante certain uses of ecto
  can provide.
  """
  use Ecto.Schema

  alias Ecto.Changeset
  alias WUE.Pictures

  @type t :: %__MODULE__{}

  schema "artists" do
    field(:name, :string, null: false)
    field(:country, :string, null: false)

    has_many(:pictures, Pictures.Picture)
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
    |> Changeset.cast(params, [:country, :name])
    |> Changeset.validate_required([:country, :name])
  end
end
