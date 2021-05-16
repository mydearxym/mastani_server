defmodule GroupherServer.CMS.Post do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.{CMS, Accounts}

  alias CMS.{
    Embeds,
    Author,
    ArticleComment,
    Community,
    PostComment,
    Tag,
    ArticleUpvote,
    ArticleCollect
  }

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title body digest length)a
  @optional_fields ~w(original_community_id link_addr copy_right link_addr link_icon article_comments_count article_comments_participators_count upvotes_count collects_count mark_delete)a

  @type t :: %Post{}
  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:link_icon, :string)
    field(:copy_right, :string)
    field(:length, :integer)
    field(:views, :integer, default: 0)

    belongs_to(:author, Author)
    embeds_one(:meta, Embeds.ArticleMeta, on_replace: :update)

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    # field(:pin, :boolean, default_value: false, virtual: true)
    field(:is_pinned, :boolean, default: false, virtual: true)
    field(:mark_delete, :boolean, default: false)

    field(:viewer_has_viewed, :boolean, default: false, virtual: true)
    field(:viewer_has_upvoted, :boolean, default: false, virtual: true)
    field(:viewer_has_collected, :boolean, default: false, virtual: true)
    field(:viewer_has_reported, :boolean, default: false, virtual: true)

    has_many(:upvotes, {"article_upvotes", ArticleUpvote})
    field(:upvotes_count, :integer, default: 0)

    has_many(:collects, {"article_collects", ArticleCollect})
    field(:collects_count, :integer, default: 0)

    # TODO
    # 相关文章
    # has_may(:related_post, ...)
    has_many(:comments, {"posts_comments", PostComment})

    has_many(:article_comments, {"articles_comments", ArticleComment})
    field(:article_comments_count, :integer, default: 0)
    field(:article_comments_participators_count, :integer, default: 0)
    # 评论参与者，只保留最近 5 个
    embeds_many(:article_comments_participators, Accounts.User, on_replace: :delete)

    embeds_one(:emotions, Embeds.ArticleEmotion, on_replace: :update)

    # The keys are inflected from the schema names!
    # see https://hexdocs.pm/ecto/Ecto.Schema.html
    many_to_many(
      :tags,
      Tag,
      join_through: "posts_tags",
      join_keys: [post_id: :id, tag_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all,
      on_replace: :delete
    )

    belongs_to(:original_community, Community)

    many_to_many(
      :communities,
      Community,
      join_through: "communities_posts",
      on_replace: :delete
    )

    # timestamps(type: :utc_datetime)
    # for paged test to diff
    # timestamps(type: :utc_datetime_usec)
    timestamps()
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 3, max: 50)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> validate_length(:body, min: 3, max: 10_000)
    |> validate_length(:link_addr, min: 5, max: 400)
    |> HTML.safe_string(:body)

    # |> foreign_key_constraint(:posts_tags, name: :posts_tags_tag_id_fkey)
    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
