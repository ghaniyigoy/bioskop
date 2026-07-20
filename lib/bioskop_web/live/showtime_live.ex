defmodule BioskopWeb.ShowtimeLive do
  use BioskopWeb, :live_view

  alias Bioskop.Cinema
  alias Bioskop.Cinema.Seat
  alias Bioskop.Ticketing

  def mount(%{"id" => showtime_id}, _session, socket) do
    showtime_id = String.to_integer(showtime_id)
    showtime = Cinema.get_showtime_with_seats!(showtime_id)
    seats = showtime.seats

    if connected?(socket) do
      BioskopWeb.Endpoint.subscribe("showtime:#{showtime_id}")
    end

    socket =
      socket
      |> assign(:current_scope, nil)
      |> assign(:showtime, showtime)
      |> assign(:showtime_id, showtime_id)
      |> assign(:selected_seats, MapSet.new())
      |> assign(:grouped_seats, group_seats_by_row(seats))

    {:ok, socket}
  end

  def handle_event("select_seat", %{"seat-id" => seat_id_str}, socket) do
    seat_id = String.to_integer(seat_id_str)
    selected = socket.assigns.selected_seats

    selected =
      if MapSet.member?(selected, seat_id) do
        MapSet.delete(selected, seat_id)
      else
        seats_map = seats_to_map(socket.assigns.grouped_seats)

        case Map.get(seats_map, seat_id) do
          %Seat{status: :available} -> MapSet.put(selected, seat_id)
          _ -> selected
        end
      end

    {:noreply, assign(socket, :selected_seats, selected)}
  end

  def handle_event("pesan_tiket", _, socket) do
    %{
      selected_seats: selected,
      grouped_seats: grouped,
      showtime_id: showtime_id,
      showtime: showtime
    } =
      socket.assigns

    seats_map = seats_to_map(grouped)
    selected_seats = Enum.map(MapSet.to_list(selected), fn id -> Map.get(seats_map, id) end)
    seat_ids = Enum.map(selected_seats, & &1.id)
    seat_nomor = Enum.map(selected_seats, & &1.nomor_kursi)

    lock_results =
      Enum.map(seat_ids, fn seat_id ->
        Bioskop.SeatLock.lock_seat(showtime_id, seat_id)
      end)

    if Enum.all?(lock_results, &(&1 == :ok)) do
      case Ticketing.create_booking(1, showtime_id, seat_nomor, showtime.harga_tiket) do
        {:ok, tickets, _transactions} ->
          ticket_ids_str = Enum.map(tickets, & &1.id) |> Enum.join(",")

          {:noreply,
           socket
           |> assign(:selected_seats, MapSet.new())
           |> push_navigate(to: ~p"/checkout?ticket_ids=#{ticket_ids_str}")}

        {:error, reason} ->
          Enum.each(seat_ids, fn seat_id ->
            Bioskop.SeatLock.unlock_seat(showtime_id, seat_id)
          end)

          {:noreply,
           socket
           |> put_flash(:error, "Gagal memproses booking: #{inspect(reason)}")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Beberapa kursi tidak dapat dikunci. Silakan coba lagi.")}
    end
  end

  def handle_info({:seat_updated, updated_seat}, socket) do
    grouped = update_seat_in_group(socket.assigns.grouped_seats, updated_seat)
    {:noreply, assign(socket, :grouped_seats, grouped)}
  end

  defp group_seats_by_row(seats) do
    seats
    |> Enum.group_by(fn seat -> String.first(seat.nomor_kursi) end)
    |> Enum.sort_by(fn {row, _} -> row end)
    |> Enum.map(fn {row, row_seats} ->
      {row, Enum.sort_by(row_seats, &parse_seat_number/1)}
    end)
  end

  defp parse_seat_number(%Seat{nomor_kursi: nomor}) do
    nomor |> String.slice(1..-1//1) |> String.to_integer()
  end

  defp update_seat_in_group(grouped, updated_seat) do
    grouped
    |> Enum.map(fn {row, seats} ->
      {row,
       Enum.map(seats, fn
         %Seat{id: id} = _seat when id == updated_seat.id -> updated_seat
         seat -> seat
       end)}
    end)
  end

  defp seats_to_map(grouped) do
    grouped
    |> Enum.flat_map(fn {_row, seats} -> seats end)
    |> Map.new(fn seat -> {seat.id, seat} end)
  end

  @doc false
  def format_price(price) do
    price
    |> Integer.to_string()
    |> String.reverse()
    |> String.codepoints()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  def seat_status_class(%Seat{status: status}, selected_seats, seat_id) do
    cond do
      MapSet.member?(selected_seats, seat_id) ->
        "bg-primary text-primary-content border-primary shadow-md shadow-primary/30 scale-105"

      status == :booked ->
        "bg-error/15 border-error/30 text-error/60 cursor-not-allowed opacity-50"

      status == :locked ->
        "bg-warning/20 border-warning/40 text-warning/60 animate-pulse cursor-not-allowed"

      status == :available ->
        "bg-success/15 border-success/30 text-success/70 hover:bg-success/25 hover:border-success/50 hover:scale-110 hover:shadow-md hover:shadow-success/20 cursor-pointer"
    end
  end
end
