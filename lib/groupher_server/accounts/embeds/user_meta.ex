defmodule GroupherServer.Accounts.Embeds.UserMeta.Macro do
  @moduledoc false

  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :threads)

  defmacro published_article_count_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"published_#{thread}s_count"), :integer, default: 0)
      end
    end)
  end
end

defmodule GroupherServer.Accounts.Embeds.UserMeta do
  @moduledoc """
  general article meta info for articles
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.Accounts.Embeds.UserMeta.Macro
  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :threads)

  @general_options %{
    reported_count: 0,
    reported_user_ids: [],
    follower_user_ids: [],
    following_user_ids: []
  }

  @optional_fields Map.keys(@general_options) ++
                     Enum.map(@article_threads, &:"published_#{&1}s_count")

  def default_meta() do
    published_article_counts =
      @article_threads
      |> Enum.reduce([], &(&2 ++ ["published_#{&1}s_count": 0]))
      |> Enum.into(%{})

    @general_options |> Map.merge(published_article_counts)
  end

  embedded_schema do
    field(:reported_count, :integer, default: 0)
    field(:reported_user_ids, {:array, :integer}, default: [])

    # TODO: 怎样处理历史数据 ？
    field(:follower_user_ids, {:array, :integer}, default: [])
    field(:following_user_ids, {:array, :integer}, default: [])

    published_article_count_fields()
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
