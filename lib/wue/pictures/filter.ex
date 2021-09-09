defmodule WUE.Pictures.Filter do
  @moduledoc """
  Defines the structure of a filter for shapes in the database.

  This is used as part of a prevalidation step for the shapes index endpoint,
  or any other potential endpoint which might involve batch listing or processing.

  The general idea is to consolidate the filter logic in one place.
  """

  use Ecto.Schema

  import Ecto.Query, only: [join: 5, or_where: 3, subquery: 1, where: 3]
  import WUE.Pictures.QueryMacros, only: [maybe_join: 5]

  alias Ecto.Changeset
  alias WUE.Pictures

  @type t :: %__MODULE__{}

  defmodule Bounds do
    @moduledoc false

    use Ecto.Schema
    alias Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:min_x, :integer, null: false)
      field(:max_x, :integer, null: false)
      field(:min_y, :integer, null: false)
      field(:max_y, :integer, null: false)
    end

    def changeset(%__MODULE__{} = struct, %{} = params) do
      fields = __MODULE__.__schema__(:fields)

      struct
      |> Changeset.cast(params, fields)
      |> Changeset.validate_required(fields)
      |> sort_bounds()
    end

    defp sort_bounds(%Changeset{valid?: false} = changeset), do: changeset

    defp sort_bounds(%Changeset{} = changeset) do
      changeset
      |> sort(:min_y, :max_y)
      |> sort(:min_x, :max_x)
    end

    defp sort(%Changeset{} = changeset, field_1, field_2) do
      case {Changeset.get_field(changeset, field_1),
            Changeset.get_field(changeset, field_2)} do
        {val_1, val_2} when val_1 <= val_2 ->
          changeset

        {val_1, val_2} ->
          changeset
          |> Changeset.put_change(field_1, val_2)
          |> Changeset.put_change(field_2, val_1)
      end
    end
  end

  @primary_key false
  embedded_schema do
    field(:type, :string, null: true)
    field(:artist_name, {:array, :string}, null: false)
    field(:artist_country, {:array, :string}, null: false)
    embeds_one(:bounds, Bounds)

    field(:select_all, :boolean, null: false, default: false)
  end

  @doc """
  Defines a changeset for a filter strcuture which allows endpoints to define
  a batch of pictures on which an operation will run.

  The filter is defined as at least one, or more, supported keys. If it has no
  supported keys, it explicitly must define a `select_all: true`, to avoid
  accidentally running an operation on all pictures in the database.
  """
  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> Changeset.cast(params, [
      :type,
      :select_all,
      :artist_name,
      :artist_country
    ])
    |> Changeset.cast_embed(:bounds)
    |> validate_explicit_all()
  end

  @spec validate_explicit_all(Changeset.t()) :: Changeset.t()
  defp validate_explicit_all(%Changeset{} = changeset) do
    case Changeset.get_field(changeset, :select_all) do
      true -> changeset
      false -> require_any_filter_key(changeset)
    end
  end

  @spec require_any_filter_key(Changeset.t()) :: Changeset.t()
  defp require_any_filter_key(%Changeset{} = changeset) do
    fields =
      :fields
      |> __MODULE__.__schema__()
      |> List.delete(:select_all)

    if Enum.any?(fields, &(Changeset.get_field(changeset, &1) !== nil)) do
      changeset
    else
      Changeset.add_error(
        changeset,
        :select_all,
        "Filter requires at least one parameter, or explicitly setting 'select_all' to 'true'"
      )
    end
  end

  @doc """
  Applies a valid filter to a queryable, expanding the queryable with conditions
  which satisfy the filter.
  """
  @spec apply(Ecto.Queryable.t(), t) :: Ecto.Query.t()
  def apply(queryable, %__MODULE__{} = filter) do
    filter
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.reduce(queryable, fn {k, v}, acc -> apply_filter(k, v, acc) end)
  end

  @spec apply_filter(atom, term, Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp apply_filter(:select_all, _, queryable), do: queryable

  defp apply_filter(:type, type, queryable) do
    where(queryable, [q], q.shape["type"] == ^type)
  end

  defp apply_filter(:artist_name, artist_names, queryable)
       when is_list(artist_names) do
    queryable
    |> maybe_join(
      :inner,
      [picture],
      artist in assoc(picture, :artist),
      as: :artist
    )
    |> where([artist: artist], artist.name in ^artist_names)
  end

  defp apply_filter(:artist_country, artist_countries, queryable)
       when is_list(artist_countries) do
    queryable
    |> maybe_join(
      :inner,
      [picture],
      artist in assoc(picture, :artist),
      as: :artist
    )
    |> where([artist: artist], artist.country in ^artist_countries)
  end

  defp apply_filter(:bounds, %Bounds{} = within, queryable) do
    %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y} = within

    points = point_query(min_x, min_y, max_x, max_y)
    lines = line_query(min_x, min_y, max_x, max_y)
    boxes = box_query(min_x, min_y, max_x, max_y)

    queryable
    |> join(:left, [q], matched in ^subquery(points),
      as: :point,
      on: q.id == matched.id
    )
    |> join(:left, [q], matched in ^subquery(lines),
      as: :line,
      on: q.id == matched.id
    )
    |> join(:left, [q], matched in ^subquery(boxes),
      as: :box,
      on: q.id == matched.id
    )
    |> where(
      [point: point, line: line, box: box],
      not (is_nil(box) and is_nil(line) and is_nil(point))
    )
  end

  @spec point_query(integer, integer, integer, integer) :: Ecto.Query.t()
  defp point_query(min_x, min_y, max_x, max_y) do
    Pictures.Picture
    |> where([q], fragment("(?->>'type')::varchar", q.shape) == "point")
    |> where([q], fragment("(?->>'x')::int", q.shape) >= ^min_x)
    |> where([q], fragment("(?->>'x')::int", q.shape) <= ^max_x)
    |> where([q], fragment("(?->>'y')::int", q.shape) >= ^min_y)
    |> where([q], fragment("(?->>'y')::int", q.shape) <= ^max_y)
  end

  @spec line_query(integer, integer, integer, integer) :: Ecto.Query.t()
  defp line_query(min_x, min_y, max_x, max_y) do
    Pictures.Picture
    |> where([q], fragment("(?->>'type')::varchar", q.shape) == "line")
    |> where(
      [q],
      fragment("(?->'a'->>'x')::int", q.shape) >= ^min_x and
        fragment("(?->'a'->>'x')::int", q.shape) <= ^max_x and
        fragment("(?->'a'->>'y')::int", q.shape) >= ^min_y and
        fragment("(?->'a'->>'y')::int", q.shape) <= ^max_y
    )
    |> or_where(
      [q],
      fragment("(?->'b'->>'x')::int", q.shape) >= ^min_x and
        fragment("(?->'b'->>'x')::int", q.shape) <= ^max_x and
        fragment("(?->'b'->>'y')::int", q.shape) >= ^min_y and
        fragment("(?->'b'->>'y')::int", q.shape) <= ^max_y
    )
  end

  @spec box_query(integer, integer, integer, integer) :: Ecto.Query.t()
  defp box_query(min_x, min_y, max_x, max_y) do
    Pictures.Picture
    |> where(
      [q],
      fragment("(?->>'type')::varchar", q.shape) == "box"
    )
    |> where(
      [q],
      not (fragment("(?->>'x')::int", q.shape) >= ^max_x or
             fragment("(?->>'x')::int + (?->>'w')::int", q.shape, q.shape) <=
               ^min_x or
             (fragment("(?->>'y')::int", q.shape) >= ^max_y and
                fragment("(?->>'y')::int + (?->>'h')::int", q.shape, q.shape) <=
                  ^min_y))
    )
  end
end
