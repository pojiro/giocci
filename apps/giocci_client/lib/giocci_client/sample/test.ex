defmodule GiocciClient.Sample.Test do
  @moduledoc false

  require Logger

  def exec(relay_name) do
    :ok = GiocciClient.register_client(relay_name)
    Logger.info("register_client/1 success!")

    :ok = GiocciClient.save_module(relay_name, GiocciClient.Sample.Module)
    Logger.info("save_module/2 success!")

    mfargs = {GiocciClient.Sample.Module, :add, [1, 2]}

    3 = GiocciClient.exec_func(relay_name, mfargs)
    Logger.info("exec_func/2 success!")

    :ok = GiocciClient.exec_func_async(relay_name, mfargs, self())
    Logger.info("exec_func_async/3 success!")

    receive do
      {:giocci_client, 3} ->
        Logger.info("exec_func_async/3 success!")
    end

    :ok
  end
end
