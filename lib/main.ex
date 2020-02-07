require Lager

defmodule MintTest.Main do
  def main(_argv0 \\ []) do
    :application.ensure_all_started(:lager)
    :application.ensure_all_started(:ssl)

    _ = Lager.alert("--- MintTest HTTP 2 Error ---")

    # open a connection
    {:ok, pid} = ConnectionProcess.start_link({:https, "sofi.zendesk.com", 443})

    # send one request on the connection
    path = "/"
    {:ok, response} =
        ConnectionProcess.request(
          pid,
          "GET",
          path,
          [
            {"Accept", "application/json"}
          ],
          ""
        )

    # expected
    # [emergency] [Elixir.ConnectionProcess:111] HTTP ERROR: {:server_closed_connection, :protocol_error, ""}

    _ = Process.sleep(1_000)
    _ = Lager.alert("--- All Done! ---")
    _ = Process.sleep(1_000)
  end
end
