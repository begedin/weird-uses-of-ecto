defmodule Test do
  @moduledoc false
  use WUE.DataCase

  alias Ecto.Changeset
  alias WUE.Pictures.PictureV2

  doctest WUE.Pictures.PictureV2

  @polygon_params %{
    shape: %{type: "polygon", path: [%{x: 1, y: 1}, %{x: 2, y: 2}]}
  }
  @polygon %{
    "path" => [
      %{"x" => 1, "y" => 1},
      %{"x" => 2, "y" => 2}
    ],
    "type" => "polygon"
  }

  @box_params %{shape: %{type: "box", x: 1, y: 1, w: 10, h: 15}}
  @box %{"x" => 1, "y" => 1, "w" => 10, "h" => 15, "type" => "box"}

  @point_params %{shape: %{type: "point", x: 1, y: 2}}
  @point %{"x" => 1, "y" => 2, "type" => "point"}

  @line_params %{
    shape: %{
      type: "line",
      a: %{x: 1, y: 2},
      b: %{x: 3, y: 4}
    }
  }

  @line %{
    "a" => %{"x" => 1, "y" => 2},
    "b" => %{"x" => 3, "y" => 4},
    "type" => "line"
  }

  defp stringify(%{} = data), do: data |> Jason.encode!() |> Jason.decode!()

  defp create(%{} = params) do
    params |> PictureV2.changeset() |> Repo.insert()
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

        assert Repo.get(PictureV2, picture.id).shape == @output
      end
    end
  end

  describe "changeset" do
    test "works" do
      assert PictureV2.changeset(%PictureV2{}, %{})
    end

    test "validates shape to be a map" do
      assert %{valid?: false} = PictureV2.changeset(%{shape: "foo"})
    end

    test "validates shape type to be supported" do
      assert %{valid?: false} = PictureV2.changeset(%{shape: %{type: "foo"}})
    end

    test "casts box" do
      assert %{valid?: true} = changeset = PictureV2.changeset(@box_params)
      assert Changeset.get_field(changeset, :shape) == @box
    end

    test "casts box with string keys" do
      params = @box_params |> Jason.encode!() |> Jason.decode!()
      assert %{valid?: true} = changeset = PictureV2.changeset(params)

      assert Changeset.get_field(changeset, :shape) == @box
    end

    test "requires x, y, w, h on a box" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{shape: %{type: "box"}})

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   h: [{"can't be blank", [validation: :required]}],
                   w: [{"can't be blank", [validation: :required]}],
                   x: [{"can't be blank", [validation: :required]}],
                   y: [{"can't be blank", [validation: :required]}]
                 }
               ]
             }
    end

    test "casts polygon" do
      assert %{valid?: true} = changeset = PictureV2.changeset(@polygon_params)
      assert Changeset.get_field(changeset, :shape) == @polygon
    end

    test "casts polygon with string keys" do
      params = stringify(@polygon_params)
      assert %{valid?: true} = changeset = PictureV2.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @polygon
    end

    test "requires path on polygon" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{shape: %{type: "polygon"}})

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   path: [{"can't be blank", [validation: :required]}]
                 }
               ]
             }
    end

    test "validates each polygon point" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{
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

      assert errors[:shape] ==
               {"is invalid",
                [
                  extra_errors: %{
                    path: [
                      %{},
                      %{
                        x: [{"is invalid", [type: :integer, validation: :cast]}]
                      },
                      %{y: [{"can't be blank", [validation: :required]}]},
                      %{x: [{"can't be blank", [validation: :required]}]},
                      %{
                        x: [{"can't be blank", [validation: :required]}],
                        y: [{"can't be blank", [validation: :required]}]
                      }
                    ]
                  }
                ]}
    end

    test "casts point" do
      assert %{valid?: true} = changeset = PictureV2.changeset(@point_params)
      assert Changeset.get_field(changeset, :shape) == @point
    end

    test "casts point with string keys" do
      params = stringify(@point_params)
      assert %{valid?: true} = changeset = PictureV2.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @point
    end

    test "requires x,y on point" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{shape: %{type: "point"}})

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   x: [{"can't be blank", [validation: :required]}],
                   y: [{"can't be blank", [validation: :required]}]
                 }
               ]
             }
    end

    test "validates x and y are integers" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{shape: %{type: "point", x: "a", y: "b"}})

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   x: [{"is invalid", [type: :integer, validation: :cast]}],
                   y: [{"is invalid", [type: :integer, validation: :cast]}]
                 }
               ]
             }
    end

    test "casts line" do
      assert %{valid?: true} = changeset = PictureV2.changeset(@line_params)
      assert Changeset.get_field(changeset, :shape) == @line
    end

    test "casts line with string keys" do
      params = stringify(@line_params)
      assert %{valid?: true} = changeset = PictureV2.changeset(params)
      assert Changeset.get_field(changeset, :shape) == @line
    end

    test "requires both points on line" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{shape: %{type: "line"}})

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   a: [{"can't be blank", [validation: :required]}],
                   b: [{"can't be blank", [validation: :required]}]
                 }
               ]
             }
    end

    test "validates points on line" do
      assert %{valid?: false, errors: errors} =
               PictureV2.changeset(%{
                 shape: %{type: "line", a: %{x: "a", y: "b"}, b: %{x: 1, y: 2}}
               })

      assert errors[:shape] == {
               "is invalid",
               [
                 extra_errors: %{
                   a: %{
                     x: [{"is invalid", [type: :integer, validation: :cast]}],
                     y: [{"is invalid", [type: :integer, validation: :cast]}]
                   }
                 }
               ]
             }
    end
  end
end
