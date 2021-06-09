defmodule Helper.Converter.Article do
  @moduledoc """
  convert body

  {:ok, { body: body, body_html: body_html }} = Converter.Article.body_parse(body)
  """
  import Helper.Utils, only: [done: 1, uid: 0, keys_to_strings: 1]

  alias Helper.Converter.EditorToHTML

  @doc """
  parse article body field
  """
  @spec body_parse(String.t()) :: {:ok, %{body: Map.t(), body_html: String.t()}}
  def body_parse(body) when is_binary(body) do
    with {:ok, body_map} <- to_editor_map(body),
         {:ok, body_html} <- EditorToHTML.to_html(body_map),
         {:ok, body_encode} <- Jason.encode(body_map) do
      %{body: body_encode, body_html: body_html} |> done
    end
  end

  def body_parse(_), do: {:error, "wrong body fmt"}

  @doc """
  decode article body string to editor map and assign id for each block
  """
  def to_editor_map(string) when is_binary(string) do
    with {:ok, map} <- Jason.decode(string),
         {:ok, _} <- EditorToHTML.Validator.is_valid(map) do
      blocks = Enum.map(map["blocks"], &Map.merge(&1, %{"id" => get_block_id(&1)}))
      Map.merge(map, %{"blocks" => blocks}) |> done
    end
  end

  # for markdown blocks
  def to_editor_map(blocks) when is_list(blocks) do
    Enum.map(blocks, fn block ->
      block = keys_to_strings(block)
      Map.merge(block, %{"id" => get_block_id(block)})
    end)
    |> done
  end

  def to_editor_map(_), do: {:error, "wrong editor fmt"}

  # use custom block id instead of editor.js's default block id
  defp get_block_id(%{"id" => id} = block) when not is_nil(id) do
    case String.starts_with?(block["id"], "block-") do
      true -> id
      false -> "block-#{uid()}"
    end
  end

  defp get_block_id(_), do: "block-#{uid()}"
end
