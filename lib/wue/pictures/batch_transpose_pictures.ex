defmodule WUE.Pictures.BatchTransposePictures do
  @moduledoc """
  Use-case module in charge of performing a transpose operation on a batch of
  pictures.

  Serves as an example of how one interpolate and join on a list defined in
  elixir, to perform an update operation in batch, where each item being updated
  receives different attributes.
  """
  import Ecto.Query, only: [join: 5, select: 3, update: 3]

  alias WUE.{Pictures, Repo}

  @doc false
  @spec call(Pictures.BatchParams.t()) :: list(Pictures.Picture.t())
  def call(%Pictures.BatchParams{} = filter) do
    # The data list contains new attributes for the item, where each of the
    # attributes holds an id to join on.
    new_data =
      filter
      |> Pictures.list_pictures()
      |> Enum.map(fn %Pictures.Picture{} = picture ->
        transposed =
          picture.shape
          |> Pictures.Transpose.call()
          |> Pictures.Shape.dump()
          |> Kernel.elem(1)

        %{id: picture.id, shape: transposed}
      end)

    {_count, updated} =
      Pictures.Picture
      |> join(
        :inner,
        [picture],
        data in fragment(
          """
          SELECT
            (values ->> 'id')::bigint AS id,
            (values -> 'shape') AS shape
          FROM JSONB_ARRAY_ELEMENTS(?) AS values
          """,
          ^new_data
        ),
        as: :data,
        on: picture.id == data.id
      )
      |> update([data: data], set: [shape: data.shape])
      |> select([picture], picture)
      |> Repo.update_all([])

    updated
  end
end
