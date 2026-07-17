defmodule BioskopWeb.MovieDetailLive do
  use BioskopWeb, :live_view

  alias Bioskop.Cinema

  def mount(%{"id" => movie_id}, _session, socket) do
    movie_id = String.to_integer(movie_id)
    movie = Cinema.get_movie_with_showtimes!(movie_id)
    grouped_dates = group_showtimes_by_date(movie.showtimes)
    unique_locations = Enum.uniq_by(movie.showtimes, & &1.lokasi)

    socket =
      socket
      |> assign(:movie, movie)
      |> assign(:grouped_dates, grouped_dates)
      |> assign(:unique_locations, unique_locations)
      |> assign(:selected_date, nil)
      |> assign(:selected_location, nil)
      |> assign(:filtered_showtimes, [])

    {:ok, socket}
  end

  def handle_event("select_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    filtered = filter_showtimes(socket.assigns, date, socket.assigns.selected_location)

    {:noreply,
     socket
     |> assign(:selected_date, date)
     |> assign(:filtered_showtimes, filtered)}
  end

  def handle_event("select_location", %{"location" => location}, socket) do
    location = if location == "", do: nil, else: location
    filtered = filter_showtimes(socket.assigns, socket.assigns.selected_date, location)

    {:noreply,
     socket
     |> assign(:selected_location, location)
     |> assign(:filtered_showtimes, filtered)}
  end

  defp group_showtimes_by_date(showtimes) do
    showtimes
    |> Enum.group_by(fn s -> DateTime.to_date(s.waktu_mulai) end)
    |> Enum.sort_by(fn {date, _} -> date end)
  end

  defp filter_showtimes(assigns, date, location) do
    assigns.movie.showtimes
    |> Enum.filter(fn s ->
      date_match? =
        case date do
          nil -> true
          d -> DateTime.to_date(s.waktu_mulai) == d
        end

      location_match? =
        case location do
          nil -> true
          l -> s.lokasi == l
        end

      date_match? && location_match?
    end)
    |> Enum.sort_by(& &1.waktu_mulai)
  end

  def format_time(datetime) do
    datetime |> DateTime.to_time() |> Time.truncate(:second) |> Calendar.strftime("%H:%M")
  end

  def format_date(date) do
    Calendar.strftime(date, "%a, %d %b")
  end

  def format_price(price) do
    price
    |> Integer.to_string()
    |> String.reverse()
    |> String.codepoints()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end
end
