defmodule Bioskop.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :judul, :string, null: false
      add :sinopsis, :text
      add :durasi, :integer
      add :poster_url, :string

      timestamps()
    end
  end
end
