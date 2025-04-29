import Config

EnvConfig.init()

config :telegex,
  token: EnvConfig.get_tg_token(),
  caller_adapter: HTTPoison

config :openai,
  http_options: [recv_timeout: :infinity, async: :once]
