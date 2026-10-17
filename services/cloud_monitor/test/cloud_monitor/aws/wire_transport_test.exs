defmodule CloudMonitor.Adapters.AWS.WireTransportTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.AWS
  @moduletag :tmp_dir

  test "signed STS and Cost Explorer requests traverse real HTTP without changing MIME body or session token",
       %{tmp_dir: dir} do
    credentials = %{
      "accessKeyId" => "AKIDEXAMPLE",
      "secretAccessKey" => "fixture-secret",
      "sessionToken" => "fixture-session"
    }

    file = Path.join(dir, "explicit-wire-test-credentials.json")
    File.write!(file, JSON.encode!(credentials))

    connection = %{
      "id" => "aws-wire-test",
      "billingScopeId" => "billing",
      "credentialRef" => "file:" <> file,
      "settings" => %{"accountId" => "123456789012", "regions" => ["us-east-1"]}
    }

    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
    {:ok, {_, port}} = :inet.sockname(listener)
    owner = self()

    response_bodies = [
      "<GetCallerIdentityResponse><GetCallerIdentityResult><Account>123456789012</Account></GetCallerIdentityResult></GetCallerIdentityResponse>",
      JSON.encode!(%{"ResultsByTime" => []})
    ]

    server =
      Task.async(fn ->
        Enum.each(response_bodies, fn response ->
          {:ok, socket} = :gen_tcp.accept(listener, 5000)
          {headers, body} = read_request(socket, "")
          send(owner, {:wire, headers, body})

          :ok =
            :gen_tcp.send(
              socket,
              "HTTP/1.1 200 OK\r\nContent-Length: #{byte_size(response)}\r\nConnection: close\r\n\r\n#{response}"
            )

          :gen_tcp.close(socket)
        end)
      end)

    on_exit(fn -> :gen_tcp.close(listener) end)

    transport = fn method, _aws_url, headers, body, opts ->
      CloudMonitor.HTTP.request(
        method,
        "http://127.0.0.1:#{port}/",
        headers,
        body,
        Keyword.put(opts, :allow_localhost, true)
      )
    end

    assert {:error, "waiting", nil} =
             AWS.collect(
               connection,
               "costs",
               %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-10-03 00:00:00Z]},
               http: transport,
               now: ~U[2026-10-17 12:00:00Z]
             )

    assert_receive {:wire, sts_headers, sts_body}
    assert URI.decode_query(sts_body)["Action"] == "GetCallerIdentity"

    assert String.downcase(sts_headers) =~
             "content-type: application/x-www-form-urlencoded; charset=utf-8"

    assert_receive {:wire, ce_headers, ce_body}
    lowered = String.downcase(ce_headers)
    assert lowered =~ "host: ce.us-east-1.amazonaws.com"
    assert lowered =~ "x-amz-security-token: fixture-session"
    assert lowered =~ "content-type: application/x-amz-json-1.1"
    assert lowered =~ "x-amz-target: awsinsightsindexservice.getcostandusage"
    assert length(Regex.scan(~r/content-type:/i, ce_headers)) == 1

    assert lowered =~
             "x-amz-content-sha256: " <>
               Base.encode16(:crypto.hash(:sha256, ce_body), case: :lower)

    assert JSON.decode!(ce_body)["Metrics"] == ["UnblendedCost"]
    assert lowered =~ "/us-east-1/ce/aws4_request"
    Task.await(server, 5000)
  end

  defp read_request(socket, bytes) do
    case String.split(bytes, "\r\n\r\n", parts: 2) do
      [headers, body] ->
        [_, length] = Regex.run(~r/content-length: (\d+)/i, headers)

        if byte_size(body) >= String.to_integer(length),
          do: {headers, body},
          else: receive_more(socket, bytes)

      _ ->
        receive_more(socket, bytes)
    end
  end

  defp receive_more(socket, bytes) do
    {:ok, more} = :gen_tcp.recv(socket, 0, 5000)
    read_request(socket, bytes <> more)
  end
end
