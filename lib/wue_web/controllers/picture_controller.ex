defmodule WUEWeb.PictureController do
  @moduledoc false
  use WUEWeb, :controller

  alias WUE.Pictures

  action_fallback(:fallback)

  @doc """
  Retrieves a list of images matching a filter.

  The filter structure is shared between this and the `batch_transpose/2`
  endpoint, so it's  validated and parsed in a prevalidation step.
  """

  def index(conn, params) do
    with {:ok, %Pictures.BatchParams{} = params} <-
           Pictures.validate_batch_params(params),
         pictures <- WUE.Pictures.list_pictures(params) do
      conn
      |> put_status(200)
      |> json(pictures)
    end
  end

  @doc """
  Performs a batch operation in a set of pictures defined by a filter.

  The filter structure is shared between this and the `index` endpoint, so it's
  validated and parsed in a prevalidation step.
  """
  def batch_transpose(conn, params) do
    with {:ok, %Pictures.BatchParams{} = params} <-
           Pictures.validate_batch_params(params),
         pictures <- WUE.Pictures.batch_transpose(params) do
      conn
      |> put_status(200)
      |> json(pictures)
    end
  end

  @doc """
  Creates a picture using a custom ecto-type to achieve a "polymorphic embed"
  effect.

  This is a simpler and cleaner method, but is not as good as building
  a validation error response payload.

  See controller tests to understand the outcomes.

  Note that the `rescue` approach is atypical and something the author would
  probably not recommend.
  """
  def create(conn, params) do
    picture = Pictures.create_picture!(params)

    conn
    |> put_status(200)
    |> json(picture)
  rescue
    e in Ecto.InvalidChangesetError -> {:error, e.changeset}
  end

  @doc """
  Creates a picture using embedded schemas to achieve a "polymorphic embed"
  effect.

  This is a more complex, less clean method, but allows for deeply nested
  custom errors.

  See controller tests to understand the outcomes.

  Note that the `rescue` approach is atypical and something the author would
  probably not recommend.
  """
  def create_v2(conn, params) do
    picture = Pictures.create_picture_v2!(params)

    conn
    |> put_status(200)
    |> json(picture)
  rescue
    e in Ecto.InvalidChangesetError -> {:error, e.changeset}
  end

  defp fallback(conn, {:error, %Ecto.Changeset{valid?: false} = changeset}) do
    conn
    |> put_status(422)
    |> put_view(WUEWeb.ErrorView)
    |> render("422.json", changeset: changeset)
  end
end
