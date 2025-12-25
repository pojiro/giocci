defmodule GiocciEngine.Worker do
  use GenServer

  require Logger

  @worker_name __MODULE__

  # API

  def register_engine(relay_name, opts \\ []) do
    GenServer.call(@worker_name, {:register_engine, relay_name, opts})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @worker_name)
  end

  def init(args) do
    engine_name = Keyword.fetch!(args, :engine_name)
    key_prefix = Keyword.get(args, :key_prefix, "")

    {:ok, session_id} =
      Zenohex.Config.default()
      |> Zenohex.Config.update_in(["mode"], fn _ -> "client" end)
      |> Zenohex.Session.open()

    save_module_key = Path.join(key_prefix, "giocci/save_module/relay/#{engine_name}")

    {:ok, save_module_queryable_id} =
      Zenohex.Session.declare_queryable(session_id, save_module_key)

    exec_func_key = Path.join(key_prefix, "giocci/exec_func/client/#{engine_name}")

    {:ok, exec_func_queryable_id} =
      Zenohex.Session.declare_queryable(session_id, exec_func_key)

    exec_func_async_key = Path.join(key_prefix, "giocci/exec_func_async/client/#{engine_name}")

    {:ok, exec_func_async_subscriber_id} =
      Zenohex.Session.declare_subscriber(session_id, exec_func_async_key)

    {:ok,
     %{
       engine_name: engine_name,
       session_id: session_id,
       key_prefix: key_prefix,
       save_module_key: save_module_key,
       save_module_queryable_id: save_module_queryable_id,
       exec_func_key: exec_func_key,
       exec_func_queryable_id: exec_func_queryable_id,
       exec_func_async_key: exec_func_async_key,
       exec_func_async_subscriber_id: exec_func_async_subscriber_id
     }}
  end

  def handle_call({:register_engine, relay_name, opts}, _from, state) do
    engine_name = state.engine_name
    session_id = state.session_id
    key_prefix = state.key_prefix

    timeout = Keyword.get(opts, :timeout, 100)

    send_term = %{engine_name: engine_name}

    result =
      with key <- Path.join(key_prefix, "giocci/register/engine/#{relay_name}"),
           {:ok, binary} <- encode(send_term),
           {:ok, binary} <- zenohex_get(session_id, key, timeout, binary),
           {:ok, :ok = _recv_term} <- decode(binary) do
        :ok
      end

    {:reply, result, state}
  end

  # for GiocciRelay.save_module/3
  def handle_info(
        %Zenohex.Query{key_expr: save_module_key, payload: binary, zenoh_query: zenoh_query},
        %{save_module_key: save_module_key} = state
      ) do
    result =
      with {:ok, %{module_object_code: {module, binary, filename}}} <- decode(binary),
           {:module, _module} <- :code.load_binary(module, filename, binary) do
        :ok
      end

    {:ok, binary} = encode(result)
    :ok = Zenohex.Query.reply(zenoh_query, save_module_key, binary)

    {:noreply, state}
  end

  # for GiocciClient.exec_func/3
  def handle_info(
        %Zenohex.Query{key_expr: exec_func_key, payload: binary, zenoh_query: zenoh_query},
        %{exec_func_key: exec_func_key} = state
      ) do
    result =
      with {:ok, %{mfargs: mfargs}} <- decode(binary),
           {:ok, result} <- exec_func(mfargs) do
        result
      end

    {:ok, binary} = encode(result)
    :ok = Zenohex.Query.reply(zenoh_query, exec_func_key, binary)

    {:noreply, state}
  end

  # for GiocciClient.exec_func_async/4
  def handle_info(
        %Zenohex.Sample{key_expr: exec_func_async_key, payload: binary},
        %{exec_func_async_key: exec_func_async_key} = state
      ) do
    session_id = state.session_id
    key_prefix = state.key_prefix

    with {:ok, recv_term} <- decode(binary),
         %{mfargs: mfargs, exec_id: exec_id, client_name: client_name} <- recv_term,
         {:ok, result} <- exec_func(mfargs),
         key <- Path.join(key_prefix, "giocci/exec_func_async/engine/#{client_name}") do
      result =
        {:ok,
         %{
           mfargs: mfargs,
           exec_id: exec_id,
           client_name: client_name,
           result: result
         }}

      {:ok, binary} = encode(result)
      :ok = Zenohex.Session.put(session_id, key, binary)
    end

    {:noreply, state}
  end

  defp zenohex_get(session_id, key, timeout, payload) do
    case Zenohex.Session.get(session_id, key, timeout, payload: payload) do
      {:ok, [%Zenohex.Sample{payload: payload}]} ->
        {:ok, payload}

      {:error, :timeout} ->
        {:error, :timeout}

      {:error, reason} ->
        {:error, "Zenohex.Session.get/4 error: #{inspect(reason)}"}
    end
  end

  defp encode(term) do
    {:ok, :erlang.term_to_binary(term)}
  end

  defp decode(payload) do
    {:ok, :erlang.binary_to_term(payload)}
  rescue
    ArgumentError -> {:error, :decode_failed}
  end

  defp exec_func({m, f, args} = mfargs) do
    {:ok, apply(m, f, args)}
  rescue
    UndefinedFunctionError ->
      {:error, "#{inspect(mfargs)} not defined"}
  end
end
