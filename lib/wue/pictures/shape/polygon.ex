defmodule WUE.Pictures.Shape.Polygon do
  @moduledoc """
  Embedded schema for a polygon shape, defined by a path, which is a list of x,y
  points.

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures.Shape

  @type t :: %__MODULE__{}

  @primary_key false
  @derive {Jason.Encoder, only: [:path]}
  embedded_schema do
    embeds_many(:path, Shape.Point)
  end

  @spec cast(map) :: {:ok, t} | {:error, message: String.t()}
  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:path]

  @doc false
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [])
    |> Changeset.cast_embed(:path, required: true)
    |> Changeset.validate_required(@keys)
  end

  @spec resolve(Changeset.t()) :: {:ok, t} | {:error, message: String.t()}
  defp resolve(%Changeset{valid?: false} = changeset) do
    extra_errors = Shape.traverse_errors(changeset)
    {:error, extra_errors: extra_errors, message: "is invalid"}
  end

  defp resolve(%Changeset{valid?: true} = changeset) do
    {:ok, Changeset.apply_changes(changeset)}
  end

  @spec dump(t) :: map
  def dump(%__MODULE__{path: path}) do
    %{
      "path" =>
        Enum.map(path, &(&1 |> Shape.Point.dump() |> Map.delete("type"))),
      "type" => "polygon"
    }
  end

  @spec load(map) :: t
  def load(%{"path" => path}) do
    %__MODULE__{path: Enum.map(path, &Shape.Point.load/1)}
  end
end
