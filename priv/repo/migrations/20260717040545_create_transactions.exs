defmodule Bioskop.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :ticket_id, references(:tickets, on_delete: :delete_all), null: false
      add :total_harga, :integer, null: false
      add :status_pembayaran, :string, null: false, default: "pending"

      timestamps()
    end

    create unique_index(:transactions, [:ticket_id])
  end
end
