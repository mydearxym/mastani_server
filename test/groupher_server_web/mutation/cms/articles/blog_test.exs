defmodule GroupherServer.Test.Mutation.Articles.Blog do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.Blog

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})
    {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, blog)

    {:ok, ~m(user_conn guest_conn owner_conn community user blog)a}
  end

  describe "[mutation blog curd]" do
    @create_blog_query """
    mutation (
      $title: String!,
      $body: String,
      $digest: String!,
      $length: Int,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createBlog(
        title: $title,
        body: $body,
        digest: $digest,
        length: $length,
        communityId: $communityId,
        articleTags: $articleTags
        ) {
          id
          title
          document {
            bodyHtml
          }
          originalCommunity {
            id
          }
          communities {
            id
            title
          }
      }
    }
    """
    test "create blog with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      blog_attr = mock_attrs(:blog)

      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, found} = ORM.find(Blog, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create blog with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      blog_attr = mock_attrs(:blog)

      variables =
        blog_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
      {:ok, blog} = ORM.find(Blog, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, blog.article_tags)
    end

    @tag :wip
    test "create blog should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      blog_attr = mock_attrs(:blog, %{body: mock_xss_string()})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
      body_html = blog |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    @tag :wip
    test "create blog should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      blog_attr = mock_attrs(:blog, %{body: mock_xss_string(:safe)})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
      {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
      body_html = blog |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateBlog(id: $id, title: $title, body: $body, articleTags: $articleTags) {
        id
        title
        document {
          bodyHtml
        }
        articleTags {
          id
        }
      }
    }
    """
    test "update a blog without login user fails", ~m(guest_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "blog can be update by owner", ~m(owner_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateBlog")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a blog", ~m(blog)a do
      blog_communities_0 = blog.communities |> List.first() |> Map.get(:title)
      passport_rules = %{blog_communities_0 => %{"blog.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateBlog")

      assert updated["id"] == to_string(blog.id)
    end

    test "unauth user update blog fails", ~m(user_conn guest_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      deleteBlog(id: $id) {
        id
      }
    }
    """

    test "can delete a blog by blog's owner", ~m(owner_conn blog)a do
      deleted = owner_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end

    test "can delete a blog by auth user", ~m(blog)a do
      belongs_community_title = blog.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"blog.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end
  end
end
