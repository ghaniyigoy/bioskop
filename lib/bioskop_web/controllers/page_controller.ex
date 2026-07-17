defmodule BioskopWeb.PageController do
  use BioskopWeb, :controller

  alias Bioskop.Cinema

  def home(conn, _params) do
    now_showing = Cinema.list_movies_now_showing()
    coming_soon = Cinema.list_movies_coming_soon()

    render(conn, :home,
      now_showing: now_showing,
      coming_soon: coming_soon,
      current_scope: nil
    )
  end
end
