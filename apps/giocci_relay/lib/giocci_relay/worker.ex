defmodule GiocciRelay.Worker do
  use GenServer

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    relay_name = Keyword.fetch!(args, :relay_name)
    key_prefix = Keyword.get(args, :key_prefix, "")

    {:ok, session_id} =
      Zenohex.Config.default()
      |> Zenohex.Config.update_in(["mode"], fn _ -> "client" end)
      |> Zenohex.Session.open()

    register_client_key = Path.join(key_prefix, "giocci/register/client/#{relay_name}")

    {:ok, register_client_queryable_id} =
      Zenohex.Session.declare_queryable(session_id, register_client_key)

    {:ok,
     %{
       relay_name: relay_name,
       session_id: session_id,
       key_prefix: key_prefix,
       register_client_queryable_id: register_client_queryable_id,
       register_client_key: register_client_key
     }}
  end

  @doc """
  for GiocciClient.register_client/2
  """
  def handle_info(
        %Zenohex.Query{key_expr: register_client_key, payload: payload, zenoh_query: zenoh_query},
        %{register_client_key: register_client_key} = state
      ) do
    result =
      case :erlang.binary_to_term(payload) do
        %{client_name: _client_name} ->
          # IMPLEMENT ME
          :ok

        _ ->
          {:error, :invalid_payload}
      end

    :ok = Zenohex.Query.reply(zenoh_query, register_client_key, :erlang.term_to_binary(result))
    {:noreply, state}
  rescue
    ArgumentError ->
      result = {:error, :invalid_erlang_binary}
      :ok = Zenohex.Query.reply(zenoh_query, register_client_key, :erlang.term_to_binary(result))
      {:noreply, state}
  end
end
