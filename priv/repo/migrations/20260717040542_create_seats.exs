defmodule Bioskop.Repo.Migrations.CreateSeats do
  use Ecto.Migration

  def change do
    create table(:seats) do
      add :showtime_id, references(:showtimes, on_delete: :delete_all), null: false
      add :nomor_kursi, :string, null: false
      add :status, :string, null: false, default: "available"

      timestamps()
    end

    create index(:seats, [:showtime_id])
    create unique_index(:seats, [:showtime_id, :nomor_kursi])
  end
end
