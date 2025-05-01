defmodule Exas.Application do
  use Application

  def start(_type, _args) do
    IO.puts("Starting Exas...")
    EnvConfig.init()

    children = [
      Exas.DbServer,
      {Task,
       fn ->
         Exas.start()
       end}
    ]

    opts = [strategy: :one_for_one, name: Exas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
