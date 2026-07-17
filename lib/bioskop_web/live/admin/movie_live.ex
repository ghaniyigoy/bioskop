defmodule BioskopWeb.Admin.MovieLive do
  use BioskopWeb, :live_view

  alias Bioskop.Cinema
  alias Bioskop.Cinema.Movie

  def mount(_params, _session, socket) do
    movies = Cinema.list_movies()

    socket =
      socket
      |> assign(:movies, movies)
      |> assign(:current_page, :movies)
      |> assign(:show_form, false)
      |> assign(:form_mode, :new)
      |> assign(:form_movie, nil)
      |> assign(:form, to_form(Cinema.change_movie(%Movie{})))
      |> allow_upload(:poster, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_page={@current_page}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <p class="text-sm text-base-content/60">
            Total {length(@movies)} film
          </p>
          <button
            class="btn btn-primary btn-sm rounded-lg gap-1.5"
            phx-click="open-new-form"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> Tambah Film
          </button>
        </div>

        <div class="overflow-hidden rounded-xl border border-base-200 bg-base-100 shadow-sm">
          <table class="w-full">
            <thead>
              <tr class="border-b border-base-200 bg-base-50">
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Poster
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Judul
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Durasi
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Genre
                </th>
                <th class="text-right px-4 py-3 text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                  Aksi
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-base-200">
              <%= for movie <- @movies do %>
                <tr class="hover:bg-base-50/50 transition-colors">
                  <td class="px-4 py-3">
                    <div class="w-12 h-16 rounded-lg overflow-hidden bg-base-200">
                      <img
                        src={movie.poster_url || "https://placehold.co/120x160?text=No+Poster"}
                        alt={movie.judul}
                        class="w-full h-full object-cover"
                      />
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <p class="font-medium text-sm">{movie.judul}</p>
                    <p class="text-xs text-base-content/40 mt-0.5">{movie.rating_umur}</p>
                  </td>
                  <td class="px-4 py-3 text-sm text-base-content/60">{movie.durasi} menit</td>
                  <td class="px-4 py-3">
                    <span class="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary">
                      {movie.genre || "-"}
                    </span>
                  </td>
                  <td class="px-4 py-3 text-right">
                    <div class="flex items-center justify-end gap-1">
                      <button
                        class="btn btn-ghost btn-sm rounded-lg"
                        phx-click="open-edit-form"
                        phx-value-id={movie.id}
                      >
                        <.icon name="hero-pencil-square" class="w-4 h-4" />
                      </button>
                      <button
                        class="btn btn-ghost btn-sm rounded-lg text-error hover:bg-error/10"
                        phx-click="delete-movie"
                        phx-value-id={movie.id}
                        data-confirm="Yakin ingin menghapus film ini?"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <%= if @movies == [] do %>
            <div class="py-16 text-center">
              <.icon name="hero-film" class="w-12 h-12 mx-auto text-base-content/20 mb-3" />
              <p class="text-base-content/40 text-sm">
                Belum ada film. Klik "Tambah Film" untuk memulai.
              </p>
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
                {(@form_mode == :new && "Tambah Film") || "Edit Film"}
              </h2>
              <button class="btn btn-ghost btn-sm btn-square rounded-lg" phx-click="close-form">
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <.form for={@form} id="movie-form" phx-submit="save-movie">
              <div class="px-6 py-4 space-y-4 max-h-[60vh] overflow-y-auto">
                <.input
                  field={@form[:judul]}
                  type="text"
                  label="Judul Film"
                  placeholder="Masukkan judul film"
                />
                <.input
                  field={@form[:sinopsis]}
                  type="textarea"
                  label="Sinopsis"
                  placeholder="Masukkan sinopsis film"
                  rows={3}
                />

                <div class="grid grid-cols-2 gap-4">
                  <.input
                    field={@form[:durasi]}
                    type="number"
                    label="Durasi (Menit)"
                    placeholder="Contoh: 120"
                  />
                  <.input
                    field={@form[:genre]}
                    type="text"
                    label="Genre"
                    placeholder="Contoh: Aksi, Petualangan"
                  />
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <.input
                    field={@form[:rating_umur]}
                    type="select"
                    label="Rating Umur"
                    options={[SU: "SU", "13+": "13+", "17+": "17+"]}
                    prompt="Pilih rating"
                  />
                  <.input field={@form[:tanggal_rilis]} type="date" label="Tanggal Rilis" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-1.5">Poster Film</label>
                  <div class="flex items-center gap-4">
                    <div class="flex-1">
                      <.input
                        field={@form[:poster_url]}
                        type="text"
                        placeholder="Atau masukkan URL poster"
                      />
                    </div>
                    <div class="relative mt-5">
                      <.live_file_input
                        upload={@uploads.poster}
                        class="file-input file-input-bordered file-input-sm w-full max-w-xs"
                      />
                    </div>
                  </div>
                  <%= for entry <- @uploads.poster.entries do %>
                    <div class="mt-2 flex items-center gap-2 text-xs text-base-content/60">
                      <.icon name="hero-check-circle" class="w-4 h-4 text-success" />
                      {entry.client_name}
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-base-200 bg-base-50/50">
                <button type="button" class="btn btn-ghost btn-sm rounded-lg" phx-click="close-form">
                  Batal
                </button>
                <button type="submit" class="btn btn-primary btn-sm rounded-lg">
                  {(@form_mode == :new && "Simpan Film") || "Simpan Perubahan"}
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
    form = to_form(Cinema.change_movie(%Movie{}))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form_mode, :new)
      |> assign(:form_movie, nil)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("open-edit-form", %{"id" => id}, socket) do
    movie = Cinema.get_movie!(String.to_integer(id))
    form = to_form(Cinema.change_movie(movie))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form_mode, :edit)
      |> assign(:form_movie, movie)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("close-form", _, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("save-movie", %{"movie" => movie_params}, socket) do
    poster_url = handle_poster_upload(socket)

    movie_params =
      if poster_url do
        Map.put(movie_params, "poster_url", poster_url)
      else
        movie_params
      end

    case socket.assigns.form_mode do
      :new ->
        case Cinema.create_movie(movie_params) do
          {:ok, _movie} ->
            {:noreply,
             socket
             |> put_flash(:info, "Film berhasil ditambahkan")
             |> push_navigate(to: "/admin/movies")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      :edit ->
        movie = socket.assigns.form_movie

        case Cinema.update_movie(movie, movie_params) do
          {:ok, _movie} ->
            {:noreply,
             socket
             |> put_flash(:info, "Film berhasil diperbarui")
             |> push_navigate(to: "/admin/movies")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  def handle_event("delete-movie", %{"id" => id}, socket) do
    movie = Cinema.get_movie!(String.to_integer(id))

    case Cinema.delete_movie(movie) do
      {:ok, _movie} ->
        {:noreply,
         socket
         |> put_flash(:info, "Film berhasil dihapus")
         |> push_navigate(to: "/admin/movies")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Gagal menghapus film")}
    end
  end

  defp handle_poster_upload(socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :poster, fn %{client_name: client_name}, path ->
        ext = client_name |> Path.extname() |> String.downcase()
        new_filename = "#{System.unique_integer([:positive])}#{ext}"
        dest = Path.join(Application.app_dir(:bioskop, "priv/static/uploads"), new_filename)

        File.cp!(path, dest)
        {:ok, "/uploads/#{new_filename}"}
      end)

    List.first(uploaded_files)
  end
end
