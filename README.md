# CineReserve — Bioskop

Sistem pemesanan tiket bioskop real-time berbasis Elixir & Phoenix Framework.

## Prerequisites

- Elixir ~> 1.17
- PostgreSQL (user: `postgres`, password: sesuaikan di `config/dev.exs`)

## Setup

```bash
# Install dependencies & setup database
mix setup

# (Opsional) Isi data contoh
mix run priv/repo/seeds.exs

# Jalankan server
mix phx.server
```

Kunjungi [`localhost:4000`](http://localhost:4000) dari browser.

## Routes

| Path | Description |
|---|---|
| `GET /` | Halaman utama — katalog film (Now Showing + Coming Soon) |
| `GET /movies/:id` | Detail film & pilih jadwal tayang |
| `GET /showtime/:id` | Pilih kursi interaktif & pesan tiket |
| `GET /checkout?ticket_ids=...` | Checkout + countdown timer 5 menit |
| `GET /booking/success?ticket_ids=...` | Halaman sukses booking + QR Code e-tiket |
| `GET /admin/movies` | **Admin** — Kelola Film (CRUD) |
| `GET /admin/showtimes` | **Admin** — Kelola Jadwal Tayang |

## Halaman Utama (`/`)

- **Now Showing**: Grid card film dengan poster, rating umur, durasi, genre, dan tombol "Beli Tiket"
- **Coming Soon**: Grid card dengan efek opacity, menampilkan tanggal rilis
- **Navbar**: Logo CineReserve, navigasi, search bar, theme toggle

## Detail Film (`/movies/:id`)

- Layout 2 kolom (desktop): kiri poster + info film, kanan pemilihan jadwal
- **Pilih Tanggal**: Tombol tab horizontal per tanggal tayang
- **Pilih Lokasi**: Filter berdasarkan bioskop (CGV, XXI, dll)
- **Jam Tayang**: Daftar showtime yang bisa diklik → navigasi ke halaman pilih kursi

## Checkout (`/checkout?ticket_ids=...`)

- Load data tiket dari DB beserta detail film, studio, jam tayang
- Countdown timer real-time 5 menit via JS Hook + safety net `Process.send_after`
- Banner merah ketika < 60 detik
- Tombol Bayar → proses atomik via `Ecto.Multi` → redirect ke halaman sukses
- Timer expired → unlock kursi & redirect ke halaman showtime

## Sukses Booking (`/booking/success?ticket_ids=...`)

- Ikon centang hijau + "Pembayaran Berhasil!"
- Kode booking (monospace besar) + QR Code SVG via `eqrcode`
- Ringkasan tiket: film, studio, jam tayang, lokasi, kursi
- Daftar per kursi: nomor kursi, kode_booking, status "Lunas", total harga
- Tombol "Kembali ke Beranda"

## Pilih Kursi (`/showtime/:id`)

- Peta kursi interaktif dengan status real-time (PubSub)
- Warna: hijau (tersedia), biru (dipilih), kuning (dipesan/locked), merah (terjual)
- Ringkasan: jumlah kursi dipilih + total harga
- 5 menit lock timer via SeatLock GenServer

## Database Schema

### `users`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| nama | string | required |
| email | string | required, unique |

### `movies`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| judul | string | required |
| sinopsis | text | |
| durasi | integer | menit, required |
| poster_url | string | |
| rating_umur | string | e.g. "SU", "13+", "17+" |
| genre | string | e.g. "Aksi, Petualangan" |
| tanggal_rilis | date | untuk film coming soon |

### `showtimes`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| movie_id | bigint | FK → movies |
| nama_studio | string | required |
| waktu_mulai | utc_datetime | required |
| harga_tiket | integer | dalam rupiah, required |
| lokasi | string | nama bioskop, e.g. "CGV Grand Indonesia" |

### `seats`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| showtime_id | bigint | FK → showtimes |
| nomor_kursi | string | e.g. "A1", unique per showtime |
| status | enum | `available`, `locked`, `booked` |

### `tickets`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| user_id | bigint | FK → users |
| showtime_id | bigint | FK → showtimes |
| nomor_kursi | string | |
| kode_booking | string | unique |

### `transactions`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| ticket_id | bigint | FK → tickets, unique |
| total_harga | integer | dalam rupiah |
| status_pembayaran | enum | `pending`, `success`, `expired` |

## Relasi

- **Movie** `1:N` **Showtime**
- **Showtime** `1:N` **Seat**, `1:N` **Ticket**
- **User** `1:N` **Ticket**
- **Ticket** `1:1` **Transaction**

## Contexts

| Context | Module | Entity |
|---|---|---|
| Accounts | `Bioskop.Accounts` | User |
| Cinema | `Bioskop.Cinema` | Movie, Showtime, Seat |
| Ticketing | `Bioskop.Ticketing` | Ticket, Transaction |

### Cinema — Fungsi Utama

| Fungsi | Deskripsi |
|---|---|
| `list_movies_now_showing/0` | Film yang sedang tayang (punya showtime) |
| `list_movies_coming_soon/0` | Film dengan `tanggal_rilis` di masa depan |
| `get_movie_with_showtimes!/1` | Preload film + showtimes |
| `get_showtime_with_seats!/1` | Preload showtime + kursi + film |

### SeatLock (In-Memory Locking)

`Bioskop.SeatLock` — GenServer untuk penguncian kursi sementara (5 menit).

| Function | Deskripsi |
|---|---|
| `lock_seat/2` | Kunci kursi (`available` → `locked`), mulai timer 5 menit |
| `unlock_seat/2` | Lepas kunci manual (`locked` → `available`) |
| `confirm_booking/2` | Konfirmasi booking, batalkan timer (`locked` → `booked`) |

### Checkout Flow

`Bioskop.Ticketing.process_checkout/2` — proses pembayaran atomik menggunakan `Ecto.Multi`.

```elixir
{:ok, %{transaction: tx, seat: seat}} = Ticketing.process_checkout(1, :success)
{:error, :payment_failed}             = Ticketing.process_checkout(1, :failure)
```

**Alur sukses (`:success`):**
1. Validasi: transaksi `pending`, ticket & kursi ditemukan, kursi `locked`
2. `Ecto.Multi` mengupdate **transaction** → `success` dan **seat** → `booked` secara atomik
3. `SeatLock.confirm_booking/2` dipanggil untuk cleanup timer in-memory

**Alur gagal (`:failure`):** tidak ada perubahan data, return `{:error, :payment_failed}`.

## Seed Data

Jalankan `mix run priv/repo/seeds.exs` untuk mengisi data contoh:
- 3 user
- 6 film Now Showing + 3 film Coming Soon
- Showtimes untuk 3 hari ke depan (5 slot waktu/hari) di 4 lokasi bioskop
- 80 kursi per showtime (baris A-H, kursi 1-10)

## Admin Panel (`/admin`)

Dashboard admin untuk manajemen data film dan jadwal tayang.

### Kelola Film (`/admin/movies`)
- Tabel daftar film: Poster mini, Judul, Rating Umur, Durasi, Genre, Aksi (Edit/Delete)
- Modal form Add/Edit: Judul, Sinopsis, Durasi, Genre, Rating Umur, Tanggal Rilis, Poster (upload file atau URL)
- Upload poster disimpan di `priv/static/uploads/`

### Kelola Jadwal (`/admin/showtimes`)
- Tabel jadwal tayang: Film, Studio, Tanggal & Jam, Lokasi, Harga, Aksi (Edit/Delete)
- Modal form Add/Edit: Dropdown Film, Dropdown Studio (1–5), Tanggal & Jam Tayang, Harga Tiket, Lokasi Bioskop
