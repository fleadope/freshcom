defmodule Mix.Tasks.Freshcom.Demo do
  use Mix.Task

  alias Freshcom.Request
  alias Freshcom.Identity

  def run(_) do
    Application.ensure_all_started(:freshcom)

    req = %Request{
      data: %{
        "name" => "Demo User",
        "username" => "test@example.com",
        "email" => "test@example.com",
        "password" => "test1234",
        "is_term_accepted" => true
      },
      _role_: "system"
    }

    {:ok, _} = Identity.register_user(req)

    req = %Request{
      data: %{
        "type" => "system",
        "name" => "Freshcom Dashboard"
      },
      _role_: "system"
    }

    {:ok, %{data: app}} = Identity.add_app(req)
    IO.puts "System App created: app-#{app.id}"
  end
end
