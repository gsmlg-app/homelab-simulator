defmodule CloudMonitor.Adapters.AWS.ValidationTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.AWS.XML

  test "XML parser refuses external entities and trailing garbage" do
    assert {:error, "invalidData"} =
             XML.parse(
               "<!DOCTYPE test [<!ENTITY xxe SYSTEM 'file:///should-never-be-read'>]><test>&xxe;</test>"
             )

    assert {:error, "invalidData"} = XML.parse("<valid/>trailing")

    assert {:ok, doc} =
             XML.parse("<root xmlns='https://example.test'><value>native</value></root>")

    assert XML.value(doc, ["value"]) == "native"
  end
end
