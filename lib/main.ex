defmodule Exas do
  alias Exas.AiWrapper

  def start() do
    loop(0)
  end

  defp loop(offset) do
    case Telegex.get_updates(offset: offset) do
      {:ok, updates} ->
        new_offset =
          Enum.reduce(updates, offset, fn update, acc_offset ->
            handle_update(update)
            max(update.update_id + 1, acc_offset)
          end)

        loop(new_offset)

      {:error, _} ->
        nil
        :timer.sleep(1000)
        loop(offset)
    end
  end

  defp handle_update(update) do
    db = Exas.DbServer.get_conn()
    message = update.message
    %{chat: %{id: chat_id}} = message
    %{current_chat: chat, id: id} = Exas.Sql.get_current_info(db)

    if id != chat_id |> Integer.to_string() do
      IO.inspect(id, label: "id")
      IO.inspect(chat_id, label: "chat_id")
      IO.puts("got: #{chat_id}, expected: #{id}")
      Telegex.send_message(chat_id, "not allowed")
    else
      history =
        Exas.Sql.list_msg(db, chat) |> Enum.map(fn h -> %{role: h.role, content: h.content} end)

      case {message.text, message.voice} do
        {text, _} when is_binary(text) ->
          case text do
            "/new" ->
              Telegex.send_message(chat_id, "history cleaned")
              Exas.Sql.create_info(db, EnvConfig.get_chat_id(), Nanoid.generate(10))

            msg ->
              {:ok, _, c} =
                Exas.AiWrapper.handle_chat(history ++ [%{role: "user", content: msg}])

              Telegex.send_message(chat_id, c)

              Exas.Sql.create_msg(db, msg, "user", chat)
              Exas.Sql.create_msg(db, c, "assistant", chat)
          end

        {_, %Telegex.Type.Voice{} = voice} ->
          {:ok, text, ogg_path, mp3_path} = handle_voice(voice.file_id)

          {:ok, _, c} =
            Exas.AiWrapper.handle_chat(history ++ [%{role: "user", content: text}])

          Telegex.send_message(chat_id, c)

          Exas.Sql.create_msg(db, text, "user", chat)
          Exas.Sql.create_msg(db, c, "assistant", chat)
          delete_voice(ogg_path, mp3_path)

        {a, b} ->
          "TGAPI: got something else" |> IO.puts()
          "text" |> IO.puts()
          a |> IO.inspect()
          "voice" |> IO.puts()
          b |> IO.inspect()
      end
    end
  end

  def handle_voice(id) do
    random_id = Nanoid.generate(20)
    ogg_path = random_id <> ".ogg"
    mp3_path = random_id <> ".mp3"
    {:ok, _} = TelegramVoiceDownloader.download_voice(id, ogg_path)
    {:ok, _} = TelegramVoiceDownloader.ogg_to_mp3(ogg_path, mp3_path)

    case AiWrapper.transcribe(mp3_path) do
      {:ok, text} ->
        {:ok, text, ogg_path, mp3_path}

      _ ->
        :error
    end
  end

  def delete_voice(ogg_path, mp3_path) do
    case {File.rm(ogg_path), File.rm(mp3_path)} do
      {:ok, :ok} ->
        IO.puts("files deleted")

      {{:error, reason}, {:error, reason2}} ->
        IO.puts("some error happend while deleting ogg,mp3 files")
        IO.inspect(reason)
        IO.inspect(reason2)
    end
  end
end
