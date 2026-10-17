defmodule CloudMonitorWeb.Auth do
  import Plug.Conn
  def init(opts), do: opts

  def call(conn, _) do
    expected = Application.get_env(:cloud_monitor, :token)

    authorized =
      case get_req_header(conn, "authorization") do
        ["Bearer " <> supplied] when is_binary(expected) and byte_size(expected) >= 16 ->
          Plug.Crypto.secure_compare(supplied, expected)

        _ ->
          false
      end

    if authorized,
      do: conn,
      else:
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          JSON.encode!(%{
            error: %{code: "authenticationFailed", message: "Authentication required"}
          })
        )
        |> halt()
  end
end
