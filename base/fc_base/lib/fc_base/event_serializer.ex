defmodule FCBase.EventSerializer do
  @moduledoc """
  A serializer that uses the JSON format and Jason library.
  """

  alias Commanded.EventStore.TypeProvider
  alias Commanded.Serialization.JsonDecoder

  @doc """
  Serialize given term to JSON binary data.
  """
  def serialize(term) do
    Jason.encode!(term)
  end

  @doc """
  Deserialize given JSON binary data to the expected type.
  """
  def deserialize(binary, config \\ []) do
    {type, opts} =
      case Keyword.get(config, :type) do
        nil -> {nil, %{}}
        type -> {TypeProvider.to_struct(type), %{keys: :strings}}
      end

    binary
    |> Jason.decode!(opts)
    |> to_struct(type)
    |> JsonDecoder.decode()
  end

  defp to_struct(data, nil), do: data
  defp to_struct(data, struct) do
    data = FCSupport.Normalization.atomize_keys(data)
    struct(struct, data)
  end
end
