defmodule WUE.Pictures.Shape.Point do
  @moduledoc """
  Embedded schema for a point shape, defined by an x, y

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.

  Also used as sub-data in the `WUE.Pictures.Shape.Polygon` field
  """

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:x, :integer, null: false)
    field(:y, :integer, null: false)
  end

  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:x, :y]

  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, @keys)
    |> Changeset.validate_required(@keys)
  end

  defp resolve(%Changeset{valid?: false}) do
    {:error,
     message: "point requires x and y fields, both of which are integers"}
  end

  defp resolve(%Changeset{valid?: true} = changeset) do
    data =
      changeset
      |> Changeset.apply_changes()
      |> Map.take(@keys)

    {:ok, data}
  end

  def dump(%__MODULE__{x: x, y: y}) do
    %{x: x, y: y}
  end
end
