defmodule WUE.Pictures.BatchTransposePictures do
  import Ecto.Query, only: [join: 5, select: 3, update: 3]

  alias WUE.{Pictures, Repo}

  def call(%Pictures.BatchParams{} = filter) do
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
