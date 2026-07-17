defmodule Bioskop.Repo.Migrations.CreateShowtimes do
  use Ecto.Migration

  def change do
    create table(:showtimes) do
      add :movie_id, references(:movies, on_delete: :delete_all), null: false
      add :nama_studio, :string, null: false
      add :waktu_mulai, :utc_datetime, null: false
      add :harga_tiket, :integer, null: false

      timestamps()
    end

    create index(:showtimes, [:movie_id])
  end
end
