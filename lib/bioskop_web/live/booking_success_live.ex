defmodule BioskopWeb.BookingSuccessLive do
  use BioskopWeb, :live_view

  import Ecto.Query

  alias Bioskop.Repo
  alias Bioskop.Ticketing.Ticket

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:tickets, [])
      |> assign(:showtime, nil)
      |> assign(:seat_names, [])
      |> assign(:qr_svg, nil)
      |> assign(:kode_booking, nil)

    {:ok, socket}
  end

  def handle_params(%{"ticket_ids" => ids}, _uri, socket) do
    tickets =
      ids
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_integer/1)
      |> then(fn ids ->
        Repo.all(from(t in Ticket, where: t.id in ^ids, preload: [:showtime, :transaction]))
      end)

    showtime =
      case tickets do
        [first | _] ->
          showtime = first.showtime
          %{showtime | movie: Repo.get!(Bioskop.Cinema.Movie, showtime.movie_id)}

        [] ->
          nil
      end

    seat_names = Enum.map(tickets, & &1.nomor_kursi)

    kode_booking =
      case tickets do
        [first | _] -> first.kode_booking
        [] -> nil
      end

    qr_svg =
      if kode_booking do
        EQRCode.encode(kode_booking)
        |> EQRCode.svg(width: 180)
      end

    {:noreply,
     socket
     |> assign(:tickets, tickets)
     |> assign(:showtime, showtime)
     |> assign(:seat_names, seat_names)
     |> assign(:kode_booking, kode_booking)
     |> assign(:qr_svg, qr_svg)}
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
