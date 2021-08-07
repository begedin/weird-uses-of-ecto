defmodule WUE.Pictures do
  @moduledoc """
  Bounded-context for management of pictures. Serves as a library of examples for
  various potentially weird uses of Ecto.
  """

  alias WUE.{Pictures, Repo}

  def create_picture!(%{} = params) do
    params
    |> Pictures.Picture.changeset()
    |> Repo.insert!()
  end
end
