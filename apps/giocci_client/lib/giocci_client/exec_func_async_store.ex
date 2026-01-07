defmodule GiocciClient.ExecFuncAsyncStore do
  @moduledoc false

  use GenServer

  @name __MODULE__

  # API

  def get(key, default \\ nil) do
    GenServer.call(@name, {:get, key, default})
  end

  def put(key, value) do
    GenServer.call(@name, {:put, key, value})
  end

  def delete(key) do
    GenServer.call(@name, {:delete, key})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  # callbacks

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call({:get, key, default}, _from, state) do
    {:reply, Map.get(state, key, default), state}
  end

  def handle_call({:put, key, value}, _from, state) do
    {:reply, :ok, Map.put(state, key, value)}
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end
end
