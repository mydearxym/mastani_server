defmodule GroupherServer.CMS.Delegate.ArticleComment do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User

  alias CMS.{
    ArticleComment,
    ArticleCommentUpvote,
    ArticleCommentReply,
    ArticleCommentUserEmotion,
    Post,
    Job
  }

  alias Ecto.Multi

  # TODO:  move to embeds
  @max_emotion_action_users_count 5

  @max_participator_count CMS.ArticleComment.max_participator_count()
  @max_replies_count CMS.ArticleComment.max_replies_count()
  @default_emotions CMS.Embeds.ArticleCommentEmotion.default_emotions()

  @doc """
  list paged article comments
  """
  def list_article_comments(thread, article_id, %{page: page, size: size} = filters) do
    with {:ok, thread_query} <- match(thread, :query, article_id) do
      ArticleComment
      |> where(^thread_query)
      |> QueryBuilder.filter_pack(filters)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  def make_emotion(comment_id, action, %User{} = user) do
    with {:ok, comment} <-
           ORM.find(ArticleComment, comment_id) do
      Multi.new()
      |> Multi.run(:create_user_emotion, fn _, _ ->
        args =
          Map.put(
            %{
              article_comment_id: comment.id,
              recived_user_id: comment.author_id,
              user_id: user.id
            },
            :"#{action}",
            true
          )

        {:ok, _} = ArticleCommentUserEmotion |> ORM.create(args)
      end)
      |> Multi.run(:query_emotion_status, fn _, _ ->
        # 每次被 emotion 动作触发后重新查询，主要原因
        # 1.并发下保证数据准确，类似 views 阅读数的统计
        # 2. 前端使用 nickname 而非 login 展示，如果用户改了 nickname, 可以"自动纠正"
        query =
          from(a in ArticleCommentUserEmotion,
            join: user in User,
            on: a.user_id == user.id,
            where: a.article_comment_id == ^comment.id,
            where: field(a, ^action) == true,
            select: %{login: user.login, nickname: user.nickname}
          )

        emotioned_user_info_list = Repo.all(query) |> Enum.uniq()
        emotioned_user_count = length(emotioned_user_info_list)

        {:ok, %{user_list: emotioned_user_info_list, user_count: emotioned_user_count}}
      end)
      |> Multi.run(:update_comment_emotion, fn _, %{query_emotion_status: status} ->
        updated_emotions =
          %{}
          |> Map.put(:"#{action}_count", status.user_count)
          |> Map.put(
            :"latest_#{action}_users",
            Enum.slice(status.user_list, 0, @max_emotion_action_users_count)
          )

        comment
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:emotions, updated_emotions)
        |> Repo.update()
      end)
      |> Repo.transaction()
      |> emotion_comment_result()

      # is not work this way, why?
      # updated_emotions =
      #   Map.merge(comment.emotions, %{
      #     downvote_count: comment.emotions.downvote_count + Enum.random([1, 2, 3]),
      #     tada_count: comment.emotions.tada_count + Enum.random([1, 2, 3])
      #   })
    end
  end

  defp emotion_comment_result({:ok, %{update_comment_emotion: result}}), do: {:ok, result}

  defp emotion_comment_result({:error, _, result, _steps}) do
    {:error, result}
  end

  @doc """
  list paged comment replies
  """
  def list_comment_replies(comment_id, %{page: page, size: size} = filters) do
    ArticleComment
    |> where([c], c.reply_to_id == ^comment_id)
    |> QueryBuilder.filter_pack(filters)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  @doc """
  Creates a comment for psot, job ...
  """
  def write_comment(
        thread,
        article_id,
        content,
        %User{} = user
      ) do
    with {:ok, info} <- match(thread),
         # make sure the article exsit
         # author is passed by middleware, it's exsit for sure
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:write_comment, fn _, _ ->
        do_create_comment(content, info.foreign_key, article.id, user)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      # |> Multi.run(:mention_users, fn _, %{create_comment: comment} ->
      #   Delivery.mention_from_comment(community, thread, content, comment, args, user)
      #   {:ok, :pass}
      # end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  @doc "reply to exsiting comment"
  def reply_article_comment(
        comment_id,
        content,
        %User{id: user_id} = user
      ) do
    with {:ok, replying_comment} <- ORM.find(ArticleComment, comment_id, preload: :reply_to),
         {thread, article} <- get_article(replying_comment),
         {:ok, info} <- match(thread),
         parent_comment <- get_parent_comment(replying_comment) do
      Multi.new()
      |> Multi.run(:create_reply_comment, fn _, _ ->
        do_create_comment(content, info.foreign_key, replying_comment[info.foreign_key], user)
      end)
      |> Multi.run(:create_article_comment_reply, fn _,
                                                     %{create_reply_comment: replyed_comment} ->
        ArticleCommentReply
        |> ORM.create(%{article_comment_id: replyed_comment.id, reply_to_id: replying_comment.id})
      end)
      |> Multi.run(:inc_replies_count, fn _, _ ->
        ORM.inc_field(ArticleComment, replying_comment, :replies_count)
      end)
      |> Multi.run(:add_replies_ifneed, fn _, %{create_reply_comment: replyed_comment} ->
        add_replies_ifneed(parent_comment, replyed_comment)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      |> Multi.run(:add_reply_to, fn _, %{create_reply_comment: replyed_comment} ->
        replyed_comment
        |> Repo.preload(:reply_to)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reply_to, replying_comment)
        |> Repo.update()
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  # TODO: should put totol upvote count in meta info
  def upvote_comment(comment_id, %User{id: user_id}) do
    # make sure the comment exsit
    # TODO: make sure the comment is not deleted yet
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      args = %{article_comment_id: comment.id, user_id: user_id}
      ArticleCommentUpvote |> ORM.create(args)
    end
  end

  # creat article comment for parent or reply
  # set floor
  # TODO: parse editor-json
  # set default emotions
  defp do_create_comment(content, foreign_key, article_id, %User{id: user_id}) do
    # @default_emotions
    # %{author_id: user_id, body_html: content, emotions: @default_emotions}
    args =
      %{author_id: user_id, body_html: content, emotions: @default_emotions}
      |> Map.put(
        foreign_key,
        article_id
      )

    # IO.inspect(args, label: "the args")
    ORM.create(ArticleComment, args)
  end

  # 设计盖楼只保留一个层级，回复楼中的评论都会被放到顶楼的 replies 中
  defp get_parent_comment(%ArticleComment{reply_to_id: nil} = comment) do
    comment
  end

  defp get_parent_comment(%ArticleComment{reply_to_id: reply_to_id} = comment) do
    Repo.preload(comment, :reply_to) |> Map.get(:reply_to)
    # get_parent_comment(Repo.preload(comment, :reply_to))
  end

  # 如果 replies 没有达到 @max_replies_count, 则添加
  # "加载更多" 的逻辑使用另外的 paged 接口从 ArticleCommentReply 表中查询
  defp add_replies_ifneed(
         %ArticleComment{replies: replies} = parent_comment,
         %ArticleComment{} = replyed_comment
       )
       when length(replies) < @max_replies_count do
    new_replies =
      replies
      |> List.insert_at(length(replies), replyed_comment)
      |> Enum.slice(0, @max_replies_count)

    parent_comment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:replies, new_replies)
    |> Repo.update()
  end

  # 如果已经有 @max_replies_count 以上的回复了，直接忽略即可
  defp add_replies_ifneed(%ArticleComment{} = parent_comment, _) do
    {:ok, parent_comment}
  end

  # add participator to article-like content (Post, Job ...)
  defp add_participator_to_article(%Post{} = article, %User{} = user) do
    new_comment_participators =
      article.comment_participators
      |> List.insert_at(0, user)
      |> Enum.uniq()
      |> Enum.slice(0, @max_participator_count)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:comment_participators, new_comment_participators)
    |> Repo.update()
  end

  defp add_participator_to_article(_, _), do: {:ok, :pass}

  # TODO: move to new matcher
  defp match(:post) do
    {:ok, %{model: Post, foreign_key: :post_id}}
  end

  defp match(:job) do
    {:ok, %{model: Job, foreign_key: :job_id}}
  end

  defp match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  defp match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}
  # matcher end

  defp get_article(%ArticleComment{post_id: post_id} = comment) when not is_nil(post_id) do
    with {:ok, article} <- ORM.find(Post, comment.post_id) do
      {:post, article}
    end
  end

  defp get_article(%ArticleComment{job_id: job_id} = comment) when not is_nil(job_id) do
    with {:ok, article} <- ORM.find(Job, comment.job_id) do
      {:job, article}
    end
  end

  defp upsert_comment_result({:ok, %{write_comment: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{add_reply_to: result}}), do: {:ok, result}

  defp upsert_comment_result({:error, :create_comment, result, _steps}) do
    {:error, result}
  end

  defp upsert_comment_result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  defp upsert_comment_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
