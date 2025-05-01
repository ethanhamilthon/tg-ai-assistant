defmodule Exas.DbServer do
  use GenServer

  # API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_conn do
    GenServer.call(__MODULE__, :get_conn)
  end

  # Callbacks

  def init(:ok) do
    path = EnvConfig.get_db_path()
    IO.puts("running db in #{path}")
    db = Exas.Sql.connect(path)

    Exas.Sql.migrate(db)
    Exas.Sql.create_default_info(db, EnvConfig.get_chat_id(), "first")

    {:ok, db}
  end

  def handle_call(:get_conn, _from, db) do
    {:reply, db, db}
  end
end
