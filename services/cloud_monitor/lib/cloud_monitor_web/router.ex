defmodule CloudMonitorWeb.Router do
  use Phoenix.Router

  pipeline :api do
    plug CloudMonitorWeb.Auth
    plug :accepts, ["json"]
  end

  scope "/v1", CloudMonitorWeb do
    pipe_through :api
    get "/connections", APIController, :connections
    get "/cloud-center/overview", APIController, :overview
    get "/connections/:id/overview", APIController, :connection_overview
    get "/connections/:id/costs", APIController, :costs
    get "/connections/:id/resources", APIController, :resources
    get "/resources/:id/usage", APIController, :usage
    post "/connections/:id/sync", APIController, :sync
    get "/sync-jobs/:id", APIController, :sync_job
    get "/budgets", APIController, :budgets
    put "/budgets/:id", APIController, :save_budget
  end
end
