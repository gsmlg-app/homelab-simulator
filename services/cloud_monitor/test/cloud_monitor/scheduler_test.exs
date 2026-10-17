defmodule CloudMonitor.BlockingTestAdapter do
  @behaviour CloudMonitor.Adapter
  def collect(connection, dataset, _window, _opts) do
    send(
      Application.fetch_env!(:cloud_monitor, :test_collector_owner),
      {:collecting, self(), connection["id"], dataset}
    )

    receive do
      :release -> {:ok, %{records: [], status: CloudMonitor.DataCase.status()}}
    end
  end
end

defmodule CloudMonitor.SchedulerTest do
  use CloudMonitor.DataCase, async: false

  setup do
    previous = Application.fetch_env!(:cloud_monitor, :adapters)
    Application.put_env(:cloud_monitor, :test_collector_owner, self())

    Application.put_env(
      :cloud_monitor,
      :adapters,
      Map.new(~w(aws cloudflare gcp), &{&1, CloudMonitor.BlockingTestAdapter})
    )

    on_exit(fn ->
      Application.put_env(:cloud_monitor, :adapters, previous)
      Application.delete_env(:cloud_monitor, :test_collector_owner)
    end)

    :ok
  end

  defp start_scheduler do
    start_supervised!(%{
      id: :test_scheduler,
      start: {GenServer, :start_link, [CloudMonitor.Scheduler, [enabled: true]]}
    })
  end

  test "scheduler enforces the configured concurrency and fills a slot after completion" do
    configure_fixture()

    for {id, dataset} <- [
          {"aws-main", "costs"},
          {"aws-main", "resources"},
          {"aws-main", "usage"},
          {"auth", "costs"}
        ] do
      assert {:ok, _} = Jobs.enqueue(id, dataset, window())
    end

    scheduler = start_scheduler()
    send(scheduler, :tick)

    workers =
      for _ <- 1..3 do
        assert_receive {:collecting, worker, _, _}, 2000
        worker
      end

    refute_receive {:collecting, _, _, _}, 100
    assert map_size(:sys.get_state(scheduler).tasks) == 3
    assert Repo.aggregate(from(j in Job, where: j.state == "queued"), :count) == 1
    Enum.each(workers, &send(&1, :release))
    assert_receive {:collecting, last, _, _}, 2500
    send(last, :release)

    eventually(fn ->
      Repo.aggregate(from(j in Job, where: j.state == "succeeded"), :count) == 4
    end)

    assert map_size(:sys.get_state(scheduler).tasks) == 0
  end

  test "an interrupted worker persists a retry rather than publishing an empty replacement" do
    data = configure_fixture()
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "aws-main"))

    assert {:ok, old} =
             Store.publish("aws-main", "costs", window(), %{records: rows, status: status()})

    assert {:ok, job} = Jobs.enqueue("aws-main", "costs", window())
    scheduler = start_scheduler()
    send(scheduler, :tick)
    assert_receive {:collecting, _, "aws-main", "costs"}, 2000
    [{ref, _}] = Map.to_list(:sys.get_state(scheduler).tasks)
    send(scheduler, {:timeout, ref})
    eventually(fn -> Repo.get!(Job, job.id).state == "retry" end)
    assert Repo.one(Snapshot).revision == old.revision
    assert Store.connection("aws-main")["statuses"]["costs"]["state"] == "failed"
  end

  defp eventually(fun, attempts \\ 100)
  defp eventually(fun, 0), do: assert(fun.())

  defp eventually(fun, attempts) do
    if fun.(),
      do: :ok,
      else:
        (
          Process.sleep(10)
          eventually(fun, attempts - 1)
        )
  end
end
