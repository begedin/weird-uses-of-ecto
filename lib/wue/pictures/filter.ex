defmodule WUE.Pictures.Filter do
  @moduledoc """
  Defines the structure of a filter for shapes in the database.

  This is used as part of a prevalidation step for the shapes index endpoint,
  or any other potential endpoint which might involve batch listing or processing.

  The general idea is to consolidate the filter logic in one place.
  """

  use Ecto.Schema
  import Ecto.Query, only: [join: 5, or_where: 3, subquery: 1, where: 3]
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
    field(:select_all, :boolean, null: false, default: false)

    embeds_one(:overlaps, Bounds)
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> Changeset.cast(params, [:type, :select_all])
    |> Changeset.cast_embed(:overlaps)
    |> validate_explicit_all()
  end

  defp validate_explicit_all(%Changeset{} = changeset) do
    case Changeset.get_field(changeset, :select_all) do
      true -> changeset
      false -> require_any_filter_key(changeset)
    end
  end

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

  defp apply_filter(:select_all, _, queryable), do: queryable

  defp apply_filter(:type, type, queryable) do
    where(queryable, [q], q.shape["type"] == ^type)
  end

  defp apply_filter(:overlaps, %Bounds{} = within, queryable) do
    %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y} = within

    points =
      Pictures.Picture
      |> where([q], fragment("(?->>'type')::varchar", q.shape) == "point")
      |> where([q], fragment("(?->>'x')::int", q.shape) >= ^min_x)
      |> where([q], fragment("(?->>'x')::int", q.shape) <= ^max_x)
      |> where([q], fragment("(?->>'y')::int", q.shape) >= ^min_y)
      |> where([q], fragment("(?->>'y')::int", q.shape) <= ^max_y)

    lines =
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

    boxes =
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

    # queryable
    # |> where(
    #   [q],
    #   (fragment("?::varchar", q.shape["type"]) == "point" and
    #      fragment("?::int", q.shape["x"]) >= ^left and
    #      fragment("?::int", q.shape["x"]) <= ^right and
    #      fragment("?::int", q.shape["y"]) >= ^bottom and
    #      fragment("?::int", q.shape["y"]) <= ^top) or
    #     ((fragment("?::varchar", q.shape["type"]) == "line" and
    #         (fragment("?::int", q.shape["a"]["x"]) >= ^left and
    #            fragment("?::int", q.shape["a"]["x"]) <= ^right and
    #            fragment("?::int", q.shape["a"]["y"]) >= ^bottom and
    #            fragment("?::int", q.shape["a"]["y"]) <= ^top)) or
    #        (fragment("?::int", q.shape["b"]["x"]) >= ^left and
    #           fragment("?::int", q.shape["b"]["x"]) <= ^right and
    #           fragment("?::int", q.shape["b"]["y"]) >= ^bottom and
    #           fragment("?::int", q.shape["b"]["y"]) <= ^top)) or
    #     ((fragment("?::varchar", q.shape["type"]) == "box" and
    #         (fragment("?::int", q.shape["x"]) >= ^left and
    #            fragment("?::int", q.shape["x"]) <= ^right and
    #            fragment("?::int", q.shape["y"]) >= ^bottom and
    #            fragment("?::int", q.shape["y"]) <= ^top)) or
    #        (fragment("?::int", q.shape["x"]) + fragment("?::int", q.shape["w"]) >=
    #           ^left and
    #           fragment("?::int", q.shape["x"]) +
    #             fragment("?::int", q.shape["w"]) <= ^right and
    #           fragment("?::int", q.shape["y"]) +
    #             fragment("?::int", q.shape["h"]) >= ^bottom and
    #           fragment("?::int", q.shape["y"]) +
    #             fragment("?::int", q.shape["h"]) <= ^top))
    # )
    # |> where(
    #   [q],
    #   fragment(
    #     """
    #     (
    #       (?->>'type')::varchar = 'point' AND
    #       (?->>'x')::integer >= ? AND
    #       (?->>'x')::integer <= ? AND
    #       (?->>'y')::integer >= ? AND
    #       (?->>'y')::integer <= ?
    #     )
    #     """,
    #     q.shape,
    #     q.shape,
    #     ^min_x,
    #     q.shape,
    #     ^max_x,
    #     q.shape,
    #     ^min_y,
    #     q.shape,
    #     ^max_y
    #   ) or
    #     ((fragment("(?->>'type')::varchar = 'line'", q.shape) and
    #         ((fragment("(?->>'a'->>'x')::integer >= ?", q.shape, ^min_x) and
    #             fragment("(?->>'a'->>'x')::integer <= ?", q.shape, ^max_x) and
    #             fragment("(?->>'a'->>'y')::integer >= ?", q.shape, ^min_y) and
    #             fragment("(?->>'a'->>'y')::integer <= ?", q.shape, ^max_y)) or
    #            (fragment("(?->>'b'->>'x')::integer >= ?", q.shape, ^min_x) and
    #               fragment("(?->>'b'->>'x')::integer <= ?", q.shape, ^max_x) and
    #               fragment("(?->>'b'->>'y')::integer >= ?", q.shape, ^min_y) and
    #               fragment("(?->>'b'->>'y')::integer <= ?", q.shape, ^max_y)))) or
    #        nil)
    # )
  end
end
