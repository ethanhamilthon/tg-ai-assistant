defmodule Exas.Application do
  use Application

  def start(_type, _args) do
    # Запуск вашего кода
    IO.puts("Starting Exas...")
    EnvConfig.init()

    # Инициализация и настройка базы данных
    "running db in #{EnvConfig.get_db_path()}" |> IO.puts()
    db = Exas.Sql.connect(EnvConfig.get_db_path())

    Exas.Sql.migrate(db)
    Exas.Sql.create_default_info(db, EnvConfig.get_chat_id(), "first")

    # Запуск блокирующего кода в отдельном процессе
    Task.start(fn -> Exas.start(db) end)

    # Возвращаем дочерние процессы
    children = []

    # Настройки супервизора
    opts = [strategy: :one_for_one, name: Exas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
