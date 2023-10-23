defmodule Gherkin.Parsers.DescriptionParser do
  @moduledoc false

  def build_description(map, [line | lines] = all_lines) do
    if starts_with_keyword?(line.text) do
      {map, all_lines}
    else
      build_description(%{map | description: map.description <> line.text <> "\n"}, lines)
    end
  end

  @all_keywords [
    "@",
    "Funktionalität",
    "Rule",
    "Grundlage",
    "Beispiele",
    "Szenario",
    ~s{"""},
    "Angenommen",
    "Dann",
    "Und",
    "Aber"
  ]
  defp starts_with_keyword?(line) do
    String.starts_with?(line, @all_keywords)
  end
end
