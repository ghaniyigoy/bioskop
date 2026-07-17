defmodule Bioskop.Cinema.Movie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "movies" do
    field :judul, :string
    field :sinopsis, :string
    field :durasi, :integer
    field :poster_url, :string
    field :rating_umur, :string, default: "SU"
    field :genre, :string
    field :tanggal_rilis, :date

    has_many :showtimes, Bioskop.Cinema.Showtime

    timestamps()
  end

  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [:judul, :sinopsis, :durasi, :poster_url, :rating_umur, :genre, :tanggal_rilis])
    |> validate_required([:judul, :durasi])
    |> validate_number(:durasi, greater_than: 0)
  end
end
