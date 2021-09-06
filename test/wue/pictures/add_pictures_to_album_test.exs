defmodule WUE.Pictures.AddPicturesToAlbumTest do
  @moduledoc false
  use WUE.DataCase

  alias WUE.Pictures

  defp discard_temp, do: Repo.query!("DISCARD TEMP")

  test "adds pictures to album" do
    joes_album = Pictures.create_album!(%{name: "Joes's Album"})
    mikes_album = Pictures.create_album!(%{name: "Mike's Album"})
    my_album = Pictures.create_album!(%{name: "My Album"})
    joe = Pictures.create_artist!(%{name: "Joe", country: "USA"})
    mike = Pictures.create_artist!(%{name: "Mike", country: "UK"})

    picture_1 =
      Pictures.create_picture!(joe, %{shape: %{type: "point", x: 1, y: 2}})

    picture_2 =
      Pictures.create_picture!(mike, %{shape: %{type: "point", x: 1, y: 2}})

    picture_3 =
      Pictures.create_picture!(mike, %{shape: %{type: "point", x: 1, y: 2}})

    params = %Pictures.BatchParams{
      filter: %Pictures.Filter{artist_name: ["Mike"]}
    }

    assert {:ok, _} = Pictures.add_pictures_to_album!(mikes_album, params)

    assert %{albums: []} = Repo.preload(picture_1, :albums)
    assert %{albums: [_]} = Repo.preload(picture_2, :albums)
    assert %{albums: [_]} = Repo.preload(picture_3, :albums)

    params = %Pictures.BatchParams{
      filter: %Pictures.Filter{artist_name: ["Joe"]}
    }

    discard_temp()

    assert {:ok, _} = Pictures.add_pictures_to_album!(joes_album, params)
    assert %{albums: [_]} = Repo.preload(picture_1, :albums)

    params = %Pictures.BatchParams{filter: %Pictures.Filter{select_all: true}}

    discard_temp()

    assert {:ok, _} = Pictures.add_pictures_to_album!(my_album, params)
    assert %{albums: [_, _]} = Repo.preload(picture_1, :albums)
    assert %{albums: [_, _]} = Repo.preload(picture_2, :albums)
    assert %{albums: [_, _]} = Repo.preload(picture_3, :albums)
  end

  test "eliminates name duplicates" do
    my_album = Pictures.create_album!(%{name: "My Album"})

    Pictures.create_picture!(%{name: "A", shape: %{type: "point", x: 1, y: 2}})
    Pictures.create_picture!(%{name: "A", shape: %{type: "point", x: 1, y: 2}})
    Pictures.create_picture!(%{name: "B", shape: %{type: "point", x: 1, y: 2}})

    params = %Pictures.BatchParams{filter: %Pictures.Filter{select_all: true}}

    assert {:ok, _} = Pictures.add_pictures_to_album!(my_album, params)

    assert %{pictures: [_, _]} = Repo.preload(my_album, :pictures)
  end
end
