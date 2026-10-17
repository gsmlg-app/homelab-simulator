defmodule CloudMonitorWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :cloud_monitor

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: JSON,
    length: 1_000_000

  plug CloudMonitorWeb.Router
end

defmodule CloudMonitorWeb.ErrorJSON do
  def render(_, _), do: %{"error" => %{"code" => "failed", "message" => "Request failed"}}
end
