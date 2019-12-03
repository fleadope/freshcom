defmodule FCIdentity.UserHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import Comeonin.Argon2
  import FCSupport.Normalization
  import FCIdentity.UserPolicy

  alias FCIdentity.UsernameStore

  alias FCIdentity.{
    RegisterUser,
    AddUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo,
    ChangeDefaultAccount,
    GenerateEmailVerificationToken,
    VerifyEmail
  }

  alias FCIdentity.{
    UserAdded,
    UserRegistered,
    UserDeleted,
    PasswordResetTokenGenerated,
    PasswordChanged,
    UserRoleChanged,
    UserInfoUpdated,
    DefaultAccountChanged,
    EmailVerificationTokenGenerated,
    EmailVerified
  }

  def handle(%{id: nil} = state, %RegisterUser{} = cmd) do
    user_registered = %UserRegistered{
      default_account_id: uuid4(),
      status: "active",
      role: "owner"
    }

    evt_generated = %EmailVerificationTokenGenerated{
      user_id: cmd.user_id,
      token: uuid4(),
      expires_at: to_utc_iso8601(Timex.shift(Timex.now(), hours: 24))
    }

    cmd
    |> authorize(state)
    ~> trim_strings()
    ~> keep_username()
    ~> merge_to(user_registered)
    ~> put_password_hash(cmd)
    ~> List.wrap()
    ~> Kernel.++([evt_generated])
    |> unwrap_ok()
  end

  def handle(_, %RegisterUser{}), do: {:error, {:already_registered, :user}}

  def handle(%{id: nil} = state, %AddUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> trim_strings()
    ~> keep_username()
    ~> merge_to(%UserAdded{type: "managed"})
    ~> put_password_hash(cmd)
    |> unwrap_ok()
  end

  def handle(_, %AddUser{}), do: {:error, {:already_exist, :user}}

  def handle(%{id: nil}, _), do: {:error, {:not_found, :user}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :user}}

  def handle(state, %DeleteUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserDeleted{username: state.username})
    |> unwrap_ok()
  end

  def handle(state, %GeneratePasswordResetToken{} = cmd) do
    case authorize(cmd, state) do
      {:ok, cmd} ->
        %PasswordResetTokenGenerated{
          user_id: cmd.user_id,
          token: uuid4(),
          expires_at: to_utc_iso8601(cmd.expires_at)
        }

      other ->
        other
    end
  end

  def handle(state, %GenerateEmailVerificationToken{} = cmd) do
    expires_at = to_utc_iso8601(cmd.expires_at)

    cmd
    |> authorize(state)
    ~> merge_to(%EmailVerificationTokenGenerated{token: uuid4(), expires_at: expires_at}, except: [:expires_at])
    |> unwrap_ok()
  end

  def handle(state, %VerifyEmail{} = cmd) do
    cmd
    |> authorize(state)
    ~>> validate_verification_token(state)
    ~> merge_to(%EmailVerified{})
    |> unwrap_ok()
  end

  def handle(state, %ChangePassword{} = cmd) do
    cmd
    |> authorize(state)
    ~>> validate_current_password(state)
    ~>> validate_reset_token(state)
    ~> merge_to(%PasswordChanged{
      new_password_hash: hashpwsalt(cmd.new_password),
      original_password_hash: state.password_hash
    })
    |> unwrap_ok()
  end

  def handle(state, %ChangeUserRole{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserRoleChanged{original_role: state.role})
    |> unwrap_ok()
  end

  def handle(state, %UpdateUserInfo{} = cmd) do
    default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCIdentity.User.translatable_fields()

    cmd
    |> authorize(state)
    ~> keep_username(state)
    ~> merge_to(%UserInfoUpdated{})
    ~> put_translations(state, translatable_fields, default_locale)
    ~> put_original_fields(state)
    |> unwrap_ok()
  end

  def handle(state, %ChangeDefaultAccount{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%DefaultAccountChanged{
      default_account_id: cmd.account_id,
      original_default_account_id: state.default_account_id
    })
    |> unwrap_ok()
  end

  defp keep_username(%{username: nil} = cmd), do: cmd

  defp keep_username(%RegisterUser{} = cmd) do
    UsernameStore.put(cmd.username, cmd.user_id)
    cmd
  end

  defp keep_username(%AddUser{} = cmd) do
    UsernameStore.put(cmd.username, cmd.user_id, cmd.account_id)
    cmd
  end

  defp keep_username(%UpdateUserInfo{} = cmd, state) do
    if Enum.member?(cmd.effective_keys, "username") && cmd.username != state.username do
      UsernameStore.delete(state.username, state.account_id)
      UsernameStore.put(cmd.username, cmd.user_id, cmd.account_id)
    end

    cmd
  end

  defp put_password_hash(event, %{password: password}) when byte_size(password) > 0 do
    %{event | password_hash: hashpwsalt(password)}
  end

  defp put_password_hash(event, _), do: event

  defp validate_current_password(%{current_password: cp} = cmd, %{password_hash: ph}) when is_binary(cp) do
    if checkpw(cp, ph) do
      {:ok, cmd}
    else
      {:error, {:validation_failed, [{:error, :current_password, :invalid}]}}
    end
  end

  defp validate_current_password(cmd, _), do: {:ok, cmd}

  defp validate_reset_token(%{reset_token: reset_token} = cmd, state) when is_binary(reset_token) do
    cond do
      is_reset_token_valid?(reset_token, state) ->
        {:ok, cmd}

      reset_token != state.password_reset_token ->
        {:error, {:validation_failed, [{:error, :reset_token, :invalid}]}}

      !Timex.before?(Timex.now(), state.password_reset_token_expires_at) ->
        {:error, {:validation_failed, [{:error, :reset_token, :expired}]}}
    end
  end

  defp validate_reset_token(cmd, _), do: {:ok, cmd}

  defp is_reset_token_valid?(reset_token, state) do
    reset_token == state.password_reset_token && Timex.before?(Timex.now(), state.password_reset_token_expires_at)
  end

  defp validate_verification_token(%{verification_token: verification_token} = cmd, state)
       when is_binary(verification_token) do
    cond do
      is_verification_token_valid?(verification_token, state) ->
        {:ok, cmd}

      verification_token != state.email_verification_token ->
        {:error, {:validation_failed, [{:error, :verification_token, :invalid}]}}

      !Timex.before?(Timex.now(), state.email_verification_token_expires_at) ->
        {:error, {:validation_failed, [{:error, :verification_token, :expired}]}}
    end
  end

  defp validate_verification_token(cmd, _), do: {:ok, cmd}

  defp is_verification_token_valid?(verification_token, state) do
    verification_token == state.email_verification_token &&
      Timex.before?(Timex.now(), state.password_reset_token_expires_at)
  end
end
