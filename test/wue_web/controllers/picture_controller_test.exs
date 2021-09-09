defmodule WUEWeb.PictureControllerTest do
  @moduledoc false

  use WUEWeb.ConnCase

  alias WUE.{Pictures, Repo}

  describe "GET /pictures" do
    @path Routes.picture_path(WUEWeb.Endpoint, :index)

    test "renders 422 if missing filter", %{conn: conn} do
      assert %{
               "errors" => %{"filter" => ["can't be blank"]}
             } = conn |> get(@path) |> json_response(422)
    end

    test "renders 422 if invalid filter", %{conn: conn} do
      params = %{filter: %{}}

      assert %{
               "errors" => %{
                 "filter" => %{
                   "select_all" => [
                     "Filter requires at least one parameter, or explicitly setting 'select_all' to 'true'"
                   ]
                 }
               }
             } = conn |> get(@path, params) |> json_response(422)
    end

    test "returns []", %{conn: conn} do
      params = %{filter: %{select_all: true}}
      assert conn |> get(@path, params) |> json_response(200) == []
    end

    test "returns pictures satisfying the filter", %{conn: conn} do
      Pictures.create_picture!(%{shape: %{type: "point", x: 1, y: 1}})

      Pictures.create_picture!(%{
        shape: %{type: "line", a: %{x: 1, y: 1}, b: %{x: 5, y: 5}}
      })

      Pictures.create_picture!(%{
        shape: %{type: "box", x: 6, y: 6, w: 4, h: 4}
      })

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "point"}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "line"}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "box"}})
               |> json_response(200)

      assert [_, _] =
               conn
               |> get(@path, %{
                 filter: %{bounds: %{min_x: 0, min_y: 0, max_x: 5, max_y: 5}}
               })
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{
                 filter: %{bounds: %{min_x: 6, min_y: 6, max_x: 10, max_y: 10}}
               })
               |> json_response(200)
    end

    test "filters by artist name", %{conn: conn} do
      me = Pictures.create_artist!(%{name: "Me", country: "Croatia"})
      you = Pictures.create_artist!(%{name: "You", country: "Poland"})
      _they = Pictures.create_artist!(%{name: "They", country: "Croatia"})

      Pictures.create_picture!(me, %{shape: %{type: "point", x: 1, y: 1}})
      Pictures.create_picture!(me, %{shape: %{type: "point", x: 1, y: 1}})
      Pictures.create_picture!(you, %{shape: %{type: "point", x: 1, y: 1}})

      assert [_, _] =
               conn
               |> get(@path, %{filter: %{artist_name: ["Me"]}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{artist_name: ["You"]}})
               |> json_response(200)

      assert [_, _, _] =
               conn
               |> get(@path, %{filter: %{artist_name: ["Me", "You"]}})
               |> json_response(200)

      assert [] =
               conn
               |> get(@path, %{filter: %{artist_name: ["They"]}})
               |> json_response(200)
    end

    test "filters by artist country", %{conn: conn} do
      me = Pictures.create_artist!(%{name: "Me", country: "Croatia"})
      you = Pictures.create_artist!(%{name: "You", country: "Poland"})
      _they = Pictures.create_artist!(%{name: "They", country: "Italy"})

      Pictures.create_picture!(me, %{shape: %{type: "point", x: 1, y: 1}})
      Pictures.create_picture!(me, %{shape: %{type: "point", x: 1, y: 1}})
      Pictures.create_picture!(you, %{shape: %{type: "point", x: 1, y: 1}})

      assert [_, _] =
               conn
               |> get(@path, %{filter: %{artist_country: ["Croatia"]}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{artist_country: ["Poland"]}})
               |> json_response(200)

      assert [_, _, _] =
               conn
               |> get(@path, %{filter: %{artist_country: ["Croatia", "Poland"]}})
               |> json_response(200)

      assert [] =
               conn
               |> get(@path, %{filter: %{artist_country: ["Italy"]}})
               |> json_response(200)
    end
  end

  describe "PUT /pictures/batch_transpose" do
    @path Routes.picture_path(WUEWeb.Endpoint, :batch_transpose)

    test "renders 422 if missing filter", %{conn: conn} do
      assert %{
               "errors" => %{"filter" => ["can't be blank"]}
             } = conn |> post(@path) |> json_response(422)
    end

    test "renders 422 if invalid filter", %{conn: conn} do
      params = %{filter: %{}}

      assert %{
               "errors" => %{
                 "filter" => %{
                   "select_all" => [
                     "Filter requires at least one parameter, or explicitly setting 'select_all' to 'true'"
                   ]
                 }
               }
             } = conn |> post(@path, params) |> json_response(422)
    end

    test "returns []", %{conn: conn} do
      params = %{filter: %{select_all: true}}
      assert conn |> post(@path, params) |> json_response(200) == []
    end

    test "batch transforms and returns affected pictures", %{conn: conn} do
      point = Pictures.create_picture!(%{shape: %{type: "point", x: 1, y: 10}})

      line =
        Pictures.create_picture!(%{
          shape: %{type: "line", a: %{x: 1, y: 10}, b: %{x: 5, y: 50}}
        })

      box =
        Pictures.create_picture!(%{
          shape: %{type: "box", x: 6, y: 60, w: 4, h: 40}
        })

      assert [_, _, _] =
               conn
               |> post(@path, %{filter: %{select_all: true}})
               |> json_response(200)

      assert %{point | shape: Pictures.Transpose.call(point.shape)} ==
               Pictures.Picture |> Repo.get(point.id) |> Repo.preload(:artist)

      assert %{line | shape: Pictures.Transpose.call(line.shape)} ==
               Pictures.Picture |> Repo.get(line.id) |> Repo.preload(:artist)

      assert %{box | shape: Pictures.Transpose.call(box.shape)} ==
               Pictures.Picture |> Repo.get(box.id) |> Repo.preload(:artist)
    end
  end

  describe "POST /pictures" do
    @path Routes.picture_path(WUEWeb.Endpoint, :create)

    test "renders 422 if invalid params", %{conn: conn} do
      params = %{"shape" => %{"type" => "box", "x" => "foo"}}

      assert conn |> post(@path, params) |> json_response(422) == %{
               "errors" => %{
                 "shape" => %{
                   "h" => ["can't be blank"],
                   "w" => ["can't be blank"],
                   "x" => ["is invalid"],
                   "y" => ["can't be blank"]
                 }
               }
             }
    end
  end

  describe "POST /v2/pictures" do
    @path Routes.picture_path(WUEWeb.Endpoint, :create_v2)

    test "renders 422 if invalid params", %{conn: conn} do
      params = %{"shape" => %{"type" => "box", "x" => "foo"}}

      assert conn |> post(@path, params) |> json_response(422) == %{
               "errors" => %{
                 "shape" => %{
                   "h" => ["can't be blank"],
                   "w" => ["can't be blank"],
                   "x" => ["is invalid"],
                   "y" => ["can't be blank"]
                 }
               }
             }
    end
  end
end
