defmodule GroupherServer.Test.CMS.Emotions.BlogEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Blog, Embeds, ArticleUserEmotion}

  @default_emotions Embeds.ArticleEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community blog_attrs)a}
  end

  describe "[emotion in paged blogs]" do
    test "login user should got viewer has emotioned status",
         ~m(community blog_attrs user)a do
      total_count = 10
      page_number = 10
      page_size = 20

      all_blogs =
        Enum.reduce(0..total_count, [], fn _, acc ->
          {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
          acc ++ [blog]
        end)

      random_blog = all_blogs |> Enum.at(3)

      {:ok, _} = CMS.emotion_to_article(:blog, random_blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, random_blog.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:blog, random_blog.id, :popcorn, user)

      {:ok, paged_articles} =
        CMS.paged_articles(:blog, %{page: page_number, size: page_size}, user)

      target = Enum.find(paged_articles.entries, &(&1.id == random_blog.id))

      assert target.emotions.downvote_count == 1
      assert user_exist_in?(user, target.emotions.latest_downvote_users)
      assert target.emotions.viewer_has_downvoteed

      assert target.emotions.beer_count == 1
      assert user_exist_in?(user, target.emotions.latest_beer_users)
      assert target.emotions.viewer_has_beered

      assert target.emotions.popcorn_count == 1
      assert user_exist_in?(user, target.emotions.latest_popcorn_users)
      assert target.emotions.viewer_has_popcorned
    end
  end

  describe "[basic article emotion]" do
    test "blog has default emotions after created", ~m(community blog_attrs user)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      emotions = blog.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    test "can make emotion to blog", ~m(community blog_attrs user user2)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Blog, blog.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "can undo emotion to blog", ~m(community blog_attrs user user2)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user2)

      {:ok, _} = CMS.undo_emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.undo_emotion_to_article(:blog, blog.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Blog, blog.id)

      assert emotions.downvote_count == 0
      assert not user_exist_in?(user, emotions.latest_downvote_users)
      assert not user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "same user make same emotion to same blog.", ~m(community blog_attrs user)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)

      {:ok, blog} = ORM.find(Blog, blog.id)

      assert blog.emotions.downvote_count == 1
      assert user_exist_in?(user, blog.emotions.latest_downvote_users)
    end

    test "same user same emotion to same blog only have one user_emotion record",
         ~m(community blog_attrs user)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :heart, user)

      {:ok, blog} = ORM.find(Blog, blog.id)

      {:ok, records} = ORM.find_all(ArticleUserEmotion, %{page: 1, size: 10})
      assert records.total_count == 1

      {:ok, record} = ORM.find_by(ArticleUserEmotion, %{blog_id: blog.id, user_id: user.id})
      assert record.downvote
      assert record.heart
    end

    test "different user can make same emotions on same blog",
         ~m(community blog_attrs user user2 user3)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :beer, user2)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(Blog, blog.id)

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    test "same user can make differcent emotions on same blog", ~m(community blog_attrs user)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :heart, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(Blog, blog.id)

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
