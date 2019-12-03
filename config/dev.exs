use Mix.Config

config :logger, level: :warn

config :eventstore, EventStore.Storage,
<<<<<<< HEAD
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_USERNAME"),
  port: System.get_env("DB_PORT"),
=======
  serializer: FCBase.EventSerializer,
  username: System.get_env("EVENTSTORE_DB_USERNAME"),
  password: System.get_env("EVENTSTORE_DB_PASSWORD"),
>>>>>>> ae0e0ff75b3d3201ec80f20e7523cd9b522fe938
  database: "freshcom_eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :fc_state_storage, :adapter, FCStateStorage.RedisAdapter
config :fc_state_storage, :redis, System.get_env("REDIS_URL")

config :freshcom, Freshcom.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "freshcom_projections_dev",
  hostname: "localhost",
<<<<<<< HEAD
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_USERNAME"),
  port: System.get_env("DB_PORT"),
=======
  username: System.get_env("PROJECTION_DB_USERNAME"),
  password: System.get_env("PROJECTION_DB_PASSWORD"),
>>>>>>> ae0e0ff75b3d3201ec80f20e7523cd9b522fe938
  pool_size: 10
