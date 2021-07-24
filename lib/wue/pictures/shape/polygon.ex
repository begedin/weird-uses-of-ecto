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

  @primary_key false
  embedded_schema do
    embeds_many(:path, Shape.Point)
  end

  def cast(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> resolve()
  end

  @keys [:path]

  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [])
    |> Changeset.cast_embed(:path, required: true)
    |> Changeset.validate_required(@keys)
  end

  defp resolve(%Changeset{valid?: false, errors: [path: {"can't be blank", _}]}) do
    {:error, message: "polygon requires a path, which is a list of points"}
  end

  defp resolve(%Changeset{valid?: false, errors: []} = changeset) do
    errors =
      changeset.changes.path
      |> Enum.with_index()
      |> Enum.map(fn
        {%{valid?: true}, index} ->
          "Point #{index} is valid."

        {%{valid?: false} = point_changeset, index} ->
          Enum.map(point_changeset.errors, fn {key, {message, _}} ->
            "Point #{index} is invalid, #{key} #{message}."
          end)
      end)
      |> List.flatten()

    message = Enum.join(["Polygon contains invalid points." | errors], " ")
    {:error, message: message}
  end

  defp resolve(%Changeset{valid?: true} = changeset) do
    data =
      changeset
      |> Changeset.apply_changes()
      |> dump()

    {:ok, data}
  end

  def dump(%__MODULE__{path: path}) do
    %{path: Enum.map(path, &Shape.Point.dump/1)}
  end
end
