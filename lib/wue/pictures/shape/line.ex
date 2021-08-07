defmodule WUE.Pictures.Shape.Line do
  @moduledoc """
  Embedded schema for a line shape, defined by two points

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures.Shape

  @primary_key false
  embedded_schema do
    embeds_one(:a, Shape.Point)
    embeds_one(:b, Shape.Point)
  end

  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [])
    |> Changeset.validate_required([])
    |> Changeset.cast_embed(:a, required: true)
    |> Changeset.cast_embed(:b, required: true)
  end

  def resolve(%Changeset{valid?: false}) do
    {:error,
     message: "line requires points a and b, each with an x and y coordinate"}
  end

  def resolve(%Changeset{valid?: true} = changeset) do
    data =
      changeset
      |> Changeset.apply_changes()
      |> dump()

    {:ok, data}
  end

  def dump(%__MODULE__{a: a, b: b}) do
    %{a: Shape.Point.dump(a), b: Shape.Point.dump(b)}
  end
end
