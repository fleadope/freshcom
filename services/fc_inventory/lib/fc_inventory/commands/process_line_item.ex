defmodule FCInventory.ProcessLineItem do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :status, String.t()
    field :quantity, Decimal.t()
  end

  @valid_statuses ["reserving", "partially_reserved", "reserved", "none_reserved"]

  validates :movement_id, presence: true, uuid: true
  validates :stockable_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: @valid_statuses
end
