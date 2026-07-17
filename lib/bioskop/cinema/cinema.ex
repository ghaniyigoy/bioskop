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

  def get_movie_with_showtimes!(id) do
    Repo.one!(
      from m in Movie,
        where: m.id == ^id,
        preload: [showtimes: ^from(s in Showtime, order_by: s.waktu_mulai)]
    )
  end

  def list_movies_now_showing do
    today = Date.utc_today()

    Repo.all(
      from m in Movie,
        join: s in Showtime,
        on: s.movie_id == m.id,
        where: is_nil(m.tanggal_rilis) or m.tanggal_rilis <= ^today,
        preload: [showtimes: ^from(s in Showtime, order_by: s.waktu_mulai)],
        distinct: m.id,
        order_by: m.judul
    )
  end

  def list_movies_coming_soon do
    today = Date.utc_today()

    Repo.all(
      from m in Movie,
        where: m.tanggal_rilis > ^today and not is_nil(m.tanggal_rilis),
        order_by: m.tanggal_rilis
    )
  end

  def create_movie(attrs \\ %{}) do
    %Movie{}
    |> Movie.changeset(attrs)
    |> Repo.insert()
  end

  def change_movie(%Movie{} = movie, attrs \\ %{}) do
    Movie.changeset(movie, attrs)
  end

  def update_movie(%Movie{} = movie, attrs) do
    movie
    |> Movie.changeset(attrs)
    |> Repo.update()
  end

  def delete_movie(%Movie{} = movie) do
    Repo.delete(movie)
  end

  # Showtimes

  def list_showtimes do
    Repo.all(Showtime)
  end

  def list_showtimes_with_movies do
    Repo.all(from s in Showtime, preload: [:movie], order_by: s.waktu_mulai)
  end

  def get_showtime!(id), do: Repo.get!(Showtime, id)

  def create_showtime(attrs \\ %{}) do
    %Showtime{}
    |> Showtime.changeset(attrs)
    |> Repo.insert()
  end

  def change_showtime(%Showtime{} = showtime, attrs \\ %{}) do
    Showtime.changeset(showtime, attrs)
  end

  def update_showtime(%Showtime{} = showtime, attrs) do
    showtime
    |> Showtime.changeset(attrs)
    |> Repo.update()
  end

  def delete_showtime(%Showtime{} = showtime) do
    Repo.delete(showtime)
  end

  # Seats

  def list_seats do
    Repo.all(Seat)
  end

  def get_seat!(id), do: Repo.get!(Seat, id)

  def list_seats_by_showtime(showtime_id) do
    Repo.all(
      from s in Seat,
        where: s.showtime_id == ^showtime_id,
        order_by: s.nomor_kursi
    )
  end

  def get_showtime_with_seats!(showtime_id) do
    Repo.one!(
      from s in Showtime,
        where: s.id == ^showtime_id,
        preload: [
          :movie,
          seats: ^from(seat in Seat, order_by: seat.nomor_kursi)
        ]
    )
  end

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
