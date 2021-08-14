defmodule WUE.Pictures.PictureTest do
  @moduledoc false
  use WUE.DataCase

  alias Ecto.Changeset
  alias WUE.Pictures.{Picture, Shape}

  @polygon_params %{
    shape: %{type: "polygon", path: [%{x: 1, y: 1}, %{x: 2, y: 2}]}
  }

  @box_params %{shape: %{type: "box", x: 1, y: 1, w: 10, h: 15}}

  @point_params %{shape: %{type: "point", x: 1, y: 2}}

  defp stringify(%{} = data), do: data |> Jason.encode!() |> Jason.decode!()

  defp create(%{} = params) do
    params |> Picture.changeset() |> Repo.insert()
  end

  describe "saving" do
    for params <- [@polygon_params, @box_params, @point_params] do
      @params params

      test "can save a #{@params.shape.type}" do
        assert {:ok, picture} = create(@params)

        assert picture.shape ==
                 @params[:shape] |> Shape.load() |> Kernel.elem(1)
      end
    end
  end

  describe "loading" do
    for params <- [@polygon_params, @box_params, @point_params] do
      @params params

      test "can load a #{@params.shape.type}" do
        assert {:ok, picture} = create(@params)

        assert Repo.get(Picture, picture.id).shape ==
                 @params[:shape] |> Shape.load() |> Kernel.elem(1)
      end
    end
  end

  describe "changeset" do
    test "works" do
      assert Picture.changeset(%Picture{}, %{})
    end

    test "validates shape to be a map" do
      assert %{valid?: false} = Picture.changeset(%{shape: "foo"})
    end

    test "validates shape type to be supported" do
      assert %{valid?: false} = Picture.changeset(%{shape: %{type: "foo"}})
    end

    test "casts box" do
      assert %{valid?: true} = changeset = Picture.changeset(@box_params)
      assert Changeset.get_field(changeset, :shape) == @box_params[:shape]
    end

    test "casts box with string keys" do
      params = @box_params |> Jason.encode!() |> Jason.decode!()
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @box_params[:shape]
    end

    test "requires x, y, w, h on a box" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "box"}})

      assert {"box requires the fields x, y, w, h, which are all integers", _} =
               errors[:shape]
    end

    test "casts polygon" do
      assert %{valid?: true} = changeset = Picture.changeset(@polygon_params)
      assert Changeset.get_field(changeset, :shape) == @polygon_params[:shape]
    end

    test "casts polygon with string keys" do
      params = stringify(@polygon_params)
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @polygon_params[:shape]
    end

    test "requires path on polygon" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "polygon"}})

      assert {"polygon requires a path, which is a list of points", _} =
               errors[:shape]
    end

    test "validates each polygon point" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{
                 shape: %{
                   type: "polygon",
                   path: [
                     %{x: 1, y: 1},
                     %{x: "a", y: 1},
                     %{x: 1},
                     %{y: 1},
                     %{}
                   ]
                 }
               })

      assert {message, _} = errors[:shape]
      assert message =~ "Polygon contains invalid points"
      assert message =~ "Point 0 is valid"
      assert message =~ "Point 1 is invalid, x is invalid"
      assert message =~ "Point 2 is invalid, y can't be blank"
      assert message =~ "Point 3 is invalid, x can't be blank"
      assert message =~ "Point 4 is invalid, x can't be blank"
      assert message =~ "Point 4 is invalid, y can't be blank"
    end

    test "casts point" do
      assert %{valid?: true} = changeset = Picture.changeset(@point_params)
      assert Changeset.get_field(changeset, :shape) == @point_params[:shape]
    end

    test "casts point with string keys" do
      params = stringify(@point_params)
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @point_params[:shape]
    end

    test "requires x,y on point" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "point"}})

      assert {"point requires x and y fields, both of which are integers", _} =
               errors[:shape]
    end

    test "validates x and y are integers" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "point", x: "a", y: "b"}})

      assert {"point requires x and y fields, both of which are integers", _} =
               errors[:shape]
    end
  end
end
