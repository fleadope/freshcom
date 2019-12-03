defmodule Freshcom.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import UUID
      import Freshcom.Fixture.Identity
      import Freshcom.Shortcut
      import Freshcom.IntegrationCase

      alias Freshcom.Request
    end
  end

  setup tags do
    {:ok, _} = Application.ensure_all_started(:freshcom)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Freshcom.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Freshcom.Repo, {:shared, self()})
    end

    on_exit(fn ->
      :ok = Application.stop(:freshcom)

      FCBase.EventStore.reset!()
    end)

    :ok
  end
end
