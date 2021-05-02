defmodule GroupherServer.Accounts.Embeds.CollectFolderMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(has_post has_job has_repo)a

  @default_meta %{
    has_post: false,
    has_job: false,
    has_repo: false
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:has_post, :boolean, default: false)
    field(:has_job, :boolean, default: false)
    field(:has_repo, :boolean, default: false)
    ###
    # field(:has_works, :boolean, default: false)
    # field(:has_cool_guide, :boolean, default: false)
    # field(:has_meetup, :boolean, default: false)
    # field(:has_post, :boolean, default: false)
    # field(:is_comment_locked, :boolean, default: false)
    # field(:is_reported, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
