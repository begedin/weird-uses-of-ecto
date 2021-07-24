defmodule WUE.Pictures.Picture do
  @moduledoc """
  Example of using ecto to achieve a polymorphic embed
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias WUE.Pictures

  schema "pictures" do
    field(:shape, Pictures.Shape)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%_{} = struct, %{} = params) do
    struct
    |> Changeset.cast(params, [:shape])
    |> Changeset.validate_required([:shape])
  end
end
