defmodule Gherkin.TagParserTest do
  use ExUnit.Case
  import Gherkin.Parser

  @feature_with_single_feature_tag """
  @beverage
  Funktionalität: Serve coffee
  Coffee should not be served until paid for
  Coffee should not be served until the button has been pressed
  If there is no coffee left then money should be refunded

  Szenario: Buy last coffee
  Angenommen there are 1 coffees left in the machine
  """

  @feature_with_many_feature_tags """
  @beverage @coffee @happy
  Funktionalität: Serve coffee
  Coffee should not be served until paid for
  Coffee should not be served until the button has been pressed
  If there is no coffee left then money should be refunded

  Szenario: Buy last coffee
  Angenommen there are 1 coffees left in the machine
  """

  @scenrio_with_tags """
  Funktionalität: Serve coffee
  Coffee should not be served until paid for
  Coffee should not be served until the button has been pressed
  If there is no coffee left then money should be refunded

  @important
  Szenario: Buy last coffee
  Angenommen there are 1 coffees left in the machine

  Szenario: Buy a bagel
  Angenommen there are bagels
  """

  test "Parses the feature with single tag" do
    %{tags: tags} = parse_feature(@feature_with_single_feature_tag)
    assert tags == [:beverage]
  end

  test "Parses the feature with many tags" do
    %{tags: tags} = parse_feature(@feature_with_many_feature_tags)
    assert tags == [:beverage, :coffee, :happy]
  end

  test "Scenarios don't get feature tags" do
    %{scenarios: [%{tags: scenario_tags}]} = parse_feature(@feature_with_single_feature_tag)
    assert scenario_tags == []
  end

  test "Scenarios can get tags" do
    %{scenarios: [%{tags: scenario_tags} | [%{tags: untagged}]]} =
      parse_feature(@scenrio_with_tags)

    assert untagged == []
    assert scenario_tags == [:important]
  end
end
