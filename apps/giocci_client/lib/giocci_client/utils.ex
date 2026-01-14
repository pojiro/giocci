defmodule GiocciClient.Utils do
  @moduledoc false

  def zenohex_get(session_id, key, timeout, payload) do
    case Zenohex.Session.get(session_id, key, timeout, payload: payload) do
      {:ok, [%Zenohex.Sample{payload: payload}]} ->
        {:ok, payload}

      {:error, :timeout} ->
        {:error, "timeout"}

      {:error, reason} ->
        {:error, "zenohex_error: #{inspect(reason)}"}
    end
  rescue
    ArgumentError -> {:error, "zenohex_error: badarg"}
  end

  def encode(term) do
    {:ok, :erlang.term_to_binary(term)}
  end

  def decode(payload) do
    # We pass the `safe` option to protect user's Erlang VM.
    {:ok, :erlang.binary_to_term(payload, [:safe])}
  rescue
    ArgumentError -> {:error, "decode_failed: payload may contain unknown atoms or unsafe terms"}
  end
end
