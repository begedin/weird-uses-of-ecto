defmodule WUE.Pictures.BatchParams do
  @moduledoc """
  Params validator for any endpoint working with a list of pictures
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
