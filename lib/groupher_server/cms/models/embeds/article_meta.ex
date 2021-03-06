defmodule GroupherServer.CMS.Model.Embeds.ArticleMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  @optional_fields ~w(thread is_edited is_comment_locked upvoted_user_ids collected_user_ids viewed_user_ids reported_user_ids reported_count is_sinked can_undo_sink last_active_at)a

  @doc "for test usage"
  def default_meta() do
    %{
      thread: "POST",
      is_edited: false,
      is_comment_locked: false,
      folded_comment_count: 0,
      upvoted_user_ids: [],
      collected_user_ids: [],
      viewed_user_ids: [],
      reported_user_ids: [],
      reported_count: 0,
      is_sinked: false,
      can_undo_sink: true,
      last_active_at: nil,
      citing_count: 0
    }
  end

  embedded_schema do
    field(:thread, :string)
    field(:is_edited, :boolean, default: false)
    field(:is_comment_locked, :boolean, default: false)
    field(:folded_comment_count, :integer, default: 0)
    # reaction history
    field(:upvoted_user_ids, {:array, :integer}, default: [])
    field(:collected_user_ids, {:array, :integer}, default: [])
    field(:viewed_user_ids, {:array, :integer}, default: [])
    field(:reported_user_ids, {:array, :integer}, default: [])
    field(:reported_count, :integer, default: 0)

    field(:is_sinked, :boolean, default: false)
    field(:can_undo_sink, :boolean, default: false)
    # if undo_sink, can recover last active_at from here
    field(:last_active_at, :utc_datetime_usec)
    field(:citing_count, :integer, default: 0)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
