defmodule Lssn.PageController do
  use Lssn.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
