defmodule Bioskop.Ticketing.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :total_harga, :integer
    field :status_pembayaran, Ecto.Enum, values: [:pending, :success, :expired], default: :pending

    belongs_to :ticket, Bioskop.Ticketing.Ticket

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:total_harga, :status_pembayaran])
    |> validate_required([:total_harga, :status_pembayaran])
    |> validate_inclusion(:status_pembayaran, [:pending, :success, :expired])
    |> validate_number(:total_harga, greater_than: 0)
  end
end
