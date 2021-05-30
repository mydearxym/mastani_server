defmodule GroupherServer.Test.Query.Accounts.Published.Jobs do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn community job user)a}
  end

  describe "[published jobs]" do
    @query """
    query($login: String!, $filter: PagedFilter!) {
      pagedPublishedJobs(login: $login, filter: $filter) {
        entries {
          id
          title
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip2
    test "can get published jobs", ~m(guest_conn community user)a do
      job_attrs = mock_attrs(:job, %{community_id: community.id})

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job2} = CMS.create_article(community, :job, job_attrs, user)

      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPublishedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job2.id)))
    end
  end

  describe "[account published comments on job]" do
    @query """
    query($login: String!, $thread: Thread, $filter: PagedFilter!) {
      pagedPublishedArticleComments(login: $login, thread: $thread, filter: $filter) {
        entries {
          id
          bodyHtml
          author {
            id
          }
          article {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip2
    test "user can get paged published comments on job", ~m(guest_conn user job)a do
      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "comment", user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{login: user.login, thread: "JOB", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPublishedArticleComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["article"]["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end
end