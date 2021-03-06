defmodule GroupherServer.Test.CMS.Hooks.MentionInRadar do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, radar} = db_insert(:radar)

    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community radar radar_attrs)a}
  end

  describe "[mention in radar basic]" do
    test "mention multi user in radar should work",
         ~m(user user2 user3 community  radar_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, radar} = preload_author(radar)

      {:ok, _result} = Hooks.Mention.handle(radar)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "RADAR"
      assert mention.block_linker |> length == 2
      assert mention.article_id == radar.id
      assert mention.title == radar.title
      assert mention.user.login == radar.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "RADAR"
      assert mention.block_linker |> length == 1
      assert mention.article_id == radar.id
      assert mention.title == radar.title
      assert mention.user.login == radar.author.user.login
    end

    test "mention in radar's comment should work", ~m(user user2 radar)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:radar, radar.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "RADAR"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == radar.id
      assert mention.title == radar.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in radar or comment", ~m(community user radar_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:radar, radar.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
