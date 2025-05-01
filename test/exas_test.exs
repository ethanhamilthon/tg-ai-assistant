defmodule ExasTest do
  use ExUnit.Case
  import Exas.Sql
  doctest Exas

  test "full db test" do
    conn = connect(":memory:")
    migrate(conn)
    create_default_info(conn, "some_id", "first")
    create_msg(conn, "hello", "user", "first")
    create_msg(conn, "hellod", "assistant", "first")
    create_msg(conn, "hellod", "assistant", "dd")
    msgs = list_msg(conn, "first")
    IO.inspect(msgs)
    assert length(msgs) == 2
  end

  test "info db test" do
    conn = connect(":memory:")
    migrate(conn)
    create_default_info(conn, "some_id", "first")
    create_default_info(conn, "some_id", "first")
    create_default_info(conn, "some_id", "first")
    create_default_info(conn, "some_id", "first")
    info = get_current_info(conn)
    assert info.id == "some_id"
    assert length(list_infos(conn)) === 1

    create_info(conn, "some_id", "second")
    info = get_current_info(conn)
    assert info.current_chat === "second"
    infos = list_infos(conn)
    infos |> IO.inspect()
    assert length(infos) === 2
  end

  test "task database test" do
    conn = connect(":memory:")
    migrate(conn)

    create_task(conn, Nanoid.generate(16), "first task", "desc")
    tasks = list_tasks(conn)

    assert length(tasks) == 1
    assert Enum.at(tasks, 0).title == "first task"

    update_task(conn, Enum.at(tasks, 0).id, "updated task", "desc")
    tasks = list_tasks(conn)

    assert length(tasks) == 1
    assert Enum.at(tasks, 0).title == "updated task"

    Enum.at(tasks, 0) |> IO.inspect()

    delete_task(conn, Enum.at(tasks, 0).id)
    tasks = list_tasks(conn)

    assert length(tasks) == 0
  end
end
