defmodule GroupherServer.Accounts.Embeds.UserMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  @optional_fields ~w(reported_count follower_user_ids following_user_ids)a

  @default_meta %{
    reported_count: 0,
    reported_user_ids: [],
    follower_user_ids: [],
    following_user_ids: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:reported_count, :integer, default: 0)
    field(:reported_user_ids, {:array, :integer}, default: [])

    # TODO: 怎样处理历史数据 ？
    field(:follower_user_ids, {:array, :integer}, default: [])
    field(:following_user_ids, {:array, :integer}, default: [])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
