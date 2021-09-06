defmodule WUE.Pictures.AddPicturesToAlbum do
  @moduledoc """
  Use-case module. Example of using temp tables to speed up large operations
  """
  import Ecto.Query, only: [join: 5, select: 3, subquery: 1, where: 3]

  alias Ecto.Multi
  alias WUE.{Pictures, Repo}

  defmodule TempData do
    @moduledoc """
    We can define a schema module for the temp table, to make certain things
    easier.

    For example, Repo.all works out of the box this way, with no
    explicit select needed.

    Also, with more complex operations, it allows us to centralize some of the
    data.
    """
    use Ecto.Schema

    @primary_key false
    schema "tmp_data" do
      field(:album_id, :integer, null: false)
      field(:picture_id, :integer, null: false)
      field(:picture_name, :string, null: false)
    end
  end

  @type result :: %{
          cleanup_data: {integer, nil},
          copy_data: {integer, nil},
          create_temp_table: Postgrex.Result.t(),
          drop_temp_table: Postgrex.Result.t(),
          prepare_data: {integer, nil}
        }

  @doc false
  @spec call(Pictures.Album.t(), Pictures.BatchParams.t()) :: {:ok, result}
  def call(%Pictures.Album{} = album, %Pictures.BatchParams{} = params) do
    # All this could also be done in a simple Repo.transaction callback,
    # but using a multi makes it a bit easier to debug things, and think of the
    # process in discrete steps.
    Multi.new()
    |> Multi.run(:create_temp_table, fn repo, _t -> create_temp_table(repo) end)
    # General process when using temp table usually runs like this example
    # - we prepopulate the temp table with data that helps us build the final
    #   data in actual tables
    # - we run some operations on prepopulated data, or add more data into it
    #   from additional sources, etc.
    # - once all is ready, we copy the data into the actual target table
    |> Multi.insert_all(
      :prepare_data,
      TempData,
      fn _t -> insert_into_temp_table(album, params) end
    )
    |> Multi.delete_all(:cleanup_data, fn _t -> cleanup() end)
    |> Multi.insert_all(
      :copy_data,
      "pictures_albums",
      fn _t -> copy_to_actual_table() end
    )
    |> Repo.transaction()
  end

  # This could also be a function within the TempData module. This usually
  # works well when the same temp-table is used across multiple operations,
  # within the backend.
  @spec create_temp_table(repo :: module) :: {:ok, Postgrex.Result.t()}
  defp create_temp_table(repo) do
    repo.query("""
      CREATE TEMPORARY TABLE #{TempData.__schema__(:source)} (
        album_id int,
        picture_id int,
        picture_name varchar
      ) ON COMMIT DROP
    """)
  end

  # This is just a query, since we have Multi.insert_all to use
  # Multi.insert_all and Repo.insert_all both support a query as the source in
  # recent versions.
  @spec insert_into_temp_table(
          Pictures.Album.t(),
          Pictures.BatchParams.t()
        ) :: Ecto.Query.t()
  defp insert_into_temp_table(
         %Pictures.Album{} = album,
         %Pictures.BatchParams{} = params
       ) do
    Pictures.Picture
    |> Pictures.Filter.apply(params.filter)
    |> select([picture], %{
      album_id: ^album.id,
      picture_id: picture.id,
      picture_name: picture.name
    })
  end

  # Again, just a query, this time as a source for deletion
  # We only allow unique names in an album, so this query returns all
  # duplicate names using a window function.
  @spec cleanup :: Ecto.Query.t()
  defp cleanup do
    ranked_named =
      TempData
      |> where([temp], not is_nil(temp.picture_name))
      |> select([temp], %{
        picture_id: temp.picture_id,
        rank: over(row_number(), partition_by: :picture_name)
      })

    TempData
    |> join(:inner, [temp], rank in ^subquery(ranked_named),
      on: temp.picture_id == rank.picture_id and rank.rank > 1
    )
  end

  # And one more query, this time, again, a source for an insert into the final
  # table.
  @spec copy_to_actual_table :: Ecto.Query.t()
  defp copy_to_actual_table do
    select(TempData, [temp], %{
      album_id: temp.album_id,
      picture_id: temp.picture_id
    })
  end

  @spec drop_temp_table(repo :: module) :: {:ok, Postgrex.Result.t()}
  defp drop_temp_table(repo) do
    repo.query("DROP TABLE IF EXISTS #{TempData.__schema__(:source)}")
  end
end
