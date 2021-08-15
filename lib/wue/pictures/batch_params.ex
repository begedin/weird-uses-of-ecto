defmodule WUE.Pictures.BatchParams do
  @moduledoc """
  Params validator for any endpoint working with a list of pictures

  This illustrates a API action pre-validation step as an atypical use for Ecto.

  A lot of endpoints in a complex API will share a common params structure, at
  least partially.

  In this example, batch endpoints share the same format for filtering items in
  that batch.

  An embedded schema is used to define the structure of this format and cast it.
  If the validation of the format fails, we return early from the controller
  action, allowing us to skip any expensive operations and render a typical 422
  validation errors response.

  This is especially useful for endpoints with a shared params structure, but is
  also useful for endpoints where several parameters are simply required to
  perform an action and fetch some data.

  There is finally also value in the fact that using this approach for any
  endpoint requiring additional params which aren't encoded in the path will now
  return a standardized response.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_one(:filter, Pictures.Filter)
  end

  @spec validate(map) :: {:ok, t} | {:error, Changeset.t()}
  def validate(%{} = params) do
    case changeset(params) do
      %{valid?: true} = changeset -> {:ok, Changeset.apply_changes(changeset)}
      %{valid?: false} = changeset -> {:error, changeset}
    end
  end

  @spec changeset(map) :: Changeset.t()
  defp changeset(%{} = params) do
    %__MODULE__{}
    |> Changeset.cast(params, [])
    |> Changeset.cast_embed(:filter, required: true)
  end
end
