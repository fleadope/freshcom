defmodule Freshcom.IdentityTest do
  use Freshcom.IntegrationCase

  alias Freshcom.Identity

  describe "register_user/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.register_user(%Request{})
      assert length(errors) > 0
    end

    test "given valid request" do
      client = system_app()

      req = %Request{
        client_id: client.id,
        data: %{
          "name" => Faker.Name.name(),
          "username" => Faker.Internet.user_name(),
          "email" => Faker.Internet.email(),
          "password" => Faker.String.base64(12),
          "is_term_accepted" => true
        }
      }

      assert {:ok, %{data: data}} = Identity.register_user(req)
      assert data.id
    end
  end

  describe "add_user/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.add_user(%Request{})
      assert length(errors) > 0
    end

    test "given unauthorized requester" do
      req = %Request{
        account_id: uuid4(),
        data: %{
          "username" => Faker.Internet.user_name(),
          "role" => "developer",
          "password" => Faker.String.base64(12)
        }
      }

      assert {:error, :access_denied} = Identity.add_user(req)
    end

    test "given valid request" do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        data: %{
          "username" => Faker.Internet.user_name(),
          "role" => "developer",
          "password" => Faker.String.base64(12)
        },
        include: "api_keys"
      }

      assert {:ok, %{data: data}} = Identity.add_user(req)
      assert data.id
      assert data.username == req.data["username"]
      assert length(data.api_keys) == 2
    end
  end

  describe "update_user_info/1" do
    test "given no identifier" do
      assert {:error, %{errors: errors}} = Identity.update_user_info(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{identifier: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.update_user_info(req)
    end

    test "given unauthorize requester" do
      user = standard_user()

      req = %Request{identifier: %{"id" => user.id}}
      assert {:error, :access_denied} = Identity.update_user_info(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)

      new_name = Faker.Name.name()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => requester.id},
        data: %{"name" => new_name}
      }

      assert {:ok, %{data: data}} = Identity.update_user_info(req)
      assert data.name == new_name
    end
  end

  describe "change_default_account/1" do
    test "given no identifier" do
      assert {:error, %{errors: errors}} = Identity.change_default_account(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{
        requester_id: uuid4(),
        data: %{"id" => uuid4()}
      }

      assert {:error, :not_found} = Identity.change_default_account(req)
    end

    test "given unauthorize requester" do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        data: %{"id" => account_id}
      }

      assert {:error, :access_denied} = Identity.change_default_account(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()
      account = account(requester.id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        data: %{"id" => account.id}
      }

      assert {:ok, %{data: data}} = Identity.change_default_account(req)
      assert data.default_account_id == account.id
    end
  end

  describe "change_user_role/1" do
    test "given no identifier" do
      assert {:error, %{errors: errors}} = Identity.change_user_role(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{
        account_id: uuid4(),
        identifier: %{"id" => uuid4()},
        data: %{"value" => "manager"}
      }

      assert {:error, :not_found} = Identity.change_user_role(req)
    end

    test "given unauthorize requester" do
      requester = standard_user()

      req = %Request{
        account_id: requester.default_account_id,
        identifier: %{"id" => requester.id},
        data: %{"value" => "manager"}
      }

      assert {:error, :access_denied} = Identity.change_user_role(req)
    end

    test "given valid request" do
      requester = standard_user()
      user = managed_user(requester.default_account_id)
      client = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => user.id},
        data: %{"value" => "manager"}
      }

      assert {:ok, %{data: data}} = Identity.change_user_role(req)
      assert data.role == "manager"
    end
  end

  describe "generate_password_reset_token/1" do
    test "given no identifier" do
      assert {:error, :not_found} = Identity.generate_password_reset_token(%Request{})
    end

    test "given invalid identifier" do
      req = %Request{
        identifier: %{"id" => uuid4()}
      }

      assert {:error, :not_found} = Identity.generate_password_reset_token(req)
    end

    test "given valid username as identifier" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        client_id: client.id,
        identifier: %{"username" => requester.username}
      }

      assert {:ok, %{data: data}} = Identity.generate_password_reset_token(req)
      assert data.password_reset_token_expires_at
    end

    test "given valid id as identifier" do
      requester = standard_user()
      account_id = requester.default_account_id
      user = managed_user(account_id)
      client = standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        identifier: %{"id" => user.id}
      }

      assert {:ok, %{data: data}} = Identity.generate_password_reset_token(req)
      assert data.password_reset_token_expires_at
    end
  end

  describe "change_password/1" do
    test "given no identifier" do
      assert {:error, :not_found} = Identity.change_password(%Request{})
    end

    test "given invalid identifier" do
      req = %Request{
        requester_id: uuid4(),
        identifier: %{"id" => uuid4()},
        data: %{"new_password" => "test1234"}
      }

      assert {:error, :not_found} = Identity.change_password(req)
    end

    test "given unauthorize requester" do
      user = standard_user()

      req = %Request{
        requester_id: uuid4(),
        identifier: %{"id" => user.id},
        data: %{"new_password" => "test1234"}
      }

      assert {:error, :access_denied} = Identity.change_password(req)
    end

    test "given valid id as identifier" do
      requester = standard_user()
      user = managed_user(requester.default_account_id)
      client = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => user.id},
        data: %{"new_password" => "test1234"}
      }

      assert {:ok, %{data: data}} = Identity.change_password(req)
    end

    test "given valid reset token as identifier" do
      requester = password_reset_token(standard_user().id)
      client = system_app()

      req = %Request{
        client_id: client.id,
        identifier: %{"reset_token" => requester.password_reset_token},
        data: %{"new_password" => "test1234"}
      }

      assert {:ok, %{data: data}} = Identity.change_password(req)
    end
  end

  describe "delete_user/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.delete_user(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{identifier: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.delete_user(req)
    end

    test "given unauthorize requester" do
      user = standard_user()

      req = %Request{identifier: %{"id" => user.id}}
      assert {:error, :access_denied} = Identity.delete_user(req)
    end

    test "given valid request" do
      requester = standard_user()
      user = managed_user(requester.default_account_id)
      client = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => user.id}
      }

      assert {:ok, %{data: data}} = Identity.delete_user(req)
      assert data.id == user.id
    end
  end

  describe "list_user/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.list_user(req)
    end

    test "given valid request target live account" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      managed_user(requester.default_account_id)
      managed_user(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id
      }

      assert {:ok, %{data: data}} = Identity.list_user(req)
      assert length(data) == 2
    end

    test "given valid request target test account" do
      user = standard_user(include: "default_account")
      live_account_id = user.default_account_id
      test_account_id = user.default_account.test_account_id

      requester = managed_user(live_account_id, role: "administrator")
      client = standard_app(test_account_id)

      managed_user(test_account_id)
      managed_user(test_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: test_account_id
      }

      assert {:ok, %{data: data}} = Identity.list_user(req)
      assert length(data) == 2
    end
  end

  describe "count_user/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.count_user(req)
    end

    test "given valid request target live account" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      managed_user(requester.default_account_id)
      managed_user(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id
      }

      assert {:ok, %{data: 2}} = Identity.count_user(req)
    end

    test "given valid request target test account" do
      user = standard_user(include: "default_account")
      live_account_id = user.default_account_id
      test_account_id = user.default_account.test_account_id

      requester = managed_user(live_account_id, role: "administrator")
      client = standard_app(test_account_id)
      managed_user(test_account_id)
      managed_user(test_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: test_account_id
      }

      assert {:ok, %{data: 2}} = Identity.count_user(req)
    end
  end

  describe "get_user/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.get_user(req)
    end

    test "target non existing user" do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      managed_user(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        identifier: %{"id" => uuid4()}
      }

      assert {:error, :not_found} = Identity.get_user(req)
    end

    test "target user of another account" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      other_user = standard_user()
      target_user = managed_user(other_user.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => target_user.id}
      }

      assert {:error, :not_found} = Identity.get_user(req)
    end

    test "target user with invalid password" do
      user = standard_user()

      req = %Request{
        identifier: %{"username" => user.username, "password" => "invalid"},
        _role_: "system"
      }

      assert {:error, :not_found} = Identity.get_user(req)
    end

    test "target standard user with valid password" do
      user = standard_user()
      managed_user(user.default_account_id, username: user.username, password: "test1234")

      req = %Request{
        identifier: %{
          "type" => "standard",
          "username" => String.upcase(user.username),
          "password" => "test1234"
        },
        _role_: "system"
      }

      assert {:ok, %{data: data}} = Identity.get_user(req)
      assert data.id == user.id
    end

    test "target managed user with valid password" do
      %{default_account_id: account_id, username: username} = standard_user()
      user = managed_user(account_id, username: username, password: "test1234")

      req = %Request{
        account_id: account_id,
        identifier: %{
          "type" => "managed",
          "username" => String.upcase(user.username),
          "password" => "test1234"
        },
        _role_: "system"
      }

      assert {:ok, %{data: data}} = Identity.get_user(req)
      assert data.id == user.id
    end

    test "target standard user as requester itself" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => requester.id}
      }

      assert {:ok, %{data: data}} = Identity.get_user(req)
      assert data.id == requester.id
    end

    test "target managed user as requester itself" do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "customer")
      client = standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        identifier: %{"id" => requester.id}
      }

      assert {:ok, %{data: data}} = Identity.get_user(req)
      assert data.id == requester.id
    end

    test "target valid user" do
      requester = standard_user()
      account_id = requester.default_account_id
      user = managed_user(account_id)
      client = standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        identifier: %{"id" => user.id}
      }

      assert {:ok, %{data: data}} = Identity.get_user(req)
      assert data.id == user.id
    end

    test "target valid user with using locale" do
      requester = standard_user()
      account_id = requester.default_account_id
      user = managed_user(account_id)
      client = standard_app(account_id)
      custom_data = %{"test" => "你好"}

      req = %Request{
        client_id: client.id,
        account_id: requester.default_account_id,
        requester_id: requester.id,
        identifier: %{"id" => user.id},
        data: %{"custom_data" => custom_data},
        locale: "zh-CN"
      }

      {:ok, _} = Identity.update_user_info(req)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id,
        identifier: %{"id" => user.id},
        locale: "zh-CN"
      }

      assert {:ok, %{data: user}} = Identity.get_user(req)
      assert user.custom_data == custom_data
    end
  end

  describe "create_account/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.create_account(%Request{})
      assert length(errors) > 0
    end

    test "given unauthorized requester" do
      req = %Request{
        requester_id: uuid4(),
        data: %{
          "name" => Faker.Company.name(),
          "default_locale" => "en"
        }
      }

      assert {:error, :access_denied} = Identity.create_account(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        data: %{
          "name" => Faker.Company.name(),
          "default_locale" => "en"
        }
      }

      assert {:ok, %{data: data}} = Identity.create_account(req)
      assert data.id
      assert data.name == req.data["name"]
      assert data.default_locale == req.data["default_locale"]
    end
  end

  describe "list_account/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.list_account(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()
      account(requester.id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id
      }

      assert {:ok, %{data: data}} = Identity.list_account(req)
      assert length(data) == 2
    end
  end

  describe "get_account/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.get_account(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id
      }

      assert {:ok, %{data: data}} = Identity.get_account(req)
      assert data.id == requester.default_account_id
    end

    test "given valid request with handle" do
      user = standard_user(include: "default_account")

      req = %Request{
        _role_: "system",
        identifier: %{"handle" => user.default_account.handle}
      }

      assert {:ok, %{data: data}} = Identity.get_account(req)
      assert data.id == user.default_account_id
    end
  end

  describe "update_account_info/1" do
    test "given no identifier" do
      assert {:error, %{errors: errors}} = Identity.update_account_info(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{account_id: uuid4()}
      assert {:error, :not_found} = Identity.update_account_info(req)
    end

    test "given unauthorize requester" do
      %{default_account_id: account_id} = standard_user()

      req = %Request{account_id: account_id}
      assert {:error, :access_denied} = Identity.update_account_info(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = standard_app(requester.default_account_id)

      new_name = Faker.Company.name()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        data: %{"name" => new_name}
      }

      assert {:ok, %{data: data}} = Identity.update_account_info(req)
      assert data.name == new_name
    end
  end

  describe "close_account/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.close_account(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{identifier: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.close_account(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()
      account = account(requester.id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => account.id}
      }

      assert {:ok, %{data: data}} = Identity.close_account(req)
      assert data.id == account.id
    end
  end

  describe "get_api_key/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.get_api_key(req)
    end

    test "given valid request by admin" do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id
      }

      assert {:ok, %{data: data}} = Identity.get_api_key(req)
      assert data.account_id == account_id
      assert data.user_id == nil
      assert data.prefixed_id
    end

    test "given valid request by system" do
      user = standard_user()
      account_id = user.default_account_id

      req = %Request{
        account_id: account_id,
        identifier: %{
          "user_id" => user.id
        },
        _role_: "system"
      }

      assert {:ok, %{data: data}} = Identity.get_api_key(req)
      assert data.account_id == account_id
      assert data.user_id == user.id
      assert data.prefixed_id
    end
  end

  describe "exchange_api_key/1" do
    test "given no refresh token given" do
      client = system_app()
      req = %Request{client_id: client.id}

      assert {:error, :not_found} = Identity.exchange_api_key(req)
    end

    test "target account with no user refresh token" do
      requester = standard_user()
      client = system_app()
      %{default_account_id: target_account_id} = standard_user()
      urt = get_urt(requester.default_account_id, requester.id)

      req = %Request{
        client_id: client.id,
        account_id: target_account_id,
        identifier: %{"id" => urt.prefixed_id}
      }

      assert {:error, :not_found} = Identity.exchange_api_key(req)
    end

    test "target corresponding test account" do
      requester = standard_user(include: "default_account")
      client = system_app()
      urt = get_urt(requester.default_account_id, requester.id)
      test_account_id = requester.default_account.test_account_id

      req = %Request{
        account_id: test_account_id,
        client_id: client.id,
        identifier: %{"id" => urt.prefixed_id}
      }

      assert {:ok, %{data: data}} = Identity.exchange_api_key(req)
      assert data.prefixed_id
      assert data.account_id == test_account_id
      assert data.user_id == requester.id
    end

    test "target the same account" do
      requester = standard_user(include: "default_account")
      account_id = requester.default_account_id
      client = system_app()
      urt = get_urt(account_id, requester.id)

      req = %Request{
        account_id: account_id,
        client_id: client.id,
        identifier: %{"id" => urt.prefixed_id}
      }

      assert {:ok, %{data: data}} = Identity.exchange_api_key(req)
      assert data.prefixed_id
      assert data.id == urt.id
    end

    test "target other live account owned by the same user" do
      requester = standard_user(include: "default_account")
      account_id = requester.default_account_id
      client = system_app()
      urt = get_urt(account_id, requester.id)

      another_account = account(requester.id)

      req = %Request{
        account_id: another_account.id,
        client_id: client.id,
        identifier: %{"id" => urt.prefixed_id}
      }

      assert {:ok, %{data: data}} = Identity.exchange_api_key(req)
      assert data.id != urt.id
      assert data.prefixed_id
    end
  end

  describe "add_app/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.add_app(%Request{})
      assert length(errors) > 0
    end

    test "given unauthorized requester" do
      req = %Request{
        account_id: uuid4(),
        data: %{
          "name" => "Test"
        }
      }

      assert {:error, :access_denied} = Identity.add_app(req)
    end

    test "given valid request by system" do
      req = %Request{
        _role_: "system",
        data: %{
          "type" => "system",
          "name" => "Test"
        }
      }

      assert {:ok, _} = Identity.add_app(req)
    end

    test "given valid request by user" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        data: %{
          "name" => "Test"
        }
      }

      assert {:ok, _} = Identity.add_app(req)
    end
  end

  describe "get_app/1" do
    test "given valid request" do
      app = system_app()

      req = %Request{
        identifier: %{
          "id" => app.id
        },
        _role_: "system"
      }

      assert {:ok, %{data: data}} = Identity.get_app(req)
      assert data.id == app.id
    end
  end

  describe "list_app/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.list_app(req)
    end

    test "given valid request" do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()

      standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id
      }

      assert {:ok, %{data: data}} = Identity.list_app(req)
      assert length(data) == 2
    end
  end

  describe "count_app/1" do
    test "given unauthorized requester" do
      req = %Request{}

      assert {:error, :access_denied} = Identity.count_app(req)
    end

    test "given valid request" do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()

      standard_app(account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: account_id
      }

      assert {:ok, %{data: 2}} = Identity.count_app(req)
    end
  end

  describe "update_app/1" do
    test "given no identifier" do
      assert {:error, %{errors: errors}} = Identity.update_app(%Request{})
      assert length(errors) >= 1
    end

    test "given invalid identifier" do
      req = %Request{identifier: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.update_app(req)
    end

    test "given unauthorize requester" do
      %{default_account_id: account_id} = standard_user()
      app = standard_app(account_id)

      req = %Request{identifier: %{"id" => app.id}}
      assert {:error, :access_denied} = Identity.update_app(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()
      app = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => app.id},
        data: %{"name" => Faker.Company.name()}
      }

      assert {:ok, %{data: data}} = Identity.update_app(req)
      assert data.id == app.id
      assert data.name == req.data["name"]
    end
  end

  describe "delete_app/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Identity.delete_app(%Request{})
      assert length(errors) > 1
    end

    test "given invalid identifier" do
      req = %Request{identifier: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.delete_app(req)
    end

    test "given unauthorize requester" do
      %{default_account_id: account_id} = standard_user()
      app = standard_app(account_id)

      req = %Request{identifier: %{"id" => app.id}}
      assert {:error, :access_denied} = Identity.delete_app(req)
    end

    test "given valid request" do
      requester = standard_user()
      client = system_app()
      app = standard_app(requester.default_account_id)

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        identifier: %{"id" => app.id}
      }

      assert {:ok, %{data: data}} = Identity.delete_app(req)
      assert data.id == app.id
    end
  end
end
