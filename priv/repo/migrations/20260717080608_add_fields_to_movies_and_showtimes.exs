defmodule Bioskop.Repo.Migrations.AddFieldsToMoviesAndShowtimes do
  use Ecto.Migration

  def change do
    alter table(:movies) do
      add :rating_umur, :string, default: "SU"
      add :genre, :string
      add :tanggal_rilis, :date
    end

    alter table(:showtimes) do
      add :lokasi, :string
    end
  end
end
