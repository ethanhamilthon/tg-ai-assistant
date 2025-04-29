defmodule Exas.AiWrapper do
  import EnvConfig

  @system """
  be consise and blunt
  """

  def run_chat(history) do
    # print history for logging purpuses
    "--- History" |> IO.puts()
    history = [%{role: "developer", content: @system}] ++ history

    history
    |> Enum.map(fn %{role: role, content: c} -> "#{role}: #{c}" end)
    |> Enum.join("\n")
    |> IO.puts()

    "--- History end" |> IO.puts()

    OpenAI.chat_completion(
      [
        model: get_openai_model(),
        messages: history,
        n: 1,
        tools: get_tool_defs()
      ],
      %OpenAI.Config{
        api_key: get_openai_token()
      }
    )
  end

  def handle_chat(history) do
    case run_chat(history) do
      {:error, e} ->
        IO.inspect(e)
        :error

      {:ok, data} ->
        # IO.inspect(data)
        content = data[:choices] |> Enum.at(0) |> Map.get("message")

        case {content["content"], content["tool_calls"]} do
          {c, _} when not is_nil(c) ->
            # IO.puts(c)
            h = history ++ [%{role: "assistant", content: c}]
            {:ok, h, c}

          {_, f} when not is_nil(f) ->
            h =
              (history ++ [%{role: "assistant", tool_calls: f}]) ++
                (f |> Enum.map(fn c -> call_fn(c) end))

            handle_chat(h)
        end
    end
  end

  def call_fn(call) do
    id = call["id"]
    # name = call["function"]["name"]

    output =
      case Jason.decode(call["function"]["arguments"]) do
        {:error, r} ->
          IO.puts(r.data)
          "some error"

        {:ok, map} ->
          # fake fn call
          map["location"] <> " is sunny"
      end

    %{role: "tool", tool_call_id: id, content: output}
  end

  def get_tool_defs do
    [
      %{
        type: "function",
        function: %{
          name: "get_weather",
          description: "Get current temperature for a given location.",
          parameters: %{
            type: "object",
            properties: %{
              location: %{
                type: "string",
                description: "City and country e.g. Bogotá, Colombia"
              }
            },
            required: [
              "location"
            ],
            additionalProperties: false
          },
          strict: true
        }
      }
    ]
  end

  def transcribe(path) do
    case OpenAI.audio_transcription(
           # file path
           path,
           [
             model: "gpt-4o-transcribe"
           ],
           %OpenAI.Config{
             api_key: get_openai_token()
           }
         ) do
      {:ok, %{text: text}} ->
        IO.puts(text)
        {:ok, text}

      {:error, reason} ->
        IO.puts(reason)
        :error
    end
  end
end
