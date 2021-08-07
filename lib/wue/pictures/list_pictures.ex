defmodule WUE.Pictures.ListPictures do
  @moduledoc """
  Use-case module for loading a list of pictures from the database
  """

  alias WUE.{Pictures, Repo}

  def call(%Pictures.BatchParams{filter: %Pictures.Filter{} = filter}) do
    Pictures.Picture
    |> Pictures.Filter.apply(filter)
    |> Repo.all()
  end
end
