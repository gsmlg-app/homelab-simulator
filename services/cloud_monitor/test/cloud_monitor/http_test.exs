defmodule CloudMonitor.HTTPTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.HTTP

  test "raw XML responses and signed form content types survive the HTTP boundary" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
    {:ok, {_, port}} = :inet.sockname(listener)
    parent = self()
    xml = "<DescribeInstancesResponse><reservationSet/></DescribeInstancesResponse>"

    server =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener)
        {:ok, request} = :gen_tcp.recv(socket, 0, 5000)
        send(parent, {:request, request})

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 200 OK\r\nContent-Length: #{byte_size(xml)}\r\nConnection: close\r\n\r\n#{xml}"
          )

        :gen_tcp.close(socket)
      end)

    on_exit(fn -> :gen_tcp.close(listener) end)

    assert {:ok, %{status: 200, body: ^xml}} =
             HTTP.request(:post, "http://127.0.0.1:#{port}/", [], "Action=DescribeInstances",
               allow_localhost: true,
               response_format: :raw,
               content_type: "application/x-www-form-urlencoded; charset=utf-8"
             )

    assert_receive {:request, request}

    assert String.downcase(request) =~
             "content-type: application/x-www-form-urlencoded; charset=utf-8"

    Task.await(server)
  end

  test "all-page success returns one collection and a later failure returns no partial rows" do
    assert {:ok, [%{"id" => "1"}, %{"id" => "2"}]} =
             HTTP.paginate(fn
               nil -> {:ok, [%{"id" => "1"}], "two"}
               "two" -> {:ok, [%{"id" => "2"}], nil}
             end)

    assert {:error, "permissionDenied", nil} =
             HTTP.paginate(fn
               nil -> {:ok, [%{"id" => "1"}], "two"}
               "two" -> {:error, "permissionDenied", nil}
             end)

    assert {:error, "requestBudgetExceeded", nil} =
             HTTP.paginate(fn _ -> {:ok, [], "more"} end, request_budget: 1)

    assert {:error, "paginationCycle", nil} = HTTP.paginate(fn _ -> {:ok, [], "more"} end)

    assert {:error, "resourceLimitExceeded", nil} =
             HTTP.paginate(fn _ -> {:ok, [1, 2], nil} end, max_records: 1)
  end

  test "HTTP requires TLS outside explicit localhost development and secrets require explicit refs" do
    assert {:error, "invalidConfiguration"} =
             HTTP.request(:get, "http://example.test", [], "", [])

    assert {:error, "unconfigured"} = CloudMonitor.Credentials.read(nil)

    assert {:error, "unconfigured"} =
             CloudMonitor.Credentials.read("env:HOMELAB_CLOUD_MONITOR_TEST_MISSING_REF")
  end
end
