defmodule Freshcom.Stockable do
  use Freshcom.Projection
  alias Freshcom.Account

  schema "stockables" do
    field :avatar_id, UUID

    field :status, :string
    field :number, :string
    field :barcode, :string

    field :name, :string
    field :label, :string
    field :print_name, :string
    field :unit_of_measure, :string
    field :specification, :string

    field :variable_weight, :boolean
    field :weight, :decimal
    field :weight_unit, :string

    field :storage_type, :string
    field :storage_size, :integer
    field :storage_description, :string
    field :stackable, :boolean

    field :width, :decimal
    field :length, :decimal
    field :height, :decimal
    field :dimension_unit, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map
    field :translations, :map

    timestamps()

    belongs_to :account, Account
  end

  @type t :: Ecto.Schema.t()
end
