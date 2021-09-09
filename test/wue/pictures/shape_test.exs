defmodule WUE.Pictures.ShapeTest do
  @moduledoc false
  use ExUnit.Case

  alias WUE.Pictures.{Picture, PictureV2}

  describe "traverse_errors/1" do
    test "traverses box errors" do
      params = %{
        shape: %{
          type: "polygon",
          path: [
            %{x: "a", y: "b"},
            %{x: 1},
            %{y: 2}
          ]
        }
      }

      error = %{
        shape: %{
          path: [
            %{x: ["is invalid"], y: ["is invalid"]},
            %{y: ["can't be blank"]},
            %{x: ["can't be blank"]}
          ]
        }
      }

      assert params
             |> Picture.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error

      assert params
             |> PictureV2.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error
    end

    test "traverses line errors" do
      params = %{
        shape: %{
          type: "line",
          a: %{x: "a", y: "b"},
          b: %{x: 1}
        }
      }

      error = %{
        shape: %{
          a: %{x: ["is invalid"], y: ["is invalid"]},
          b: %{y: ["can't be blank"]}
        }
      }

      assert params
             |> Picture.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error

      assert params
             |> PictureV2.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error
    end

    test "traverses point errors" do
      params = %{shape: %{type: "point"}}

      assert params
             |> PictureV2.changeset()
             |> WUEWeb.ErrorView.traverse_errors() ==
               %{shape: %{x: ["can't be blank"], y: ["can't be blank"]}}
    end

    test "traverses polygon errors" do
      params = %{shape: %{type: "box", x: "a", w: "b"}}

      error = %{
        shape: %{
          h: ["can't be blank"],
          w: ["is invalid"],
          x: ["is invalid"],
          y: ["can't be blank"]
        }
      }

      assert params
             |> Picture.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error

      assert params
             |> PictureV2.changeset()
             |> WUEWeb.ErrorView.traverse_errors() == error
    end
  end
end
