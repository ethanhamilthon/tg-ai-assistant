defmodule EnvConfig do
  def init do
    :ok = DotenvParser.load_file(".env")
    :ok
  end

  @spec get!(String.t()) :: String.t()
  def get!(name) do
    case System.get_env(name) do
      nil -> raise "env #{name} not found"
      s -> s
    end
  end

  def get_openai_token do
    "OPENAI_KEY" |> get!()
  end

  def get_openai_model do
    "OPENAI_MODEL" |> get!()
  end

  def get_db_path do
    "DBPATH" |> get!()
  end

  def get_tg_token do
    "TELEGRAM_TOKEN" |> get!()
  end

  def get_chat_id do
    "TELEGRAM_CHAT_ID" |> get!()
  end
end
