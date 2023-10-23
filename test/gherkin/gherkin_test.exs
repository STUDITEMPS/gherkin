defmodule Gherkin.GherkinTest do
  use ExUnit.Case
  alias Gherkin.Elements.Step

  doctest Gherkin

  @file_name "test/fixtures/coffee.feature"
  test "parsing" do
    assert %Gherkin.Elements.Feature{scenarios: _scenarios, file: @file_name} =
             Gherkin.parse_file(@file_name)
  end

  @outline """
  Funktionalität: Serve coffee

    Szenariogrundriss: Buy coffee
      Angenommen there are <coffees> coffees left in the machine
      Und I have deposited $<money>
      Wenn I press the coffee button
      Dann I should be served <served> coffees

      Beispiele:
        | coffees | money | served |
        |  12     |  6    |  12    |
        |  2      |  3    |  2     |
  """

  test "changing an outline into a scenario" do
    assert %Gherkin.Elements.Feature{line: 1} = feature = @outline |> Gherkin.parse()

    assert [
             %Gherkin.Elements.Scenario{
               name: "Buy coffee (Example 1)",
               line: 3,
               steps: [
                 %Step{
                   keyword: "Angenommen",
                   text: "there are 12 coffees left in the machine",
                   line: 4
                 },
                 %Step{keyword: "Und", text: "I have deposited $6", line: 5},
                 %Step{keyword: "Wenn", text: "I press the coffee button", line: 6},
                 %Step{keyword: "Dann", text: "I should be served 12 coffees", line: 7}
               ]
             },
             %Gherkin.Elements.Scenario{
               name: "Buy coffee (Example 2)",
               line: 3,
               steps: [
                 %Step{
                   keyword: "Angenommen",
                   text: "there are 2 coffees left in the machine",
                   line: 4
                 },
                 %Step{keyword: "Und", text: "I have deposited $3", line: 5},
                 %Step{keyword: "Wenn", text: "I press the coffee button", line: 6},
                 %Step{keyword: "Dann", text: "I should be served 2 coffees", line: 7}
               ]
             }
           ] = Gherkin.scenarios_for(feature.scenarios |> hd)
  end

  test "flattening a feature into scenarios" do
    feature = @outline |> Gherkin.parse()

    assert %Gherkin.Elements.Feature{
             scenarios: [%Gherkin.Elements.Scenario{}, %Gherkin.Elements.Scenario{}]
           } = Gherkin.flatten(feature)
  end
end
