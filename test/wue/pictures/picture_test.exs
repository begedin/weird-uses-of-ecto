defmodule WUE.Pictures.PictureTest do
  @moduledoc false
  use WUE.DataCase

  alias Ecto.Changeset
  alias WUE.Pictures.{Picture, Shape}

  doctest WUE.Pictures.Picture

  @polygon_params %{
    shape: %{type: "polygon", path: [%{x: 1, y: 1}, %{x: 2, y: 2}]}
  }
  @polygon %Shape.Polygon{
    path: [
      %Shape.Point{x: 1, y: 1},
      %Shape.Point{x: 2, y: 2}
    ]
  }

  @box_params %{shape: %{type: "box", x: 1, y: 1, w: 10, h: 15}}
  @box %Shape.Box{x: 1, y: 1, w: 10, h: 15}

  @point_params %{shape: %{type: "point", x: 1, y: 2}}
  @point %Shape.Point{x: 1, y: 2}

  @line_params %{
    shape: %{
      type: "line",
      a: %{x: 1, y: 2},
      b: %{x: 3, y: 4}
    }
  }

  @line %Shape.Line{
    a: %Shape.Point{x: 1, y: 2},
    b: %Shape.Point{x: 3, y: 4}
  }

  defp stringify(%{} = data), do: data |> Jason.encode!() |> Jason.decode!()

  defp create(%{} = params) do
    params |> Picture.changeset() |> Repo.insert()
  end

  describe "saving" do
    for {input, output} <- [
          {@box_params, @box},
          {@line_params, @line},
          {@point_params, @point},
          {@polygon_params, @polygon}
        ] do
      @input input
      @output output

      test "can save a #{@input.shape.type}" do
        assert {:ok, picture} = create(@input)
        assert picture.shape == @output
      end
    end
  end

  describe "loading" do
    for {input, output} <- [
          {@box_params, @box},
          {@line_params, @line},
          {@point_params, @point},
          {@polygon_params, @polygon}
        ] do
      @input input
      @output output

      test "can load a #{@input.shape.type}" do
        assert {:ok, picture} = create(@input)

        assert Repo.get(Picture, picture.id).shape == @output
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
      assert Changeset.get_field(changeset, :shape) == @box
    end

    test "casts box with string keys" do
      params = @box_params |> Jason.encode!() |> Jason.decode!()
      assert %{valid?: true} = changeset = Picture.changeset(params)

      assert Changeset.get_field(changeset, :shape) == @box
    end

    test "requires x, y, w, h on a box" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "box"}})

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{
               h: ["can't be blank"],
               w: ["can't be blank"],
               x: ["can't be blank"],
               y: ["can't be blank"]
             }
    end

    test "casts polygon" do
      assert %{valid?: true} = changeset = Picture.changeset(@polygon_params)
      assert Changeset.get_field(changeset, :shape) == @polygon
    end

    test "casts polygon with string keys" do
      params = stringify(@polygon_params)
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @polygon
    end

    test "requires path on polygon" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "polygon"}})

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{path: ["can't be blank"]}
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

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{
               path: [
                 %{},
                 %{x: ["is invalid"]},
                 %{y: ["can't be blank"]},
                 %{x: ["can't be blank"]},
                 %{x: ["can't be blank"], y: ["can't be blank"]}
               ]
             }
    end

    test "casts point" do
      assert %{valid?: true} = changeset = Picture.changeset(@point_params)
      assert Changeset.get_field(changeset, :shape) == @point
    end

    test "casts point with string keys" do
      params = stringify(@point_params)
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @point
    end

    test "requires x,y on point" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "point"}})

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{
               x: ["can't be blank"],
               y: ["can't be blank"]
             }
    end

    test "validates x and y are integers" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "point", x: "a", y: "b"}})

      assert {"is invalid", opts} = errors[:shape]
      assert opts[:extra_errors] == %{x: ["is invalid"], y: ["is invalid"]}
    end

    test "casts line" do
      assert %{valid?: true} = changeset = Picture.changeset(@line_params)
      assert Changeset.get_field(changeset, :shape) == @line
    end

    test "casts line with string keys" do
      params = stringify(@line_params)
      assert %{valid?: true} = changeset = Picture.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @line
    end

    test "requires both points on line" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{shape: %{type: "line"}})

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{
               a: ["can't be blank"],
               b: ["can't be blank"]
             }
    end

    test "validates points on line" do
      assert %{valid?: false, errors: errors} =
               Picture.changeset(%{
                 shape: %{type: "line", a: %{x: "a", y: "b"}, b: %{x: 1, y: 2}}
               })

      assert {"is invalid", opts} = errors[:shape]

      assert opts[:extra_errors] == %{
               a: %{x: ["is invalid"], y: ["is invalid"]}
             }
    end
  end
end
