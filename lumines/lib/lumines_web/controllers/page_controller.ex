defmodule LuminesWeb.PageController do
  use LuminesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
