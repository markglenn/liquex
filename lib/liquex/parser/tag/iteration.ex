defmodule Liquex.Parser.Tag.Iteration do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Tag.Conditional

  @spec for_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def for_expression(combinator \\ empty()) do
    combinator
    |> for_in_tag()
    |> tag(parsec(:document), :contents)
    |> tag(:for)
    |> optional(Conditional.else_tag())
    |> ignore(Tag.tag_directive("endfor"))
  end

  @spec cycle_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def cycle_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("cycle"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(cycle_group() |> unwrap_and_tag(:group))
    |> tag(argument_sequence(), :sequence)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:cycle)
  end

  defp argument_sequence(combinator \\ empty()) do
    combinator
    |> Literal.argument()
    |> repeat(
      ignore(string(","))
      |> ignore(Literal.whitespace())
      |> Literal.argument()
    )
  end

  defp for_in_tag(combinator) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("for"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end

  defp reversed(combinator \\ empty()) do
    combinator
    |> ignore(Literal.whitespace())
    |> replace(string("reversed"), :reversed)
    |> unwrap_and_tag(:order)
  end

  defp collection(combinator \\ empty()) do
    combinator
    |> choice([Literal.range(), Literal.argument()])
    |> repeat(
      ignore(Literal.whitespace(empty(), 1))
      |> choice([reversed(), limit(), offset()])
    )
  end

  defp limit(combinator \\ empty()) do
    combinator
    |> ignore(string("limit:"))
    |> unwrap_and_tag(integer(min: 1), :limit)
  end

  defp offset(combinator \\ empty()) do
    combinator
    |> ignore(string("offset:"))
    |> unwrap_and_tag(integer(min: 1), :offset)
  end

  defp cycle_group(combinator \\ empty()) do
    combinator
    |> Literal.literal()
    |> ignore(string(":"))
    |> ignore(Literal.whitespace())
  end
end