defmodule FCInventory.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCInventory.{
    AddStorage,
    UpdateStorage,
    DeleteStorage,
    AddBatch,
    UpdateBatch,
    DeleteBatch,
    CreateTransaction,
    UpdateTransaction,
    DeleteTransaction,
    CreateMovement
  }

  alias FCInventory.{Storage, Batch, Transaction, Movement}
  alias FCInventory.{StorageHandler, BatchHandler, TransactionHandler, MovementHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Storage, by: :storage_id, prefix: "stock-storage-")
  identify(Batch, by: :batch_id, prefix: "stock-batch-")
  identify(Movement, by: :movement_id, prefix: "stock-movement-")
  identify(Transaction, by: :transaction_id, prefix: "stock-transaction-")

  dispatch([AddStorage, UpdateStorage, DeleteStorage], to: StorageHandler, aggregate: Storage)
  dispatch([AddBatch, UpdateBatch, DeleteBatch], to: BatchHandler, aggregate: Batch)
  dispatch([CreateTransaction], to: TransactionHandler, aggregate: Transaction)
  dispatch([CreateMovement], to: MovementHandler, aggregate: Movement)
end
