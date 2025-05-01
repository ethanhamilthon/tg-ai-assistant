defmodule Exas.Tools do
  def get_full_definitions() do
    definitions()
    |> Enum.map(fn %{name: name, description: d, properties: p} ->
      %{
        type: "function",
        function: %{
          name: name,
          description: d,
          parameters: %{
            type: "object",
            properties: p,
            required: Map.keys(p) |> Enum.map(&to_string/1),
            additionalProperties: false
          },
          strict: true
        }
      }
    end)
  end

  def call_functions(name, args) do
    IO.puts("calling #{name}")
    IO.puts("args #{args}")

    case definitions() |> Enum.find(fn d -> d.name === name end) do
      nil ->
        "tool #{name} not found"

      tool ->
        tool.call.(Jason.decode!(args))
    end
  end

  defp definitions() do
    [
      %{
        call: fn args ->
          db = Exas.DbServer.get_conn()
          # logging
          "list_tasks is calling" |> IO.puts()
          IO.inspect(args)

          # calling
          tasks = Exas.Sql.list_tasks(db)

          # encoding to json
          case Jason.encode(tasks) do
            {:ok, s} -> s
            {:error, reason} -> "list tasks failed: #{reason}"
          end
        end,
        name: "list_tasks",
        description: "Returns all user's tasks",
        properties: %{}
      },
      %{
        call: fn args ->
          db = Exas.DbServer.get_conn()
          # logging
          "create_task is calling" |> IO.puts()
          IO.inspect(args)

          # calling
          id = Nanoid.generate(16)
          Exas.Sql.create_task(db, id, args["title"], args["description"])

          # encoding to json
          "new task created with id = #{id}}"
        end,
        name: "create_task",
        description: "Creates a new task",
        properties: %{
          title: %{
            type: "string",
            description: "Title of the task"
          },
          description: %{
            type: "string",
            description: "Description of the task"
          }
        }
      },
      %{
        call: fn args ->
          db = Exas.DbServer.get_conn()
          # logging
          "update_task is calling" |> IO.puts()
          IO.inspect(args)

          # calling
          Exas.Sql.update_task(db, args["id"], args["title"], args["description"])

          # encoding to json
          "task updated"
        end,
        name: "update_task",
        description: "Updates the existing task",
        properties: %{
          id: %{
            type: "string",
            description: "ID of the task"
          },
          title: %{
            type: "string",
            description: "Title of the task"
          },
          description: %{
            type: "string",
            description: "Description of the task"
          }
        }
      },
      %{
        call: fn args ->
          db = Exas.DbServer.get_conn()
          # logging
          "delete_task is calling" |> IO.puts()
          IO.inspect(args)

          # calling
          Exas.Sql.delete_task(db, args["id"])

          # encoding to json
          "task deleted"
        end,
        name: "delete_task",
        description: "Deletes the existing task by ID",
        properties: %{
          id: %{
            type: "string",
            description: "ID of the task"
          }
        }
      }
    ]
  end
end
