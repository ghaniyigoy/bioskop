defmodule BioskopWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BioskopWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :current_page, :atom,
    default: nil,
    doc: "the current page identifier for active nav highlighting"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar bg-base-100 border-b border-base-200 px-4 sm:px-6 lg:px-8 sticky top-0 z-50 backdrop-blur-lg bg-base-100/90">
      <div class="flex-1 flex items-center gap-4 sm:gap-8">
        <a href="/" class="flex items-center gap-2.5 group">
          <div class="w-9 h-9 rounded-xl bg-primary flex items-center justify-center shadow-md shadow-primary/20 group-hover:shadow-lg group-hover:shadow-primary/30 transition-all">
            <.icon name="hero-film" class="w-5 h-5 text-primary-content" />
          </div>
          <span class="text-lg font-bold tracking-tight hidden sm:block">CineReserve</span>
        </a>

        <div class="hidden md:flex items-center gap-1">
          <a
            href="/"
            class={[
              "btn btn-ghost btn-sm rounded-lg text-sm",
              if(@current_page == :home, do: "btn-active")
            ]}
          >
            Now Showing
          </a>

          <a href="/#coming-soon" class="btn btn-ghost btn-sm rounded-lg text-sm">
            Coming Soon
          </a>
        </div>
      </div>

      <div class="flex-none flex items-center gap-2 sm:gap-3">
        <div class="relative hidden sm:block">
          <.icon
            name="hero-magnifying-glass"
            class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-base-content/40"
          />
          <input
            type="search"
            placeholder="Cari film..."
            class="input input-sm input-ghost rounded-lg pl-9 w-40 lg:w-56 bg-base-200/50 focus:bg-base-200 transition-all text-sm"
          />
        </div>
        <.theme_toggle />
      </div>
    </header>

    <main class="min-h-screen">
      {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Admin layout with sidebar navigation.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_page, :atom, default: nil, doc: "current page for active nav highlighting"
  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <div class="min-h-screen flex bg-base-200">
      <%!-- Sidebar --%>
      <aside class="w-64 bg-base-100 border-r border-base-200 flex flex-col shrink-0">
        <div class="p-5 border-b border-base-200">
          <a href="/admin/movies" class="flex items-center gap-2.5 group">
            <div class="w-9 h-9 rounded-xl bg-primary flex items-center justify-center shadow-md shadow-primary/20">
              <.icon name="hero-film" class="w-5 h-5 text-primary-content" />
            </div>
            <span class="text-lg font-bold tracking-tight">CineReserve</span>
          </a>

          <p class="text-xs text-base-content/50 mt-1 ml-0.5">Admin Panel</p>
        </div>

        <nav class="flex-1 p-3 space-y-1">
          <.admin_nav_item
            label="Kelola Film"
            icon="hero-film"
            path="/admin/movies"
            active={@current_page == :movies}
          />
          <.admin_nav_item
            label="Kelola Jadwal"
            icon="hero-calendar-days"
            path="/admin/showtimes"
            active={@current_page == :showtimes}
          />
        </nav>

        <div class="p-3 border-t border-base-200">
          <a
            href="/"
            class="flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm text-base-content/60 hover:text-base-content hover:bg-base-200 transition-colors"
          >
            <.icon name="hero-arrow-left-on-rectangle" class="w-4 h-4" /> Kembali ke Website
          </a>
        </div>
      </aside>
      <%!-- Main content --%>
      <div class="flex-1 flex flex-col min-h-screen">
        <header class="h-16 bg-base-100 border-b border-base-200 flex items-center justify-between px-6 sticky top-0 z-40">
          <div>
            <h1 class="text-lg font-semibold">
              {case @current_page do
                :movies -> "Kelola Film"
                :showtimes -> "Kelola Jadwal"
                _ -> "Dashboard"
              end}
            </h1>
          </div>

          <div class="flex items-center gap-3">
            <.theme_toggle />
          </div>
        </header>

        <main class="flex-1 p-6">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  defp admin_nav_item(assigns) do
    ~H"""
    <a
      href={@path}
      class={[
        "flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm transition-colors",
        if(@active,
          do: "bg-primary/10 text-primary font-medium",
          else: "text-base-content/60 hover:text-base-content hover:bg-base-200"
        )
      ]}
    >
      <.icon name={@icon} class="w-4 h-4" /> {@label}
    </a>
    """
  end
end
