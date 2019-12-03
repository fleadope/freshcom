defmodule FCInventory.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCInventory.{
    AddStorage,
    UpdateStorage,
    DeleteStorage,

    AddLocation,

    DraftTransaction,
    PrepareTransaction,
    CommitTransaction,
    UpdateTransaction,
    DeleteTransaction,
    CompleteTransactionPrep,
    CompleteTransactionCommit,

    ReserveStock,
    DecreaseReservedStock,
    CommitStock,
    AddEntry,
    UpdateEntry,
    CommitEntry,
    DeleteEntry,

    CreateMovement,
    MarkMovement
  }

  alias FCInventory.{Storage, Location, Stock, Movement, Transaction}
  alias FCInventory.{StorageHandler, LocationHandler, StockHandler, MovementHandler, TransactionHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Storage, by: :storage_id, prefix: "inventory-storage-")
  identify(Location, by: :location_id, prefix: "inventory-location-")
  identify(Stock, by: :stock_id, prefix: "inventory-stock-")
  identify(Movement, by: :movement_id, prefix: "inventory-movement-")
  identify(Transaction, by: :transaction_id, prefix: "inventory-transaction-")

  dispatch(
    [
      AddStorage,
      UpdateStorage,
      DeleteStorage
    ],
    to: StorageHandler,
    aggregate: Storage
  )

  dispatch([AddLocation], to: LocationHandler, aggregate: Location)

  dispatch(
    [
      ReserveStock,
      DecreaseReservedStock,
      CommitStock,
      AddEntry,
      UpdateEntry,
      CommitEntry,
      DeleteEntry
    ],
    to: StockHandler,
    aggregate: Stock
  )

  dispatch(
    [
      DraftTransaction,
      PrepareTransaction,
      CommitTransaction,
      UpdateTransaction,
      DeleteTransaction,
      CompleteTransactionPrep,
      CompleteTransactionCommit
    ],
    to: TransactionHandler,
    aggregate: Transaction
  )
  dispatch(
    [
      CreateMovement,
      MarkMovement
    ],
    to: MovementHandler,
    aggregate: Movement
  )
end
