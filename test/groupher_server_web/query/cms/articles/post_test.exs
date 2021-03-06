defmodule GroupherServer.Test.Query.Articles.Post do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user_conn guest_conn post user community post_attrs)a}
  end

  @query """
  query($id: ID!) {
    post(id: $id) {
      id
      title
      meta {
        isEdited
      }
    }
  }
  """

  test "basic graphql query on post with logined user",
       ~m(user_conn community user post_attrs)a do
    {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    variables = %{id: post.id}
    results = user_conn |> query_result(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_kv?(results, "title", :string)
    assert %{"isEdited" => false} == results["meta"]
    assert length(Map.keys(results)) == 3
  end

  test "basic graphql query on post with stranger(unloged user)", ~m(guest_conn post)a do
    variables = %{id: post.id}
    results = guest_conn |> query_result(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_kv?(results, "title", :string)
  end
end
