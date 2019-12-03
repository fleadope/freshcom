defmodule FCGoods.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCGoods.{
    AddStockable,
    UpdateStockable,
    DeleteStockable
  }

  alias FCGoods.{Stockable}
  alias FCGoods.{StockableHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Stockable, by: :stockable_id, prefix: "stockable-")

  dispatch([AddStockable, UpdateStockable, DeleteStockable], to: StockableHandler, aggregate: Stockable)
end
