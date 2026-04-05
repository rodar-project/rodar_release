defmodule Relex.Config do
  @moduledoc false

  @config_file ".relex.exs"
  @defaults [
    ai_cmd: {"claude", ["-p"]},
    branch_pre: %{}
  ]

  def get(key) do
    config = read()
    Keyword.get(config, key, Keyword.get(@defaults, key))
  end

  def put(key, value) do
    config = read()
    Process.put(:relex_config, Keyword.put(config, key, value))
  end

  def reset do
    Process.delete(:relex_config)
  end

  defp read do
    case Process.get(:relex_config) do
      nil ->
        config = load()
        Process.put(:relex_config, config)
        config

      config ->
        config
    end
  end

  defp load do
    path = Path.join(File.cwd!(), @config_file)

    if File.exists?(path) do
      {config, _binding} = Code.eval_file(path)

      unless Keyword.keyword?(config) do
        Mix.raise("""
        Invalid .relex.exs format. Expected a keyword list, got: #{inspect(config)}

        Example .relex.exs:

            [
              ai_cmd: {"gemini", ["-p"]},
              branch_pre: %{"staging" => "rc"}
            ]
        """)
      end

      config
    else
      []
    end
  rescue
    e in [SyntaxError, TokenMissingError, CompileError] ->
      Mix.raise("Error reading .relex.exs: #{Exception.message(e)}")
  end
end
