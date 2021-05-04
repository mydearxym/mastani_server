defmodule GroupherServer.Test.Query.Accounts.CollectedArticles do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  @total_count 20

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, posts} = db_insert_multi(:post, @total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user posts)a}
  end

  @query """
  query($filter: CollectFoldersFilter!) {
    pagedCollectFolders(filter: $filter) {
      entries {
        id
        title
        private
      }
      totalPages
      totalCount
      pageSize
      pageNumber
    }
  }
  """
  @tag :wip2
  test "other user can get other user's paged collect folders", ~m(user_conn guest_conn posts)a do
    {:ok, user} = db_insert(:user)

    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

    variables = %{filter: %{user_login: user.login, page: 1, size: 20}}
    results = user_conn |> query_result(@query, variables, "pagedCollectFolders")
    results2 = guest_conn |> query_result(@query, variables, "pagedCollectFolders")

    assert results["totalCount"] == 2
    assert results2["totalCount"] == 2

    assert results |> is_valid_pagination?()
    assert results2 |> is_valid_pagination?()
  end

  test "can get paged favoritedPosts on a spec category", ~m(user_conn guest_conn posts)a do
    {:ok, user} = db_insert(:user)

    Enum.each(posts, fn post ->
      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
    end)

    post1 = Enum.at(posts, 0)
    post2 = Enum.at(posts, 1)
    post3 = Enum.at(posts, 2)
    post4 = Enum.at(posts, 4)

    test_category = "test category"
    test_category2 = "test category2"

    {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
    {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

    {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post1.id, category.id)
    {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post2.id, category.id)
    {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post3.id, category.id)
    {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post4.id, category2.id)

    variables = %{userId: user.id, categoryId: category.id, filter: %{page: 1, size: 20}}
    results = user_conn |> query_result(@query, variables, "favoritedPosts")
    results2 = guest_conn |> query_result(@query, variables, "favoritedPosts")

    assert results["totalCount"] == 3
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post1.id)))
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post2.id)))
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post3.id)))

    assert results == results2
  end
end
