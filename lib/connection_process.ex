require Lager

defmodule ConnectionProcess do
  @moduledoc """
  Maintains the state of a Mint connection
  """
  use GenServer

  defstruct [:conn, requests: %{}]

  def start_link({scheme, host, port}) do
    GenServer.start_link(__MODULE__, {scheme, host, port}, name: __MODULE__)
  end

  def start({scheme, host, port}) do
    GenServer.start(__MODULE__, {scheme, host, port})
  end

  def request(pid, method, path, headers, body, timeout \\ 60_000) do
    GenServer.call(pid, {:request, method, path, headers, body}, timeout)
  end

  def inspect do
    GenServer.call(__MODULE__, {:inspect})
  end

  ## Callbacks

  @impl true
  def init({scheme, host, port}) do
    opts =
      case scheme do
        :https ->
          [
            # https://erlang.org/doc/man/gen_tcp.html
            transport_opts: [
              ciphers: :ssl.cipher_suites(:default, :"tlsv1.2"),
              cacertfile: "priv/cacerts.pem"
            ]
          ]

        _ ->
          [transport_opts: []]
      end

    case Mint.HTTP.connect(scheme, host, port, opts) do
      {:ok, conn} ->
        state = %__MODULE__{conn: conn}
        {:ok, state}

      {:error, %Mint.TransportError{reason: _reason} = error} ->
        {:stop, Exception.message(error)}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:request, method, path, headers, body}, from, state) do
    case Mint.HTTP.request(state.conn, method, path, headers, body) do
      {:ok, conn, request_ref} ->
        state = put_in(state.conn, conn)
        state =
          put_in(state.requests[request_ref], %{from: from, response: %{}})

        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:inspect}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, &process_response/2)
        {:noreply, state}

      {:error, conn, %Mint.TransportError{reason: :closed}, _responses} ->
        _ =
          Lager.debug(
            "#{inspect(self())}, Connection closed, recycle ... #{
              inspect(_responses)
            }"
          )

        state =
          case init(config_from(conn)) do
            {:ok, recycle_state} ->
              put_in(state.conn, recycle_state.conn)

            {:error, reason} ->
              _ =
                Lager.error("Could not recycle connection: #{inspect(reason)}")

              state
          end

        {:noreply, state}

      {:error, conn, %Mint.HTTPError{reason: reason}, _responses} ->
        _ =
          Lager.emergency("HTTP ERROR: #{inspect(reason)}")

        {:noreply, state}

      :unknown ->
        _ = Lager.warning("Unknown message: " <> inspect(message))
        {:noreply, state}

      message ->
        _ = Lager.error("Unhandled Message: " <> inspect(message))
        {:noreply, state}
    end
  end

  defp process_response({:status, request_ref, status}, state) do
    put_in(state.requests[request_ref].response[:status], status)
  end

  defp process_response({:headers, request_ref, headers}, state) do
    put_in(state.requests[request_ref].response[:headers], headers)
  end

  defp process_response({:data, request_ref, new_data}, state) do
    update_in(state.requests[request_ref].response[:data], fn data ->
      (data || "") <> new_data
    end)
  end

  defp process_response({:done, request_ref}, state) do
    {%{response: response, from: from}, state} =
      pop_in(state.requests[request_ref])

    GenServer.reply(from, {:ok, response})
    state
  end

  defp config_from(%Mint.HTTP1{host: host, port: port, scheme_as_string: scheme}) do
    {scheme |> String.to_atom(), host, port}
  end
end
