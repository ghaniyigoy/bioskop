defmodule Bioskop.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :showtime_id, references(:showtimes, on_delete: :nothing), null: false
      add :nomor_kursi, :string, null: false
      add :kode_booking, :string, null: false

      timestamps()
    end

    create index(:tickets, [:user_id])
    create index(:tickets, [:showtime_id])
    create unique_index(:tickets, [:kode_booking])
  end
end
