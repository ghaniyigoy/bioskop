import Ecto.Query, warn: false

alias Bioskop.Repo
alias Bioskop.Accounts.User
alias Bioskop.Cinema.{Movie, Showtime, Seat}
alias Bioskop.Ticketing.{Ticket, Transaction}

# Clean existing data
Repo.delete_all(Transaction)
Repo.delete_all(Ticket)
Repo.delete_all(Seat)
Repo.delete_all(Showtime)
Repo.delete_all(Movie)
Repo.delete_all(User)

# === Users ===
%User{nama: "Andi Pratama", email: "andi@example.com"} |> Repo.insert!()
%User{nama: "Siti Nurhaliza", email: "siti@example.com"} |> Repo.insert!()
%User{nama: "Budi Santoso", email: "budi@example.com"} |> Repo.insert!()

# === Movies (Now Showing) ===
pengabdi =
  %Movie{
    judul: "Pengabdi Setan 2: Communion",
    sinopsis:
      "Setelah peristiwa mengerikan di rumah susun, Rini dan keluarganya pindah ke rumah baru. Namun, teror yang lebih menakutkan mulai mengintai mereka.",
    durasi: 119,
    genre: "Horor",
    rating_umur: "17+",
    poster_url: "https://image.tmdb.org/t/p/w500/qyPp8M10k4EyN2LnG2rnEFV6uph.jpg"
  }
  |> Repo.insert!()

top_gun =
  %Movie{
    judul: "Top Gun: Maverick",
    sinopsis:
      "Setelah lebih dari 30 tahun mengabdi sebagai pilot angkatan laut, Pete 'Maverick' Mitchell kembali untuk melatih sekelompok pilot muda untuk misi berbahaya.",
    durasi: 131,
    genre: "Aksi",
    rating_umur: "13+",
    poster_url: "https://image.tmdb.org/t/p/w500/62HCnUTPiJgFJAGzLv0wJ5G8OXS.jpg"
  }
  |> Repo.insert!()

spiderman =
  %Movie{
    judul: "Spider-Man: No Way Home",
    sinopsis:
      "Setelah identitas Spider-Man terbuka, Peter Parker meminta bantuan Doctor Strange untuk mengembalikan rahasianya. Namun, hal itu justru membuka portal ke multiverse.",
    durasi: 148,
    genre: "Aksi, Petualangan",
    rating_umur: "13+",
    poster_url: "https://image.tmdb.org/t/p/w500/uJYYizSuA9Y3Qj1W4UqK8V8J8z.jpg"
  }
  |> Repo.insert!()

oppenheimer =
  %Movie{
    judul: "Oppenheimer",
    sinopsis:
      "Kisah ilmuwan J. Robert Oppenheimer dan perannya dalam pengembangan bom atom yang mengubah sejarah dunia.",
    durasi: 180,
    genre: "Sejarah, Drama",
    rating_umur: "17+",
    poster_url: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg"
  }
  |> Repo.insert!()

dune =
  %Movie{
    judul: "Dune: Part Two",
    sinopsis:
      "Paul Atreides melanjutkan perjalanannya menyatukan suku Fremen melawan Kekaisaran yang menindas.",
    durasi: 166,
    genre: "Fiksi Ilmiah, Petualangan",
    rating_umur: "13+",
    poster_url: "https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg"
  }
  |> Repo.insert!()

inside_out =
  %Movie{
    judul: "Inside Out 2",
    sinopsis:
      "Riley kini memasuki usia remaja dan markas besar pikirannya kedatangan emosi baru yang membuat suasana semakin kacau.",
    durasi: 100,
    genre: "Animasi, Keluarga",
    rating_umur: "SU",
    poster_url: "https://image.tmdb.org/t/p/w500/vpnVM9B6NMtQk1DqE3NxWnTqTg.jpg"
  }
  |> Repo.insert!()

# === Movies (Coming Soon) ===
tanggal_besok = Date.utc_today() |> Date.add(14)

%Movie{
  judul: "Gladiator 2",
  sinopsis: "Lucius, pewaris Roma, kembali ke Colosseum untuk membalaskan dendam keluarganya.",
  durasi: 148,
  genre: "Aksi, Sejarah",
  rating_umur: "17+",
  poster_url: "https://image.tmdb.org/t/p/w500/2cxhvjR5aM7pRmKsvI25jWFWVj.jpg",
  tanggal_rilis: tanggal_besok
}
|> Repo.insert!()

%Movie{
  judul: "The Batman 2",
  sinopsis: "Batman menghadapi ancaman baru yang menguji batas keadilan di Gotham City.",
  durasi: 176,
  genre: "Aksi, Kriminal",
  rating_umur: "13+",
  poster_url: "https://image.tmdb.org/t/p/w500/oQxqT8S0GxS6zM4y0qZd4M0K1B.jpg",
  tanggal_rilis: Date.add(tanggal_besok, 30)
}
|> Repo.insert!()

%Movie{
  judul: "Frozen 3",
  sinopsis: "Elsa dan Anna memulai petualangan baru melampaui hutan ajaib Arendelle.",
  durasi: 105,
  genre: "Animasi, Musikal",
  rating_umur: "SU",
  poster_url: "https://image.tmdb.org/t/p/w500/xN4UJ1Y2b4K3Z7cF5v8W0mL9aR.jpg",
  tanggal_rilis: Date.add(tanggal_besok, 60)
}
|> Repo.insert!()

# === Showtimes ===
now_showing_movies = [pengabdi, top_gun, spiderman, oppenheimer, dune, inside_out]

locations = ["CGV Grand Indonesia", "XXI Plaza Senayan", "CGV Pacific Place", "XXI Pondok Indah"]

now = DateTime.utc_now()
base_time = %{now | hour: 10, minute: 0, second: 0} |> DateTime.truncate(:second)

showtime_slots = [
  {10, 30},
  {13, 0},
  {15, 45},
  {18, 30},
  {20, 15}
]

studios = ["1", "2", "3", "4", "5"]

rows = ["A", "B", "C", "D", "E", "F", "G", "H"]
seats_per_row = 10

Enum.each(now_showing_movies, fn movie ->
  Enum.each(0..2, fn day_offset ->
    date = DateTime.add(base_time, day_offset * 86_400, :second)

    Enum.each(showtime_slots, fn {hour, min} ->
      waktu_mulai = %{date | hour: hour, minute: min, second: 0} |> DateTime.truncate(:second)
      studio = Enum.random(studios)
      lokasi = Enum.random(locations)
      harga = Enum.random([35_000, 40_000, 45_000, 50_000, 55_000])

      showtime =
        %Showtime{
          movie_id: movie.id,
          nama_studio: studio,
          waktu_mulai: waktu_mulai,
          harga_tiket: harga,
          lokasi: lokasi
        }
        |> Repo.insert!()

      # Create seats for each showtime
      Enum.each(rows, fn row ->
        Enum.each(1..seats_per_row, fn seat_num ->
          nomor = "#{row}#{seat_num}"

          %Seat{
            showtime_id: showtime.id,
            nomor_kursi: nomor,
            status: :available
          }
          |> Repo.insert!()
        end)
      end)
    end)
  end)
end)
