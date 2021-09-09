defmodule WUE.Pictures.Shape.Utils do
  @moduledoc false

  alias Ecto.Changeset

  @doc """
  Collects errors on the changeset into a map, without any transformations
  """
  @spec collect_errors_into_map(Changeset.t()) :: map
  def collect_errors_into_map(%Changeset{} = shape_changeset) do
    Changeset.traverse_errors(shape_changeset, fn _c, _field, {msg, opts} ->
      {msg, opts}
    end)
  end
end
