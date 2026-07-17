defmodule Bioskop.Ticketing.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :nomor_kursi, :string
    field :kode_booking, :string

    belongs_to :user, Bioskop.Accounts.User
    belongs_to :showtime, Bioskop.Cinema.Showtime
    has_one :transaction, Bioskop.Ticketing.Transaction

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:user_id, :showtime_id, :nomor_kursi, :kode_booking])
    |> validate_required([:user_id, :showtime_id, :nomor_kursi, :kode_booking])
    |> unique_constraint(:kode_booking)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:showtime_id)
  end
end
