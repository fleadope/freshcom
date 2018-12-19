defmodule FCIdentity.Account do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCIdentity.{AccountCreated, AccountInfoUpdated, AccountClosed}

  typedstruct do
    field :id, String.t()

    field :status, String.t()
    field :system_label, String.t()
    field :owner_id, String.t()
    field :mode, String.t()
    field :live_account_id, String.t()
    field :test_account_id, String.t()
    field :default_locale, String.t()

    field :handle, String.t()
    field :name, String.t()
    field :legal_name, String.t()
    field :website_url, String.t()
    field :support_email, String.t()
    field :tech_email, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map, default: %{}
    field :translations, map, default: %{}
  end

  def translatable_fields do
    [
      :name,
      :legal_name,
      :website_url,
      :support_email,
      :tech_email,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %AccountCreated{} = event) do
    %{state | id: event.account_id}
    |> merge(event)
  end

  def apply(%{} = state, %AccountInfoUpdated{locale: locale} = event) do
    state
    |> cast(event)
    |> Translation.put_change(translatable_fields(), locale, state.default_locale)
    |> apply_changes()
  end

  def apply(%{} = state, %AccountClosed{handle: handle}) do
    %{state | status: "deleted", handle: handle}
  end
end