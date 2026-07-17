defmodule Bioskop.Cinema.Showtime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "showtimes" do
    field :nama_studio, :string
    field :waktu_mulai, :utc_datetime
    field :harga_tiket, :integer

    belongs_to :movie, Bioskop.Cinema.Movie
    has_many :seats, Bioskop.Cinema.Seat
    has_many :tickets, Bioskop.Ticketing.Ticket

    timestamps()
  end

  def changeset(showtime, attrs) do
    showtime
    |> cast(attrs, [:movie_id, :nama_studio, :waktu_mulai, :harga_tiket])
    |> validate_required([:movie_id, :nama_studio, :waktu_mulai, :harga_tiket])
    |> validate_number(:harga_tiket, greater_than: 0)
    |> foreign_key_constraint(:movie_id)
  end
end
