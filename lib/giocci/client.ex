defmodule Giocci.Client do
  use GenServer
  require Logger

  @spec module_save(GenServer.name(), module()) :: :ok | {:error, term()}
  def module_save(name, module) when is_atom(module) do
    GenServer.call(name, {:module_save, module})
  end

  @spec module_exec(GenServer.name(), {module(), function(), list()}) :: :ok | {:error, term()}
  def module_exec(name, {module, function, args}) when is_atom(module) do
    GenServer.call(name, {:module_exec, {module, function, args}})
  end

  def start(name) do
    DynamicSupervisor.start_child(Giocci.DynamicSupervisor, {__MODULE__, name: name})
  end

  def stop(name) do
    GenServer.stop(name)
  end

  def start_link(arg) do
    name = Keyword.get(arg, :name)

    GenServer.start_link(__MODULE__, arg, name: name)
  end

  @impl true
  def init(_arg) do
    {:ok, session_id} = Zenohex.Session.open()

    {:ok, subscriber_id} =
      Zenohex.Session.declare_subscriber(
        session_id,
        key_prefix() <> "giocci/relay_to_client/" <> relay_name <> "/" <> my_client_node_name(),
        self()
      )

    {:ok, publisher_id} =
      Zenohex.Session.declare_publisher(
        session_id,
        key_prefix() <> "giocci/client_to_relay/" <> relay_name <> "/" <> my_client_node_name()
      )

    {:ok,
     %{
       session_id: session_id,
       subscriber_id: subscriber_id,
       publisher_id: publisher_id
     }}
  end

  def handle_call({:module_save, module}, _from, state) do
    case :code.get_object_code(module) do
      {_module, _binary, _filename} = tuple ->
        binary = :erlang.term_to_binary({:module_save, tuple})
        reply = send_to_relay(state, binary)
        {:reply, reply, state}

      :error ->
        Logger.error("Failed to find module, module: #{inspect(module)}}")
        {:reply, {:error, :module_not_found}, state}
    end
  end

  def handle_call({:module_exec, {module, function, args}}, _from, state) do
    binary = :erlang.term_to_binary({:module_exec, {module, function, args}})
    reply = send_to_relay(state, binary)
    {:reply, reply, state}
  end

  def handle_info(%Zenohex.Sample{payload: binary}, state) do
    term = :erlang.binary_to_term(binary)

    if is_function(state.callback) do
      state.callback.(term)
    else
      Logger.info("#{inspect(term)}")
    end

    {:noreply, state}
  end

  defp send_to_relay(state, binary) do
    case Zenohex.Publisher.put(state.publisher_id, binary) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send, error: #{inspect(reason)}")
        {:error, :failed_to_send}
    end
  end
end
