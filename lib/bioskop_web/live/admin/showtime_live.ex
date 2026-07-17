defmodule BioskopWeb.Admin.ShowtimeLive do
  use BioskopWeb, :live_view

  alias Bioskop.Cinema
  alias Bioskop.Cinema.Showtime

  def mount(_params, _session, socket) do
    showtimes = Cinema.list_showtimes_with_movies()
    movies = Cinema.list_movies()

    socket =
      socket
      |> assign(:showtimes, showtimes)
      |> assign(:movies, movies)
      |> assign(:current_page, :showtimes)
      |> assign(:show_form, false)
      |> assign(:form_mode, :new)
      |> assign(:form_showtime, nil)
      |> assign(:form, to_form(Cinema.change_showtime(%Showtime{})))
      |> assign(:selected_date, nil)
      |> assign(:selected_time, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_page={@current_page}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <p class="text-sm text-base-content/60">
            Total {length(@showtimes)} jadwal tayang
          </p>
          <button
            class="btn btn-primary btn-sm rounded-lg gap-1.5"
            phx-click="open-new-form"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> Tambah Jadwal
          </button>
        </div>

        <div class="overflow-hidden rounded-xl border border-base-200 bg-base-100 shadow-sm">
          <table class="w-full">
            <thead>
              <tr class="border-b border-base-200 bg-base-50">
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Film
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Studio
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Tanggal & Jam
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Lokasi
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Harga
                </th>
                <th class="text-right px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Aksi
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-base-200">
              <%= for showtime <- @showtimes do %>
                <tr class="hover:bg-base-50/50 transition-colors">
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-10 rounded overflow-hidden bg-base-200 shrink-0">
                        <img
                          src={showtime.movie.poster_url || "https://placehold.co/80x100?text=N"}
                          alt={showtime.movie.judul}
                          class="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <p class="font-medium text-sm">{showtime.movie.judul}</p>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <span class="text-sm">Studio {showtime.nama_studio}</span>
                  </td>
                  <td class="px-4 py-3">
                    <p class="text-sm">
                      {format_date(showtime.waktu_mulai)}
                    </p>
                    <p class="text-xs text-base-content/40">
                      {format_time(showtime.waktu_mulai)}
                    </p>
                  </td>
                  <td class="px-4 py-3 text-sm text-base-content/60">{showtime.lokasi}</td>
                  <td class="px-4 py-3">
                    <span class="text-sm font-medium">{format_price(showtime.harga_tiket)}</span>
                  </td>
                  <td class="px-4 py-3 text-right">
                    <div class="flex items-center justify-end gap-1">
                      <button
                        class="btn btn-ghost btn-sm rounded-lg"
                        phx-click="open-edit-form"
                        phx-value-id={showtime.id}
                      >
                        <.icon name="hero-pencil-square" class="w-4 h-4" />
                      </button>
                      <button
                        class="btn btn-ghost btn-sm rounded-lg text-error hover:bg-error/10"
                        phx-click="delete-showtime"
                        phx-value-id={showtime.id}
                        data-confirm="Yakin ingin menghapus jadwal ini?"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <%= if @showtimes == [] do %>
            <div class="py-16 text-center">
              <.icon name="hero-calendar-days" class="w-12 h-12 mx-auto text-base-content/20 mb-3" />
              <p class="text-base-content/40 text-sm">Belum ada jadwal tayang.</p>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @show_form do %>
        <div class="fixed inset-0 z-50 flex items-start justify-center pt-10 sm:pt-24">
          <div class="fixed inset-0 bg-black/40 backdrop-blur-sm" phx-click="close-form" />
          <div class="relative bg-base-100 rounded-2xl shadow-2xl border border-base-200 w-full max-w-lg mx-4 overflow-hidden">
            <div class="flex items-center justify-between px-6 py-4 border-b border-base-200">
              <h2 class="text-lg font-semibold">
                {(@form_mode == :new && "Tambah Jadwal Tayang") || "Edit Jadwal Tayang"}
              </h2>
              <button class="btn btn-ghost btn-sm btn-square rounded-lg" phx-click="close-form">
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <.form for={@form} id="showtime-form" phx-submit="save-showtime">
              <div class="px-6 py-4 space-y-4 max-h-[60vh] overflow-y-auto">
                <.input
                  field={@form[:movie_id]}
                  type="select"
                  label="Pilih Film"
                  options={Enum.map(@movies, fn m -> {m.judul, m.id} end)}
                  prompt="Pilih film"
                />

                <.input
                  field={@form[:nama_studio]}
                  type="select"
                  label="Pilih Studio"
                  options={[
                    "Studio 1": "1",
                    "Studio 2": "2",
                    "Studio 3": "3",
                    "Studio 4": "4",
                    "Studio 5": "5"
                  ]}
                  prompt="Pilih studio"
                />

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:tanggal]}
                      type="date"
                      label="Tanggal Tayang"
                      value={@selected_date}
                    />
                  </div>
                  <div>
                    <.input field={@form[:jam]} type="time" label="Jam Tayang" value={@selected_time} />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <.input
                    field={@form[:harga_tiket]}
                    type="number"
                    label="Harga Tiket (Rp)"
                    placeholder="Contoh: 50000"
                  />
                  <.input
                    field={@form[:lokasi]}
                    type="text"
                    label="Lokasi Bioskop"
                    placeholder="Contoh: CGV Grand Indonesia"
                  />
                </div>
              </div>

              <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-base-200 bg-base-50/50">
                <button type="button" class="btn btn-ghost btn-sm rounded-lg" phx-click="close-form">
                  Batal
                </button>
                <button type="submit" class="btn btn-primary btn-sm rounded-lg">
                  {(@form_mode == :new && "Simpan Jadwal") || "Simpan Perubahan"}
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </Layouts.admin>
    """
  end

  def handle_event("open-new-form", _, socket) do
    form = to_form(Cinema.change_showtime(%Showtime{}))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form_mode, :new)
      |> assign(:form_showtime, nil)
      |> assign(:selected_date, nil)
      |> assign(:selected_time, nil)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("open-edit-form", %{"id" => id}, socket) do
    showtime = Cinema.get_showtime_with_seats!(String.to_integer(id))

    waktu_mulai = showtime.waktu_mulai
    date_str = waktu_mulai |> DateTime.to_date() |> Date.to_iso8601()

    time_str =
      waktu_mulai
      |> DateTime.to_time()
      |> Time.truncate(:second)
      |> Time.to_string()
      |> String.slice(0, 5)

    showtime_params = %{
      movie_id: showtime.movie_id,
      nama_studio: showtime.nama_studio,
      harga_tiket: showtime.harga_tiket,
      lokasi: showtime.lokasi
    }

    form = to_form(Cinema.change_showtime(showtime, showtime_params))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form_mode, :edit)
      |> assign(:form_showtime, showtime)
      |> assign(:selected_date, date_str)
      |> assign(:selected_time, time_str)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("close-form", _, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("save-showtime", %{"showtime" => showtime_params}, socket) do
    date_str = showtime_params["tanggal"]
    time_str = showtime_params["jam"]

    waktu_mulai =
      case NaiveDateTime.from_iso8601("#{date_str} #{time_str}:00") do
        {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
        _ -> nil
      end

    showtime_params = Map.put(showtime_params, "waktu_mulai", waktu_mulai)

    case socket.assigns.form_mode do
      :new ->
        case Cinema.create_showtime(showtime_params) do
          {:ok, _showtime} ->
            {:noreply,
             socket
             |> put_flash(:info, "Jadwal berhasil ditambahkan")
             |> push_navigate(to: "/admin/showtimes")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      :edit ->
        showtime = socket.assigns.form_showtime

        case Cinema.update_showtime(showtime, showtime_params) do
          {:ok, _showtime} ->
            {:noreply,
             socket
             |> put_flash(:info, "Jadwal berhasil diperbarui")
             |> push_navigate(to: "/admin/showtimes")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  def handle_event("delete-showtime", %{"id" => id}, socket) do
    showtime = Cinema.get_showtime!(String.to_integer(id))

    case Cinema.delete_showtime(showtime) do
      {:ok, _showtime} ->
        {:noreply,
         socket
         |> put_flash(:info, "Jadwal berhasil dihapus")
         |> push_navigate(to: "/admin/showtimes")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Gagal menghapus jadwal")}
    end
  end

  defp format_price(price) do
    price
    |> Integer.to_string()
    |> String.reverse()
    |> String.codepoints()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
    |> then(&"Rp#{&1}")
  end

  defp format_date(%DateTime{} = datetime) do
    datetime |> DateTime.to_date() |> Calendar.strftime("%d %b %Y")
  end

  defp format_time(%DateTime{} = datetime) do
    datetime |> DateTime.to_time() |> Time.truncate(:second) |> Calendar.strftime("%H:%M")
  end
end
