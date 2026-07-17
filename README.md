# CineReserve — Bioskop

Sistem pemesanan tiket bioskop real-time berbasis Elixir & Phoenix Framework.

## Prerequisites

- Elixir ~> 1.17
- PostgreSQL (user: `postgres`, password: sesuaikan di `config/dev.exs`)

## Setup

```bash
# Install dependencies
mix setup

# Buat database & jalankan migration
mix ecto.create
mix ecto.migrate

# Jalankan server
mix phx.server
```

Kunjungi [`localhost:4000`](http://localhost:4000) dari browser.

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

### `showtimes`
| Field | Type | Notes |
|---|---|---|
| id | bigserial | PK |
| movie_id | bigint | FK → movies |
| nama_studio | string | required |
| waktu_mulai | utc_datetime | required |
| harga_tiket | integer | dalam rupiah, required |

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
|---|---|---|---|
| Accounts | `Bioskop.Accounts` | User |
| Cinema | `Bioskop.Cinema` | Movie, Showtime, Seat |
| Ticketing | `Bioskop.Ticketing` | Ticket, Transaction |

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
