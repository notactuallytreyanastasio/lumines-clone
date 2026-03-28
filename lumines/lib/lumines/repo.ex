defmodule Lumines.Repo do
  use Ecto.Repo,
    otp_app: :lumines,
    adapter: Ecto.Adapters.Postgres
end
