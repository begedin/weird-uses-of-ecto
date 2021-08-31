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
        %{changeset: %Changeset{data: %Pictures.PictureV2{}} = changeset}
      ) do
    %{
      errors: Pictures.PictureV2.traverse_errors(changeset)
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
end
