defmodule Lssn.Router do
  use Lssn.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Lssn.Auth, repo: Lssn.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Lssn do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/classes", ClassController, except: [:edit, :update]

    get "/classes/:id/export", ClassController, :export

    get "/classes/new/item_new", ClassController, :item_new
    post "/classes/new", ClassController, :item_create

    get "/classes/:id/new", ClassController, :record_new
    post "/classes/:id/create", ClassController, :record_create
    delete "/classes/:id/delete", ClassController, :record_delete
    get "/classes/:id/edit", ClassController, :record_edit
    post "/classes/:id/update", ClassController, :record_update

    post "/classes/:id", ClassController, :show

    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Lssn do
  #   pipe_through :api
  # end
end
