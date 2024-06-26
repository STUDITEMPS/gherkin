defmodule Gherkin.ParserTest do
  use ExUnit.Case
  import Gherkin.Parser
  alias Gherkin.Elements.Rule
  alias Gherkin.Elements.Step
  alias Gherkin.Elements.Feature

  @feature_text """
    Funktionalität: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      Szenario: Buy last coffee
        Angenommen there are 1 coffees left in the machine
        Und I have deposited 1$
        Wenn I press the coffee button
        Dann I should be served a coffee

      Szenario: Be sad that no coffee is left
        Angenommen there are 0 coffees left in the machine
        Und I have deposited 1$
        Wenn I press the coffee button
        Dann I should be frustrated
  """

  @feature_with_backgroundtext """
  Funktionalität: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

    Grundlage:
      Angenommen coffee exists as a beverage
      Und there is a coffee machine

    Szenario: Buy last coffee
      Angenommen there are 1 coffees left in the machine
      Und I have deposited 1$
      Wenn I press the coffee button
      Dann I should be served a coffee
  """

  @feature_with_single_feature_tag """
  @beverage
  Funktionalität: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Szenario: Buy last coffee
    Angenommen there are 1 coffees left in the machine
  """

  @feature_with_value_feature_tag """
  @cost 1
  Funktionalität: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Szenario: Buy last coffee
    Angenommen there are 1 coffees left in the machine
  """

  @feature_with_multiple_feature_tag """
  @beverage @coffee
  @caffeine
  Funktionalität: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Szenario: Buy last coffee
    Angenommen there are 1 coffees left in the machine
  """

  @feature_with_step_with_table """
  Funktionalität: Have tables
    Sometimes data is a table

    Szenario: I have a step with a table
      Angenommen the following table
      | Column one | Column two |
      | Hello      | World      |
      Dann everything should be okay
  """

  @feature_with_step_with_table_containing_pipes ~S"""
  Funktionalität: Have tables
    Sometimes data is a table

    Szenario: I have a step with a table
      Angenommen the following table
      | Column one | Column two              |
      | Hello      | World                   |
      | Goodbye    | It's all\|folks!        |
      | Goodbye    | It's\|all\|folks!       |
      | Goodbye    | Backslash and pipe: \\| |
      Dann everything should be okay
  """

  @feature_with_doc_string "
  Funktionalität: Have tables
    Sometimes data is a table

    Szenario: I have a step with a doc string
      Angenommen the following data
      \"\"\"json
      {
        \"a\": \"b\"
      }
      \"\"\"
      Dann everything should be okay
  "

  @feature_with_scenario_outline """
  Funktionalität: Szenariogrundrisss exist

    Szenariogrundriss: eating
      Angenommen there are <start> cucumbers
      Wenn I eat <eat> cucumbers
      Dann I should have <left> cucumbers

      Beispiele:
        | start | eat | left |
        |  12   |  5  |  7   |
        |  20   |  5  |  15  |
  """

  @feature_with_comments """
    Funktionalität: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      #Only one coffee? this is bad!
      Szenario: Buy last coffee
        Angenommen there are 1 coffees left in the machine
        Und I have deposited 1$
        Wenn I press the coffee button
        # I better get some coffee
        Dann I should be served a coffee
  """

  @feature_with_rule """
    Funktionalität: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      Rule: Coffee must be payed for
        Grundlage:
          Angenommen there are 1 coffees left in the machine

        Szenario: Deposit money before buying coffee
          Angenommen I have deposited 1$
          Wenn I press the coffee button
          Dann I should be served a coffee

        Szenario: Don't deposit money before buying coffee
          Angenommen I press the coffee button
          Dann I should not be served a coffee
  """

  @feature_with_multiple_rules """
    Funktionalität: Barista protocol
      Always greet with a smile
      Always ask for the customer's name

      Rule: In a normal store
        Grundlage:
          Angenommen a customer has approached the till

        Szenario: Customer speaks first
          Angenommen they place an order before Barista can greet
          Dann skip greeting and ask name
          Und serve with a smile

        Szenario: Barista speaks first
          Angenommen Barista greets first
          Dann say common greeting and ask for order and name
          Und serve with a smile

      Rule: In the Pentagon
        For security purposes no names can be used at this location

        Grundlage:
          Angenommen a customer has approached the till

        Szenario: Customer speaks first
          Angenommen they place an order before Barista can greet
          Dann skip greeting and give customer a unique order number
          Und serve with a smile

        Szenario: Barista speaks first
          Angenommen Barista greets first
          Dann say common greeting and ask for order and give customer a unique order number
          Und serve with a smile
  """

  test "binary and stream is parsed exaclty the same" do
    from_binary =
      "test/fixtures/coffee.feature"
      |> File.read!()
      |> parse_feature()

    from_stream =
      "test/fixtures/coffee.feature"
      |> File.stream!()
      |> parse_feature()

    assert from_binary == from_stream
  end

  test "Parses the feature name" do
    assert %Feature{name: name, line: 1} = parse_feature(@feature_text)
    assert name == "Serve coffee"
  end

  test "Parses the feature description" do
    assert %Feature{description: description, line: 1} = parse_feature(@feature_text)

    assert description == """
           Coffee should not be served until paid for
           Coffee should not be served until the button has been pressed
           If there is no coffee left then money should be refunded
           """
  end

  test "reads in the correct number of scenarios" do
    assert %Feature{scenarios: scenarios, line: 1} = parse_feature(@feature_text)
    assert Enum.count(scenarios) == 2
  end

  test "Gets the scenario's name" do
    assert %Feature{scenarios: [%{name: name} | _], line: 1} = parse_feature(@feature_text)
    assert name == "Buy last coffee"
  end

  test "Gets the correct number of steps for the scenario" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} = parse_feature(@feature_text)
    assert Enum.count(steps) == 4
  end

  test "Has the correct steps for a scenario" do
    expected_steps = [
      %Step{keyword: "Angenommen", text: "there are 1 coffees left in the machine", line: 7},
      %Step{keyword: "Und", text: "I have deposited 1$", line: 8},
      %Step{keyword: "Wenn", text: "I press the coffee button", line: 9},
      %Step{keyword: "Dann", text: "I should be served a coffee", line: 10}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_text)
    assert expected_steps == steps
  end

  test "Parses the expected background steps" do
    expected_steps = [
      %Step{keyword: "Angenommen", text: "coffee exists as a beverage", line: 7},
      %Step{keyword: "Und", text: "there is a coffee machine", line: 8}
    ]

    %{background_steps: background_steps} = parse_feature(@feature_with_backgroundtext)
    assert expected_steps == background_steps
  end

  test "Reads a doc string in to the correct step" do
    expected_data = "{\n  \"a\": \"b\"\n}\n"

    expected_steps = [
      %Step{keyword: "Angenommen", text: "the following data", doc_string: expected_data, line: 5},
      %Step{keyword: "Dann", text: "everything should be okay", line: 11}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_doc_string)
    assert expected_steps == steps
  end

  test "Reads a table in to the correct step" do
    expected_table_data = [
      %{:"Column one" => "Hello", :"Column two" => "World"}
    ]

    expected_steps = [
      %Step{
        keyword: "Angenommen",
        text: "the following table",
        table_data: expected_table_data,
        line: 5
      },
      %Step{keyword: "Dann", text: "everything should be okay", line: 8}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_step_with_table)
    assert expected_steps == steps
  end

  test "Reads in a table containing pipes to the correct step" do
    expected_table_data = [
      %{:"Column one" => "Hello", :"Column two" => "World"},
      %{:"Column one" => "Goodbye", :"Column two" => "It's all|folks!"},
      %{:"Column one" => "Goodbye", :"Column two" => "It's|all|folks!"},
      %{:"Column one" => "Goodbye", :"Column two" => "Backslash and pipe: \\|"}
    ]

    expected_steps = [
      %Step{
        keyword: "Angenommen",
        text: "the following table",
        table_data: expected_table_data,
        line: 5
      },
      %Step{keyword: "Dann", text: "everything should be okay", line: 11}
    ]

    %{scenarios: [%{steps: steps} | _]} =
      parse_feature(@feature_with_step_with_table_containing_pipes)

    assert expected_steps == steps
  end

  test "Reads Szenariogrundrisss correctly" do
    expected_example_data = [
      %{start: "12", eat: "5", left: "7"},
      %{start: "20", eat: "5", left: "15"}
    ]

    expected_steps = [
      %Step{keyword: "Angenommen", text: "there are <start> cucumbers", line: 4},
      %Step{keyword: "Wenn", text: "I eat <eat> cucumbers", line: 5},
      %Step{keyword: "Dann", text: "I should have <left> cucumbers", line: 6}
    ]

    %{scenarios: [%{steps: steps, examples: examples} | _]} =
      parse_feature(@feature_with_scenario_outline)

    assert expected_steps == steps
    assert expected_example_data == examples
  end

  test "Commented out lines are ignored" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} =
             parse_feature(@feature_with_comments)

    # Only should be 4 steps as the commented out line should be ignored
    assert Enum.count(steps) == 4
  end

  test "file streaming" do
    assert %Gherkin.Elements.Feature{} =
             File.stream!("test/fixtures/coffee.feature") |> parse_feature()
  end

  test "Reads a feature with a single tag" do
    assert %{tags: [:beverage]} = parse_feature(@feature_with_single_feature_tag)
  end

  test "Reads a feature with a value tag" do
    assert %{tags: [{:cost, 1}]} = parse_feature(@feature_with_value_feature_tag)
  end

  test "Reads a feature with a multiple tags" do
    assert %{tags: [:beverage, :coffee, :caffeine]} =
             parse_feature(@feature_with_multiple_feature_tag)
  end

  test "Reads a feature with a rule" do
    assert %{rules: [%Rule{} = _]} = parse_feature(@feature_with_rule)
  end

  test "Reads a feature with multiple rules" do
    assert %{rules: [%Rule{}, %Rule{}]} = parse_feature(@feature_with_multiple_rules)
  end
end
