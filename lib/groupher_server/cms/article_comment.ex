defmodule GroupherServer.CMS.ArticleComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias CMS.{
    Post,
    Job,
    ArticleCommentUpvote,
    ArticleCommentReply,
    ArticleCommentEmotion
  }

  # alias Helper.HTML

  @required_fields ~w(body_html author_id)a
  @optional_fields ~w(post_id job_id reply_to_id replies_count)a

  @max_participator_count 5
  @max_replies_count 3

  @doc "latest participators stores in article comment_participators field"
  def max_participator_count(), do: @max_participator_count
  @doc "latest replies stores in article_comment replies field, used for frontend display"
  def max_replies_count(), do: @max_replies_count

  @type t :: %ArticleComment{}
  schema "articles_comments" do
    field(:body_html, :string)
    field(:replies_count, :integer, default: 0)

    # field(:floor, :integer)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:reply_to, ArticleComment, foreign_key: :reply_to_id)

    embeds_many(:replies, ArticleComment, on_replace: :delete)
    embeds_one(:emotions, ArticleCommentEmotion, on_replace: :delete)

    has_many(:upvotes, {"articles_comments_upvotes", ArticleCommentUpvote})

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          GroupherServer.CMS.ArticleComment.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(%ArticleComment{} = article_comment, attrs) do
    article_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:emotions, required: true, with: &ArticleCommentEmotion.changeset/2)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  # @doc false
  def update_changeset(%ArticleComment{} = article_comment, attrs) do
    article_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    # |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)

    # |> validate_length(:body_html, min: 3, max: 2000)
    # |> HTML.safe_string(:body_html)
  end
end
