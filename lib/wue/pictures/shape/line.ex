defmodule WUE.Pictures.Shape.Line do
  @moduledoc """
  Embedded schema for a line shape, defined by two points

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures.Shape

  @type t :: %__MODULE__{}

  @primary_key false
  @derive {Jason.Encoder, only: [:a, :b]}
  embedded_schema do
    embeds_one(:a, Shape.Point)
    embeds_one(:b, Shape.Point)
  end

  @spec cast(map) :: {:ok, t} | {:error, message: String.t()}
  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @doc false
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [])
    |> Changeset.validate_required([])
    |> Changeset.cast_embed(:a, required: true)
    |> Changeset.cast_embed(:b, required: true)
  end

  @spec resolve(Changeset.t()) :: {:ok, t} | {:error, message: String.t()}
  def resolve(%Changeset{valid?: false} = changeset) do
    extra_errors = Shape.traverse_errors(changeset)
    {:error, extra_errors: extra_errors, message: "is invalid"}
  end

  def resolve(%Changeset{valid?: true} = changeset) do
    {:ok, Changeset.apply_changes(changeset)}
  end

  @spec dump(t) :: map
  def dump(%__MODULE__{a: a, b: b}) do
    %{
      "a" => a |> Shape.Point.dump() |> Map.delete("type"),
      "b" => b |> Shape.Point.dump() |> Map.delete("type"),
      "type" => "line"
    }
  end

  @spec load(map) :: t
  def load(%{"a" => a, "b" => b}) do
    %__MODULE__{a: Shape.Point.load(a), b: Shape.Point.load(b)}
  end
end
