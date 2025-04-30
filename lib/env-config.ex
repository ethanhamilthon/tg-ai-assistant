defmodule EnvConfig do
  def init do
    case get!("MIX_ENV") do
      "dev" ->
        :ok = DotenvParser.load_file(".env")
        :ok

      "prod" ->
        :ok = DotenvParser.load_file(".env.prod")
        :ok
    end
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
