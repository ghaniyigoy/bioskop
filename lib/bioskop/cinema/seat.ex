defmodule Bioskop.Cinema.Seat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seats" do
    field :nomor_kursi, :string
    field :status, Ecto.Enum, values: [:available, :locked, :booked], default: :available

    belongs_to :showtime, Bioskop.Cinema.Showtime

    timestamps()
  end

  def changeset(seat, attrs) do
    seat
    |> cast(attrs, [:nomor_kursi, :status])
    |> validate_required([:nomor_kursi, :status])
    |> validate_inclusion(:status, [:available, :locked, :booked])
    |> unique_constraint(:nomor_kursi, name: :seats_showtime_id_nomor_kursi_index)
  end
end
