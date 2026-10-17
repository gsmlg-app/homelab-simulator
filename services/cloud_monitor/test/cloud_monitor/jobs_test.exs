defmodule CloudMonitor.JobsTest do
  use CloudMonitor.DataCase, async: true

  test "job uniqueness, restart recovery and persisted attempts survive worker loss" do
    configure_fixture()
    assert {:ok, first} = Jobs.enqueue("aws-main", "resources", window())
    assert {:ok, duplicate} = Jobs.enqueue("aws-main", "resources", window())
    assert first.id == duplicate.id
    assert {:ok, claimed} = Jobs.claim(first.id)
    assert claimed.state == "running"
    assert :ok = Jobs.recover()
    assert %Job{state: "queued", attempts: 1} = Repo.get!(Job, first.id)
    assert {:ok, _} = Jobs.run(first.id, adapter: CloudMonitor.TestAdapter)
    assert %Job{state: "succeeded", attempts: 2} = Repo.get!(Job, first.id)
    assert Repo.aggregate(Entry, :count) > 0
  end

  test "second and millisecond windows persist with canonical precision" do
    configure_fixture()

    assert {:ok, first} =
             Jobs.enqueue("aws-main", "costs", %{
               start: ~U[2026-10-01 00:00:00Z],
               end: ~U[2026-11-01 00:00:00Z]
             })

    assert {:ok, duplicate} = Jobs.enqueue("aws-main", "costs", window())
    assert first.id == duplicate.id
    assert first.window_start.microsecond == {0, 6}
    assert first.window_end.microsecond == {0, 6}

    assert {:ok, _} =
             Jobs.enqueue("aws-main", "resources", %{
               start: ~U[2026-10-01 00:00:00.123456Z],
               end: ~U[2026-10-02 00:00:00.654321Z]
             })
  end

  test "rate limits respect retry-after, auth failures are terminal and no synthetic data appears" do
    configure_fixture()
    assert {:ok, job} = Jobs.enqueue("aws-main", "costs", window())

    assert {:error, "rateLimited"} =
             Jobs.run(job.id,
               adapter: CloudMonitor.TestAdapter,
               adapter_opts: [test_result: {:error, "rateLimited", 120}]
             )

    assert %Job{state: "retry", next_run_at: retry_at} = Repo.get!(Job, job.id)
    assert DateTime.diff(retry_at, DateTime.utc_now()) >= 115
    assert {:error, "notDue"} = Jobs.claim(job.id)
    assert {:ok, auth} = Jobs.enqueue("auth", "costs", window())

    assert {:error, "authenticationFailed"} =
             Jobs.run(auth.id,
               adapter: CloudMonitor.TestAdapter,
               adapter_opts: [test_result: {:error, "authenticationFailed", nil}]
             )

    assert %Job{state: "failed"} = Repo.get!(Job, auth.id)
    assert Store.records("costs") == []
    assert {:ok, unconfigured} = Jobs.enqueue("unconfigured", "costs", window())
    assert {:error, "unconfigured"} = Jobs.run(unconfigured.id)
  end

  test "registered providers classify missing references and invalid settings without retry" do
    data = configure_fixture()

    assert Enum.sort(Map.keys(Application.fetch_env!(:cloud_monitor, :adapters))) ==
             ~w(aws cloudflare gcp)

    for provider <- ~w(aws cloudflare gcp) do
      base =
        hd(data["connections"])
        |> Map.merge(%{
          "id" => "missing-" <> provider,
          "provider" => provider,
          "credentialRef" => nil,
          "settings" => %{}
        })

      :ok = Store.configure(%{"connections" => [base]})
      {:ok, job} = Jobs.enqueue(base["id"], "costs", window())
      assert {:error, "unconfigured"} = Jobs.run(job.id)
      assert %Job{state: "failed", error_code: "unconfigured"} = Repo.get!(Job, job.id)

      configured =
        Map.merge(base, %{
          "id" => "invalid-" <> provider,
          "credentialRef" => "env:CC04_OFFLINE_UNUSED_REFERENCE"
        })

      :ok = Store.configure(%{"connections" => [configured]})
      {:ok, job} = Jobs.enqueue(configured["id"], "costs", window())
      assert {:error, "configurationError"} = Jobs.run(job.id)
      assert %Job{state: "failed", error_code: "configurationError"} = Repo.get!(Job, job.id)
    end

    assert Store.records("costs") == []
  end
end
