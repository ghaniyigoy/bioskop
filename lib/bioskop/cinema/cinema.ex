defmodule Bioskop.Cinema do
  @moduledoc """
  The Cinema context manages movies, showtimes, and seats.
  """

  import Ecto.Query, warn: false
  alias Bioskop.Repo
  alias Bioskop.Cinema.{Movie, Showtime, Seat}

  # Movies

  def list_movies do
    Repo.all(Movie)
  end

  def get_movie!(id), do: Repo.get!(Movie, id)

  def create_movie(attrs \\ %{}) do
    %Movie{}
    |> Movie.changeset(attrs)
    |> Repo.insert()
  end

  # Showtimes

  def list_showtimes do
    Repo.all(Showtime)
  end

  def get_showtime!(id), do: Repo.get!(Showtime, id)

  def create_showtime(attrs \\ %{}) do
    %Showtime{}
    |> Showtime.changeset(attrs)
    |> Repo.insert()
  end

  # Seats

  def list_seats do
    Repo.all(Seat)
  end

  def get_seat!(id), do: Repo.get!(Seat, id)

  def create_seat(attrs \\ %{}) do
    %Seat{}
    |> Seat.changeset(attrs)
    |> Repo.insert()
  end

  def update_seat(%Seat{} = seat, attrs) do
    seat
    |> Seat.changeset(attrs)
    |> Repo.update()
  end
end
