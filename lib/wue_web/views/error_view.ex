defmodule WUEWeb.ErrorView do
  use WUEWeb, :view

  alias Ecto.Changeset
  alias WUE.Pictures

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".

  def render(
        "422.json",
        %{changeset: %Changeset{data: %Pictures.Picture{}} = changeset}
      ) do
    %{
      errors: traverse_errors(changeset)
    }
  end

  def render(
        "422.json",
        %{changeset: %Changeset{data: %Pictures.PictureV2{}} = changeset}
      ) do
    %{
      errors: traverse_errors(changeset)
    }
  end

  def render("422.json", %{changeset: %Changeset{} = changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end

  def template_not_found(template, _assigns) do
    %{
      errors: %{
        detail: Phoenix.Controller.status_message_from_template(template)
      }
    }
  end

  alias Ecto.Changeset

  @doc """
  Error traversal function specifically designed to convert the :extra_errors
  key of a `WUE.Pictures.{Picture,PictureV2}` changeset.

  The `WUEWeb.ErrorView` is in charge of calling this when necessary.

  This is what renders the :extra_errors conent in the same way one would
  regularly render errors on a normal ecto embed.
  """
  @spec traverse_errors(Changeset.t()) :: map
  def traverse_errors(%Changeset{} = changeset) do
    traversed =
      Changeset.traverse_errors(changeset, fn {msg, opts} ->
        if opts[:extra_errors] do
          opts[:extra_errors]
          |> Enum.map(&do_traverse_errors/1)
          |> Map.new()
        else
          WUEWeb.ErrorHelpers.translate_error({msg, opts})
        end
      end)

    case Map.get(traversed, :shape) do
      nil -> traversed
      [shape_errors] -> Map.put(traversed, :shape, shape_errors)
    end
  end

  @spec do_traverse_errors(
          {atom, map}
          | {atom, list}
          | map
          | {String.t(), Keyword.t()}
        ) ::
          {atom, map}
          | {atom, list}
          | map
          | {String.t(), Keyword.t()}
  defp do_traverse_errors(error) do
    case error do
      {field, %{} = value} when is_atom(field) ->
        {field, value |> Enum.map(&do_traverse_errors/1) |> Map.new()}

      {field, [msg]} when is_atom(field) and is_binary(msg) ->
        {field, [msg]}

      {field, value} when is_atom(field) and is_list(value) ->
        {field, Enum.map(value, &do_traverse_errors/1)}

      %{} = errors ->
        errors |> Enum.map(&do_traverse_errors/1) |> Map.new()

      {msg, opts} when is_binary(msg) ->
        WUEWeb.ErrorHelpers.translate_error({msg, opts})
    end
  end
end
