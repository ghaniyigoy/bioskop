defmodule BioskopWeb.PageController do
  use BioskopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
