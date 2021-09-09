defmodule WUE.Pictures.Shape.Point do
  @moduledoc """
  Embedded schema for a point shape, defined by an x, y

  Used as part of the `WUE.Pictures.Shape` type, to validate and store data
  into the `:shape` field of a `WUE.Pictures.Picture`.

  Also used as sub-data in the `WUE.Pictures.Shape.Polygon` field
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures.Shape

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:x, :y]}
  @primary_key false
  embedded_schema do
    field(:x, :integer, null: false)
    field(:y, :integer, null: false)
  end

  @spec cast(map) :: {:ok, t} | {:error, message: String.t()}
  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:x, :y]

  @doc false
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, @keys)
    |> Changeset.validate_required(@keys)
  end

  @spec resolve(Changeset.t()) :: {:ok, t} | {:error, message: String.t()}
  defp resolve(%Changeset{valid?: false} = changeset) do
    extra_errors = Shape.Utils.collect_errors_into_map(changeset)
    {:error, extra_errors: extra_errors, message: "is invalid"}
  end

  defp resolve(%Changeset{valid?: true} = changeset) do
    {:ok, Changeset.apply_changes(changeset)}
  end

  @spec dump(t) :: map
  def dump(%__MODULE__{x: x, y: y}) do
    %{"x" => x, "y" => y, "type" => "point"}
  end

  @spec load(map) :: t
  def load(%{"x" => x, "y" => y}) do
    %__MODULE__{x: x, y: y}
  end
end
