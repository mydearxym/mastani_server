defmodule GroupherServer.Test.Mutation.Flags.PostFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mutation post flag curd]" do
    @query """
    mutation($id: ID!){
      markDeletePost(id: $id) {
        id
        markDelete
      }
    }
    """
    @tag :wip2
    test "auth user can markDelete post", ~m(community post)a do
      variables = %{id: post.id}

      passport_rules = %{"post.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeletePost")

      assert updated["id"] == to_string(post.id)
      assert updated["markDelete"] == true
    end

    @tag :wip2
    test "unauth user markDelete post fails", ~m(user_conn guest_conn post community)a do
      variables = %{id: post.id, thread: "POST"}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeletePost(id: $id) {
        id
        markDelete
      }
    }
    """
    @tag :wip2
    test "auth user can undo markDelete post", ~m(community post)a do
      variables = %{id: post.id, thread: "POST"}

      {:ok, _} = CMS.mark_delete_article(:post, post.id)

      passport_rules = %{"post.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeletePost")

      assert updated["id"] == to_string(post.id)
      assert updated["markDelete"] == false
    end

    @tag :wip2
    test "unauth user undo markDelete post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, thread: "POST"}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinPost(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinPost")

      assert updated["id"] == to_string(post.id)
    end

    test "unauth user pin post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinPost(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:post, post.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinPost")

      assert updated["id"] == to_string(post.id)
    end

    test "unauth user undo pin post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
