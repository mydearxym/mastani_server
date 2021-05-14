defmodule GroupherServer.Test.Mutation.Articles.Post do
  use GroupherServer.TestTools

  alias Helper.{ORM, Utils}
  alias GroupherServer.{CMS, Delivery}

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mutation post curd]" do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $digest: String!
      $length: Int!
      $communityId: ID!
      $tags: [Ids]
      $mentionUsers: [Ids]
    ) {
      createPost(
        title: $title
        body: $body
        digest: $digest
        length: $length
        communityId: $communityId
        tags: $tags
        mentionUsers: $mentionUsers
      ) {
        title
        body
        id
        originalCommunity {
          id
        }
      }
    }
    """
    test "create post with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables = post_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"])

      assert created["id"] == to_string(post.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)
    end

    test "create post should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post, %{body: assert_v(:xss_string)})

      variables = post_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"])

      assert post.body == assert_v(:xss_safe_string)
    end

    # NOTE: this test is IMPORTANT, cause json_codec: Jason in router will cause
    # server crash when GraphQL parse error
    test "create post with missing non_null field should get 200 error" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)
      variables = post_attr |> Map.merge(%{communityId: community.id}) |> Map.delete(:title)

      assert user_conn |> mutation_get_error?(@create_post_query, variables)
    end

    test "can create post with tags" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{tags: [%{id: tag1.id}, %{id: tag2.id}]})

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"], preload: :tags)

      assert post.tags |> Enum.any?(&(&1.id == tag1.id))
      assert post.tags |> Enum.any?(&(&1.id == tag2.id))
    end

    test "can create post with mentionUsers" do
      {:ok, user} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{mentionUsers: [%{id: user2.id}]})

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 0

      _created = user_conn |> mutation_result(@create_post_query, variables, "createPost")

      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)

      assert mentions.total_count == 1
      assert mentions.entries |> List.first() |> Map.get(:community) !== nil
    end

    @query """
    mutation($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """

    test "delete a post by post's owner", ~m(owner_conn post)a do
      deleted = owner_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
    end

    test "can delete a post by auth user", ~m(post)a do
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"post.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
    end

    test "delete a post without login user fails", ~m(guest_conn post)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: post.id}, ecode(:account_login))
    end

    test "login user with auth passport delete a post", ~m(post)a do
      post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      passport_rules = %{post_communities_0 => %{"post.delete" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
    end

    test "unauth user delete post fails", ~m(user_conn guest_conn post)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $copyRight: String, $tags: [Ids]){
      updatePost(id: $id, title: $title, body: $body, copyRight: $copyRight, tags: $tags) {
        id
        title
        body
        copyRight
        meta {
          isEdited
        }
        articleCommentsParticipators {
          id
          nickname
        }
      }
    }
    """
    test "update a post without login user fails", ~m(guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "can update post with tags", ~m(owner_conn post)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        tags: [%{id: tag1.id}, %{id: tag2.id}]
      }

      updated = owner_conn |> mutation_result(@query, variables, "updatePost")
      {:ok, post} = ORM.find(CMS.Post, updated["id"], preload: :tags)
      tag_ids = post.tags |> Utils.pick_by(:id)

      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
    end

    test "post can be update by owner", ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}",
        copyRight: "translate"
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["title"] == variables.title
      assert updated_post["body"] == variables.body
      assert updated_post["copyRight"] == variables.copyRight
    end

    @tag :wip
    test "update post with valid attrs should have is_edited meta info update",
         ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert true == updated_post["meta"]["isEdited"]
    end

    test "login user with auth passport update a post", ~m(post)a do
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)

      passport_rules = %{belongs_community_title => %{"post.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = rule_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["id"] == to_string(post.id)
    end

    test "unauth user update post fails", ~m(user_conn guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
