defmodule CloudMonitor.Adapters.AWS.SignatureTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.AWS.Signature

  test "deterministic canonical IAM request matches independent Python hashlib HMAC calculation" do
    credentials = %{
      "accessKeyId" => "AKIDEXAMPLE",
      "secretAccessKey" => "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
    }

    headers =
      Signature.sign(
        credentials,
        "us-east-1",
        "iam",
        ~U[2015-08-30 12:36:00Z],
        :get,
        "https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
        [{"content-type", "application/x-www-form-urlencoded; charset=utf-8"}],
        ""
      )
      |> Map.new(fn {key, value} -> {String.downcase(key), value} end)

    assert headers["authorization"] ==
             "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request,SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date,Signature=dd479fa8a80364edf2119ec24bebde66712ee9c9cb2b0d92eb3ab9ccdc0c3947"

    assert headers["x-amz-content-sha256"] ==
             "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  end

  test "session token payload and host all affect the signature" do
    credentials = %{
      "accessKeyId" => "AKIDEXAMPLE",
      "secretAccessKey" => "fixture-secret",
      "sessionToken" => "short-lived-fixture"
    }

    sign = fn url, body ->
      Signature.sign(
        credentials,
        "us-east-1",
        "ce",
        ~U[2026-10-17 00:00:00Z],
        :post,
        url,
        [{"content-type", "application/x-amz-json-1.1"}],
        body
      )
      |> Map.new(fn {k, v} -> {String.downcase(k), v} end)
    end

    first = sign.("https://ce.us-east-1.amazonaws.com/", "{}")
    assert first["x-amz-security-token"] == "short-lived-fixture"

    assert first["authorization"] !=
             sign.("https://ce.us-east-1.amazonaws.com/", "{\"x\":1}")["authorization"]

    assert first["authorization"] !=
             sign.("https://ce.us-west-2.amazonaws.com/", "{}")["authorization"]

    assert String.contains?(first["authorization"], "x-amz-security-token")
  end
end
