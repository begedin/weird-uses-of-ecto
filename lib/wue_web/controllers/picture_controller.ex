defmodule WUEWeb.PictureController do
  @moduledoc false
  use WUEWeb, :controller

  alias WUE.Pictures

  action_fallback(:fallback)

  def index(conn, params) do
    with {:ok, params} <- Pictures.BatchParams.validate(params),
         pictures <- WUE.Pictures.ListPictures.call(params) do
      conn
      |> put_status(200)
      |> json(pictures)
    end
  end

  def batch_transpose(conn, params) do
    with {:ok, params} <- Pictures.BatchParams.validate(params),
         pictures <- WUE.Pictures.BatchTransposePictures.call(params) do
      conn
      |> put_status(200)
      |> json(pictures)
    end
  end

  defp fallback(conn, {:error, %Ecto.Changeset{valid?: false} = changeset}) do
    conn
    |> put_status(422)
    |> put_view(WUEWeb.ErrorView)
    |> render("422.json", changeset: changeset)
  end
end
