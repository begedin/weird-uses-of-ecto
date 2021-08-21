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
    create_picture!(nil, params)
  end

  @doc """
  Used to create a picture associated to an artist
  """
  @spec create_picture!(Pictures.Artist.t() | nil, map) :: Pictures.Picture.t()
  def create_picture!(artist, %{} = params) do
    params
    |> Pictures.Picture.changeset()
    |> Ecto.Changeset.put_assoc(:artist, artist)
    |> Repo.insert!()
  end

  @just_helper "Just a helper function, not really an example for anything."

  @doc """
  Used to create an artist.

  #{@just_helper}
  """
  @spec create_artist!(map) :: Pictures.Artist.t()
  def create_artist!(%{} = params) do
    params
    |> Pictures.Artist.changeset()
    |> Repo.insert!()
  end

  @doc """
  Lists pictures matching the given filter. This is part of an example of how
  a complex set of parameters, commonly used across the app, can be prevalidated
  and converted into a struct, so further operations that use it can be made
  simpler.

  In this case, rather than receiving a dynamic map and filtering on that, this
  function receives a well defined struct, guaranteed to be valid, because it
  was already prevalidated using `WUE.Pictures.BatchParams.validate/1`
  """
  @spec list_pictures(Pictures.BatchParams.t()) :: list(Pictures.Picture.t())
  def list_pictures(%Pictures.BatchParams{} = params) do
    Pictures.ListPictures.call(params)
  end

  @doc """
  Performs a naive transpose operation on a batch of pictures matching the
  given filter.

  This is an example of passing in a list of attributes into an ecto update
  operation, to join on.

  See module for further documentation.
  """
  @spec batch_transpose(Pictures.BatchParams.t()) :: list(Pictures.Picture.t())
  def batch_transpose(%Pictures.BatchParams{} = params) do
    Pictures.BatchTransposePictures.call(params)
  end

  @doc """
  Creates an album.

  #{@just_helper}
  """
  @spec create_album!(map) :: Pictures.Album.t()
  def create_album!(%{} = params) do
    params
    |> Pictures.Album.changeset()
    |> Repo.insert!()
  end

  @doc """
  Adds pictures matching the specified batch params into the specified album.

  Serves as an example of using ecto with temp tables to speed up batch
  preprocessing of data in large volumes, to speed up a slow operation which
  is performed on a large number of items.
  """
  @spec add_pictures_to_album!(
          Pictures.Album.t(),
          Pictures.BatchParams.t()
        ) :: {:ok, Pictures.AddPicturesToAlbum.result()}

  def add_pictures_to_album!(
        %Pictures.Album{} = album,
        %Pictures.BatchParams{} = params
      ) do
    Pictures.AddPicturesToAlbum.call(album, params)
  end
end
