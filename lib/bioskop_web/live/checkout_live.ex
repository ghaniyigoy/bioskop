defmodule BioskopWeb.CheckoutLive do
  use BioskopWeb, :live_view

  import Ecto.Query

  alias Bioskop.Repo
  alias Bioskop.Ticketing
  alias Bioskop.Ticketing.{Ticket, Transaction}
  alias Bioskop.Cinema

  @lock_duration :timer.minutes(5)

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_scope, nil)
      |> assign(:tickets, [])
      |> assign(:showtime, nil)
      |> assign(:total_price, 0)
      |> assign(:admin_fee_total, 0)
      |> assign(:grand_total, 0)
      |> assign(:loading, false)
      |> assign(:seat_names, [])

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
        [first | _] -> %{first.showtime | movie: Repo.get!(Cinema.Movie, first.showtime.movie_id)}
        [] -> nil
      end

    harga_tiket = if showtime, do: showtime.harga_tiket, else: 0
    admin_fee_per_ticket = 5_000
    ticket_count = length(tickets)
    total_price = harga_tiket * ticket_count
    admin_fee_total = admin_fee_per_ticket * ticket_count
    grand_total = total_price + admin_fee_total
    seat_names = Enum.map(tickets, & &1.nomor_kursi)

    locked_at =
      case tickets do
        [first | _] ->
          showtime_id = first.showtime_id
          seat_id = get_seat_id(showtime_id, first.nomor_kursi)

          case seat_id do
            nil -> nil
            sid -> get_locked_at_ms(showtime_id, sid)
          end

        [] ->
          nil
      end

    socket =
      if connected?(socket) and locked_at do
        socket
        |> assign(:tickets, tickets)
        |> assign(:showtime, showtime)
        |> assign(:total_price, total_price)
        |> assign(:admin_fee_total, admin_fee_total)
        |> assign(:grand_total, grand_total)
        |> assign(:seat_names, seat_names)
        |> push_event("start_countdown", %{
          locked_at: locked_at,
          lock_duration_ms: @lock_duration
        })
      else
        socket
        |> assign(:tickets, tickets)
        |> assign(:showtime, showtime)
        |> assign(:total_price, total_price)
        |> assign(:admin_fee_total, admin_fee_total)
        |> assign(:grand_total, grand_total)
        |> assign(:seat_names, seat_names)
      end

    if connected?(socket) and locked_at do
      Process.send_after(self(), :expired, @lock_duration)
    end

    {:noreply, socket}
  end

  def handle_event("pay", _, socket) do
    tickets = socket.assigns.tickets
    transactions = Enum.map(tickets, & &1.transaction)

    results =
      Enum.reduce_while(transactions, [], fn tx, acc ->
        case Ticketing.process_checkout(tx.id, :success) do
          {:ok, _} -> {:cont, acc}
          error -> {:halt, error}
        end
      end)

    case results do
      [] ->
        {:noreply,
         socket
         |> put_flash(:info, "Pembayaran berhasil!")
         |> push_navigate(
           to: ~p"/booking/success?#{[ticket_ids: Enum.map(tickets, & &1.id) |> Enum.join(",")]}"
         )}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Pembayaran gagal: #{inspect(reason)}")}
    end
  end

  def handle_event("timer_expired", _, socket) do
    expire_tickets(socket)
  end

  def handle_info(:expired, socket) do
    expire_tickets(socket)
  end

  defp expire_tickets(socket) do
    tickets = socket.assigns.tickets

    Enum.each(tickets, fn ticket ->
      case ticket.transaction do
        %Transaction{status_pembayaran: :pending} ->
          Ticketing.update_transaction(ticket.transaction, %{status_pembayaran: :expired})

          seat_id = get_seat_id(ticket.showtime_id, ticket.nomor_kursi)
          if seat_id, do: Bioskop.SeatLock.unlock_seat(ticket.showtime_id, seat_id)

        _ ->
          :ok
      end
    end)

    showtime_id =
      case tickets do
        [first | _] -> first.showtime_id
        [] -> nil
      end

    {:noreply,
     socket
     |> put_flash(:error, "Waktu pembayaran habis. Silakan pilih kursi kembali.")
     |> push_navigate(to: (showtime_id && ~p"/showtime/#{showtime_id}") || ~p"/")}
  end

  defp get_locked_at_ms(showtime_id, seat_id) do
    case Bioskop.SeatLock.get_lock_info(showtime_id, seat_id) do
      {:ok, %{locked_at: locked_at}} ->
        DateTime.to_unix(locked_at, :millisecond)

      _ ->
        nil
    end
  end

  defp get_seat_id(showtime_id, nomor_kursi) do
    seat = Repo.get_by(Cinema.Seat, showtime_id: showtime_id, nomor_kursi: nomor_kursi)
    seat && seat.id
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
