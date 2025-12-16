defmodule GiocciEngine do
  @moduledoc """
  Documentation for `GiocciEngine`.
  """

  @doc """
  """
  @spec register_engine(String.t(), keyword()) :: :ok | {:error, reason :: term()}
  defdelegate register_engine(relay_name, opts \\ []), to: GiocciEngine.Worker
end
