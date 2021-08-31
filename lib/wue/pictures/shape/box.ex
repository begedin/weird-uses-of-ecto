defmodule WUE.Pictures.Shape.Box do
  @moduledoc """
  Embedded schema for a box shape, defined by an x, y, width and height

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.
  """

  use Ecto.Schema
  alias Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  @derive {Jason.Encoder, only: [:x, :y, :w, :h]}
  embedded_schema do
    field(:x, :integer, null: false)
    field(:y, :integer, null: false)
    field(:w, :integer, null: false)
    field(:h, :integer, null: false)
  end

  @spec cast(map) :: {:ok, t} | {:error, message: String.t()}
  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:x, :y, :w, :h]

  @doc false
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, @keys)
    |> Changeset.validate_required(@keys)
  end

  @spec resolve(Changeset.t()) :: {:ok, t} | {:error, message: String.t()}
  def resolve(%Changeset{valid?: false}) do
    fields = Enum.join(@keys, ", ")

    {:error,
     message: "box requires the fields #{fields}, which are all integers"}
  end

  def resolve(%Changeset{valid?: true} = changeset) do
    {:ok, Changeset.apply_changes(changeset)}
  end

  @spec dump(t) :: map
  def dump(%__MODULE__{x: x, y: y, w: w, h: h}) do
    %{"x" => x, "y" => y, "w" => w, "h" => h, "type" => "box"}
  end

  @spec load(map) :: t
  def load(%{"x" => x, "y" => y, "w" => w, "h" => h}) do
    %__MODULE__{x: x, y: y, w: w, h: h}
  end
end
