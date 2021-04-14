defmodule GroupherServer.Test.CMS.ArticleCommentEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Embeds, Post}

  @max_replies_count ArticleComment.max_replies_count()
  @default_emotions Embeds.ArticleCommentEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 user3 post job)a}
  end

  describe "[basic article comment emotion]" do
    @tag :wip2
    test "comment has default emotions after created", ~m(post user user2)a do
      parent_content = "parent comment"

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)
      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      emotions = parent_comment.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    @tag :wip2
    test "can make emotion to comment", ~m(post user user2)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user2)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert parent_comment.emotions.downvote_count == 2
      assert user_exist_in?(user, parent_comment.emotions.latest_downvote_users)
      assert user_exist_in?(user2, parent_comment.emotions.latest_downvote_users)
    end

    @tag :wip2
    test "same user make same emotion to same comment", ~m(post user)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert parent_comment.emotions.downvote_count == 1
      assert user_exist_in?(user, parent_comment.emotions.latest_downvote_users)
    end

    @tag :wip2
    test "different user can make same emotions on same comment", ~m(post user user2 user3)a do
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, "parent comment", user)

      {:ok, _} = CMS.make_emotion(parent_comment.id, :beer, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :beer, user2)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)
      # IO.inspect(emotions, label: "the parent_comment")

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    @tag :wip2
    test "same user can make differcent emotions on same comment", ~m(post user)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :beer, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :heart, user)
      {:ok, _} = CMS.make_emotion(parent_comment.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)

      assert emotions.downvote_count == 1
      assert user_exist_in?(user, emotions.latest_downvote_users)

      assert emotions.beer_count == 1
      assert user_exist_in?(user, emotions.latest_beer_users)

      assert emotions.heart_count == 1
      assert user_exist_in?(user, emotions.latest_heart_users)

      assert emotions.orz_count == 1
      assert user_exist_in?(user, emotions.latest_orz_users)

      assert emotions.pill_count == 0
      assert not user_exist_in?(user, emotions.latest_pill_users)

      assert emotions.biceps_count == 0
      assert not user_exist_in?(user, emotions.latest_biceps_users)

      assert emotions.confused_count == 0
      assert not user_exist_in?(user, emotions.latest_confused_users)
    end
  end
end
