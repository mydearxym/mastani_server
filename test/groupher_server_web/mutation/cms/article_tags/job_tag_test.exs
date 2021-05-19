defmodule GroupherServer.Test.Mutation.ArticleTags.JobTag do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, job)

    tag_attrs = mock_attrs(:tag)
    tag_attrs2 = mock_attrs(:tag)

    {:ok, ~m(user_conn guest_conn owner_conn community job tag_attrs tag_attrs2 user)a}
  end

  describe "[mutation job tag]" do
    @set_tag_query """
    mutation($id: ID!, $thread: Thread, $articleTagId: ID!, $communityId: ID!) {
      setArticleTag(id: $id, thread: $thread, articleTagId: $articleTagId, communityId: $communityId) {
        id
      }
    }
    """
    @tag :wip2
    test "auth user can set a valid tag to job", ~m(community job tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)

      passport_rules = %{community.title => %{"job.article_tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{
        id: job.id,
        thread: "JOB",
        articleTagId: article_tag.id,
        communityId: community.id
      }

      rule_conn |> mutation_result(@set_tag_query, variables, "setArticleTag")
      {:ok, found} = ORM.find(CMS.Job, job.id, preload: :article_tags)

      assoc_tags = found.article_tags |> Enum.map(& &1.id)
      assert article_tag.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $thread: Thread, $articleTagId: ID!, $communityId: ID!) {
      unsetArticleTag(id: $id, thread: $thread, articleTagId: $articleTagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    @tag :wip2
    test "can unset tag to a job", ~m(community job tag_attrs tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :job, tag_attrs2, user)

      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag2.id)

      passport_rules = %{community.title => %{"job.article_tag.unset" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{
        id: job.id,
        thread: "JOB",
        articleTagId: article_tag.id,
        communityId: community.id
      }

      rule_conn |> mutation_result(@unset_tag_query, variables, "unsetArticleTag")

      {:ok, job} = ORM.find(CMS.Job, job.id, preload: :article_tags)
      assoc_tags = job.article_tags |> Enum.map(& &1.id)

      assert article_tag.id not in assoc_tags
      assert article_tag2.id in assoc_tags
    end
  end
end
