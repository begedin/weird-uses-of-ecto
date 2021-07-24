defmodule WUE.Pictures.Shape.Box do
  @moduledoc """
  Embedded schema for a box shape, defined by an x, y, width and height

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.
  """

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:x, :integer, null: false)
    field(:y, :integer, null: false)
    field(:w, :integer, null: false)
    field(:h, :integer, null: false)
  end

  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:x, :y, :w, :h]

  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, @keys)
    |> Changeset.validate_required(@keys)
  end

  def resolve(%Changeset{valid?: false}) do
    fields = Enum.join(@keys, ", ")

    {:error,
     message: "box requires the fields #{fields}, which are all integers"}
  end

  def resolve(%Changeset{valid?: true} = changeset) do
    data =
      changeset
      |> Changeset.apply_changes()
      |> dump()

    {:ok, data}
  end

  def dump(%__MODULE__{x: x, y: y, w: w, h: h}) do
    %{x: x, y: y, w: w, h: h}
  end
end