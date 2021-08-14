defmodule WUE.Pictures do
  @moduledoc """
  Bounded-context for management of pictures. Serves as a library of examples for
  various potentially weird uses of Ecto.
  """

  alias WUE.{Pictures, Repo}

  @type shape ::
          Pictures.Shape.Box.t()
          | Pictures.Shape.Line.t()
          | Pictures.Shape.Point.t()
          | Pictures.Shape.Polygon.t()

  @doc """
  Used to create a new picture. Shape of expected params is

  ```
  ```
  %{
    "shape" => %{"type" => "point", "x" => integer, "y" => integer}
  }

  %{
    "shape" => %{
      "type" => "line",
      "a" => %{"x" => integer, "y" => integer},
      "b" => %{"x" => integer, "y" => integer}
    }
  }

  %{
    "shape" => %{
      "type" => "box",
      "x" => integer, "y" => integer,
      "w" => integer, "h" => integer
    }
  }

  %{
    "shape" => %{
      "type" => "polygon",
      "path" => list(%{"x" => integer, "y" => integer})
    }
  }
  ```

  Atom keys are also supported
  """
  @spec create_picture!(map) :: Pictures.Picture.t()
  def create_picture!(%{} = params) do
    params
    |> Pictures.Picture.changeset()
    |> Repo.insert!()
  end

  @spec list_pictures(map) :: list(Pictures.Picture.t())
  def list_pictures(%{} = params) do
    Pictures.ListPictures.call(params)
  end
end
