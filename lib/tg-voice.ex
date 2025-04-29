defmodule TelegramVoiceDownloader do
  import EnvConfig

  def api_url do
    "https://api.telegram.org/bot#{get_tg_token()}"
  end

  def file_url do
    "https://api.telegram.org/file/bot#{get_tg_token()}"
  end

  def get_file_path(file_id) do
    url = "#{api_url()}/getFile?file_id=#{file_id}"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> get_in(["result", "file_path"])

      error ->
        IO.inspect(error, label: "get_file_path error")
        nil
    end
  end

  # Скачать файл на диск
  def download_voice(file_id, save_as \\ "voice.ogg") do
    case get_file_path(file_id) do
      nil ->
        {:error, :no_file_path}

      path ->
        url = "#{file_url()}/#{path}"

        case HTTPoison.get(url) do
          {:ok, %{status_code: 200, body: body}} ->
            File.write(save_as, body)
            {:ok, save_as}

          error ->
            IO.inspect(error, label: "download_voice error")
            {:error, :download_failed}
        end
    end
  end

  def ogg_to_mp3(input_path, output_path) do
    cmd = "ffmpeg"

    args = [
      "-y",
      "-i",
      input_path,
      "-vn",
      "-ar",
      "44100",
      "-ac",
      "2",
      "-b:a",
      "192k",
      output_path
    ]

    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {_, 0} -> {:ok, output_path}
      {output, code} -> {:error, %{exit_code: code, message: output}}
    end
  end
end
