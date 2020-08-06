defmodule Hui.Query.HighlighterFastVectorTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.HighlighterFastVector.new()
    assert x.__struct__ == Query.HighlighterFastVector

    {alt_field, len, highlight} = {"description", 500, false}

    x = Query.HighlighterFastVector.new(alt_field)
    assert x.alternateField == alt_field
    assert is_nil(x.maxAlternateFieldLength)
    assert is_nil(x.highlightAlternate)

    x = Query.HighlighterFastVector.new(alt_field, len, highlight)
    assert x.alternateField == alt_field
    assert x.maxAlternateFieldLength == len
    assert x.highlightAlternate == highlight
  end
end
