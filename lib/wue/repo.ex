defmodule WUE.Repo do
  use Ecto.Repo,
    otp_app: :wue,
    adapter: Ecto.Adapters.Postgres
end
