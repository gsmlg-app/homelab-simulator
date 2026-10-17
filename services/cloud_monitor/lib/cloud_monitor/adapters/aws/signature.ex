defmodule CloudMonitor.Adapters.AWS.Signature do
  @moduledoc "SigV4 wrapper around aws-beam/aws_signature. Sign exactly the final wire request."
  def sign(credentials, region, service, now, method, url, headers, body) do
    headers = [{"host", URI.parse(url).host} | headers]

    headers =
      if credentials["sessionToken"],
        do: [{"x-amz-security-token", credentials["sessionToken"]} | headers],
        else: headers

    datetime = {{now.year, now.month, now.day}, {now.hour, now.minute, now.second}}

    :aws_signature.sign_v4(
      credentials["accessKeyId"],
      credentials["secretAccessKey"],
      region,
      service,
      datetime,
      method |> Atom.to_string() |> String.upcase(),
      url,
      headers,
      body
    )
  end
end
