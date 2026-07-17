defmodule Bioskop.Ticketing do
  @moduledoc """
  The Ticketing context manages tickets and transactions.
  """

  import Ecto.Query, warn: false
  alias Bioskop.Repo
  alias Bioskop.Ticketing.{Ticket, Transaction}
  alias Bioskop.Cinema.Seat
  alias Ecto.Multi

  # Tickets

  def list_tickets do
    Repo.all(Ticket)
  end

  def get_ticket!(id), do: Repo.get!(Ticket, id)

  def create_ticket(attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  # Transactions

  def list_transactions do
    Repo.all(Transaction)
  end

  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  # Checkout / Payment

  @doc """
  Memproses checkout (pembayaran) untuk sebuah transaksi secara atomik.

  Simulasi pembayaran:
    - `:success` → update atomik: transaction `:pending` → `:success`, seat `:locked` → `:booked`
    - `:failure` → tidak ada perubahan data, return `{:error, :payment_failed}`

  Menggunakan `Ecto.Multi` untuk memastikan perubahan transaction dan seat
  terjadi bersamaan (atomic).
  """
  def process_checkout(transaction_id, payment_result \\ :success)

  def process_checkout(_transaction_id, :failure) do
    {:error, :payment_failed}
  end

  def process_checkout(transaction_id, :success) do
    with {:ok, transaction, ticket, seat} <- load_checkout_deps(transaction_id) do
      do_atomic_checkout(transaction, seat, ticket.showtime_id)
    end
  end

  defp load_checkout_deps(transaction_id) do
    transaction = Repo.get(Transaction, transaction_id)

    case transaction do
      %Transaction{status_pembayaran: :pending, ticket_id: ticket_id} ->
        ticket = Repo.get(Ticket, ticket_id)

        case ticket do
          %Ticket{showtime_id: showtime_id, nomor_kursi: nomor_kursi} ->
            seat = Repo.get_by(Seat, showtime_id: showtime_id, nomor_kursi: nomor_kursi)

            case seat do
              %Seat{status: :locked} ->
                {:ok, transaction, ticket, seat}

              %Seat{status: status} ->
                {:error, {:seat_invalid_status, status}}

              nil ->
                {:error, :seat_not_found}
            end

          nil ->
            {:error, :ticket_not_found}
        end

      %Transaction{status_pembayaran: :success} ->
        {:error, :already_paid}

      %Transaction{status_pembayaran: :expired} ->
        {:error, :transaction_expired}

      nil ->
        {:error, :transaction_not_found}
    end
  end

  defp do_atomic_checkout(transaction, seat, showtime_id) do
    result =
      Multi.new()
      |> Multi.update(
        :transaction,
        Transaction.changeset(transaction, %{status_pembayaran: :success})
      )
      |> Multi.update(:seat, Seat.changeset(seat, %{status: :booked}))
      |> Repo.transaction()

    with {:ok, %{seat: updated_seat}} <- result do
      Bioskop.SeatLock.confirm_booking(showtime_id, updated_seat.id)
    end

    result
  end
end
