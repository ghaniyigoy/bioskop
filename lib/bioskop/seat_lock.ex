defmodule Bioskop.SeatLock do
  use GenServer

  alias Bioskop.Repo
  alias Bioskop.Cinema.Seat

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.merge([name: __MODULE__], opts))
  end

  def lock_seat(server \\ __MODULE__, showtime_id, seat_id) do
    GenServer.call(server, {:lock_seat, showtime_id, seat_id}, :timer.seconds(15))
  end

  def unlock_seat(server \\ __MODULE__, showtime_id, seat_id) do
    GenServer.call(server, {:unlock_seat, showtime_id, seat_id})
  end

  def confirm_booking(server \\ __MODULE__, showtime_id, seat_id) do
    GenServer.call(server, {:confirm_booking, showtime_id, seat_id})
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lock_seat, showtime_id, seat_id}, _from, state) do
    key = {showtime_id, seat_id}

    if Map.has_key?(state, key) do
      {:reply, {:error, :already_locked}, state}
    else
      seat = Repo.get(Seat, seat_id)

      case seat do
        %Seat{status: :available} ->
          case Repo.update(Ecto.Changeset.change(seat, status: :locked)) do
            {:ok, _updated_seat} ->
              timer_ref =
                Process.send_after(
                  self(),
                  {:release_lock, showtime_id, seat_id},
                  :timer.minutes(5)
                )

              new_state =
                Map.put(state, key, %{
                  locked_at: DateTime.utc_now(),
                  timer_ref: timer_ref
                })

              {:reply, :ok, new_state}

            {:error, changeset} ->
              {:reply, {:error, {:db_error, changeset}}, state}
          end

        %Seat{status: :locked} ->
          {:reply, {:error, :already_locked}, state}

        %Seat{status: :booked} ->
          {:reply, {:error, :already_booked}, state}

        nil ->
          {:reply, {:error, :not_found}, state}
      end
    end
  end

  @impl true
  def handle_call({:unlock_seat, showtime_id, seat_id}, _from, state) do
    key = {showtime_id, seat_id}

    case state do
      %{^key => %{timer_ref: timer_ref}} ->
        Process.cancel_timer(timer_ref)

        with %Seat{status: :locked} = seat <- Repo.get(Seat, seat_id) do
          Repo.update(Ecto.Changeset.change(seat, status: :available))
        end

        {:reply, :ok, Map.delete(state, key)}

      _ ->
        {:reply, {:error, :not_locked}, state}
    end
  end

  @impl true
  def handle_call({:confirm_booking, showtime_id, seat_id}, _from, state) do
    key = {showtime_id, seat_id}

    case state do
      %{^key => %{timer_ref: timer_ref}} ->
        Process.cancel_timer(timer_ref)

        seat = Repo.get(Seat, seat_id)

        case seat do
          %Seat{status: :locked} ->
            case Repo.update(Ecto.Changeset.change(seat, status: :booked)) do
              {:ok, _updated_seat} ->
                {:reply, :ok, Map.delete(state, key)}

              {:error, changeset} ->
                {:reply, {:error, {:db_error, changeset}}, state}
            end

          %Seat{status: :booked} ->
            {:reply, {:error, :already_booked}, Map.delete(state, key)}

          nil ->
            {:reply, {:error, :not_found}, state}
        end

      _ ->
        {:reply, {:error, :not_locked}, state}
    end
  end

  @impl true
  def handle_info({:release_lock, showtime_id, seat_id}, state) do
    key = {showtime_id, seat_id}

    with %Seat{status: :locked} = seat <- Repo.get(Seat, seat_id) do
      Repo.update(Ecto.Changeset.change(seat, status: :available))
    end

    {:noreply, Map.delete(state, key)}
  end
end
