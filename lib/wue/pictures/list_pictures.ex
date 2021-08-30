defmodule WUE.Pictures.ListPictures do
  @moduledoc """
  Loads a list of pictures from the database

  Accepts a `WUE.Pictures.BatchParams` struct, which is the result of a
  prevalidation operation.

  Due to receiving a very well defined structure, i.e. an actual elixir struct,
  the code here, as well as the code in `WUE.Pictures.Filter` is relatively
  simple. We already know all fields of the filter are in the current format,
  we know we're dealing with atoms, etc.
  """

  alias WUE.{Pictures, Repo}

  @spec call(Pictures.BatchParams.t()) :: list(Pictures.Picture.t())
  def call(%Pictures.BatchParams{filter: %Pictures.Filter{} = filter}) do
    Pictures.Picture
    |> Pictures.Filter.apply(filter)
    |> Repo.all()
  end
end
