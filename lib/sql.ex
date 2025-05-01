defmodule Exas.Sql do
  defmodule Message do
    @derive Jason.Encoder
    defstruct [:id, :content, :role, :chat]
  end

  defmodule Info do
    @derive Jason.Encoder
    defstruct [:id, :current_chat, :created_at]
  end

  defmodule UserTask do
    @derive Jason.Encoder
    defstruct [:id, :title, :description]
  end

  @spec connect(binary()) :: Exqlite.Sqlite3.db()
  def connect(path) do
    case Exqlite.Sqlite3.open(path) do
      {:ok, db} ->
        db

      {:error, r} ->
        raise r
    end
  end

  def migrate(db) do
    :ok =
      Exqlite.Sqlite3.execute(
        db,
        """
        create table if not exists messages (
          id text primary key,
          content text not null,
          role text not null,
          chat text not null
        );

        create table if not exists infos (
          id text not null,
          current_chat text not null,
          created_at text not null
        );

        create table if not exists tasks (
          id text not null,
          title text not null,
          description text not null
        )
        """
      )
  end

  def create_msg(db, content, role, chat) do
    id = Nanoid.generate(16)

    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        "INSERT INTO messages (id, content, role, chat) VALUES (?, ?, ?, ?)"
      )

    :ok = Exqlite.Sqlite3.bind(stt, [id, content, role, chat])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def create_default_info(db, id, chat_name) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        INSERT INTO infos (id, current_chat, created_at)
        SELECT ?, ?, ?
        WHERE NOT EXISTS (SELECT 1 FROM infos);
        """
      )

    :ok = Exqlite.Sqlite3.bind(stt, [id, chat_name, DateTime.utc_now() |> DateTime.to_iso8601()])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def create_info(db, id, chat_name) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        INSERT INTO infos (id, current_chat, created_at) VALUES (?,?,?)
        """
      )

    :ok = Exqlite.Sqlite3.bind(stt, [id, chat_name, DateTime.utc_now() |> DateTime.to_iso8601()])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def create_task(db, id, title, desc) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        INSERT INTO tasks (id, title, description) VALUES (?,?,?)
        """
      )

    :ok = Exqlite.Sqlite3.bind(stt, [id, title, desc])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def update_task(db, id, title, desc) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        UPDATE tasks
        SET title = ?, description = ?
        WHERE id = ?;
        """
      )

    :ok = Exqlite.Sqlite3.bind(stt, [title, desc, id])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def delete_task(db, id) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        DELETE FROM tasks
        WHERE id = ?;
        """
      )

    :ok = Exqlite.Sqlite3.bind(stt, [id])
    :done = Exqlite.Sqlite3.step(db, stt)
    :ok = Exqlite.Sqlite3.release(db, stt)
  end

  def get_current_info(db) do
    {:ok, stt} =
      Exqlite.Sqlite3.prepare(
        db,
        """
        SELECT * FROM infos ORDER BY created_at DESC LIMIT 1
        """
      )

    {:row, [id, current_chat, created_at]} = Exqlite.Sqlite3.step(db, stt)

    %Info{
      id: id,
      current_chat: current_chat,
      created_at: created_at
    }
  end

  def list_infos(db) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, "SELECT * FROM infos ")

    fetch_all_rows(db, stmt)
    |> Enum.map(fn [id, current_chat, created_at] ->
      %Info{
        id: id,
        current_chat: current_chat,
        created_at: created_at
      }
    end)
  end

  def list_msg(db, chat) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, "SELECT * FROM messages where chat = ?")
    :ok = Exqlite.Sqlite3.bind(stmt, [chat])

    fetch_all_rows(db, stmt)
    |> Enum.map(fn [id, content, role, chat] ->
      %Message{
        id: id,
        content: content,
        role: role,
        chat: chat
      }
    end)
  end

  def list_tasks(db) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, "SELECT * FROM tasks")

    fetch_all_rows(db, stmt)
    |> Enum.map(fn [id, title, description] ->
      %UserTask{
        id: id,
        title: title,
        description: description
      }
    end)
  end

  defp fetch_all_rows(conn, stmt) do
    Stream.repeatedly(fn -> Exqlite.Sqlite3.step(conn, stmt) end)
    |> Enum.take_while(fn
      :done -> false
      {:row, _} -> true
    end)
    |> Enum.map(fn {:row, values} ->
      values
    end)
  end
end
