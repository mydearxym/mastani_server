defmodule MastaniServer.Test.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Test.AssertHelper
  import MastaniServer.Factory
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.{ORM, Certification}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, category} = db_insert(:category)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 post community category post_attrs job_attrs)a}
  end

  describe "[cms post]" do
    test "can create post with valid attrs", ~m(user post_attrs)a do
      assert {:error, _} = ORM.find_by(CMS.Author, user_id: user.id)

      {:ok, post} = CMS.create_content(:post, %Accounts.User{id: user.id}, post_attrs)
      assert post.title == post_attrs.title
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user post_attrs)a do
      assert {:error, _} = ORM.find_by(CMS.Author, user_id: user.id)

      {:ok, _} = CMS.create_content(:post, %Accounts.User{id: user.id}, post_attrs)
      {:ok, author} = ORM.find_by(CMS.Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with on exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_content(:post, %Accounts.User{id: user.id}, invalid_attrs)
    end
  end

  describe "[cms jobs]" do
    test "can create a job with valid attrs", ~m(user job_attrs)a do
      {:ok, job} = CMS.create_content(:job, %Accounts.User{id: user.id}, job_attrs)

      {:ok, found} = ORM.find(CMS.Job, job.id)
      assert found.id == job.id
      assert found.title == job.title
    end

    test "create job with on exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:job, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_content(:job, %Accounts.User{id: user.id}, invalid_attrs)
    end
  end

  describe "[cms tag]" do
    test "create tag with valid data", ~m(community user)a do
      valid_attrs = mock_attrs(:tag, %{community_id: community.id})

      {:ok, tag} = CMS.create_tag(:post, valid_attrs, %Accounts.User{id: user.id})
      assert tag.title == valid_attrs.title
    end

    test "create tag with non-exsit user fails", ~m(user)a do
      invalid_attrs = mock_attrs(:tag, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_tag(:post, invalid_attrs, %Accounts.User{id: user.id})
    end

    test "create tag with non-exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:tag, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_tag(:post, invalid_attrs, %Accounts.User{id: user.id})
    end
  end

  describe "[cms category]" do
    test "create category with valid attrs", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})

      {:ok, category} =
        CMS.create_category(%CMS.Category{title: valid_attrs.title}, %Accounts.User{id: user.id})

      assert category.title == valid_attrs.title
      # assert category.author_id == user.id
    end

    test "create category with same title fails", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})

      {:ok, _} =
        CMS.create_category(%CMS.Category{title: valid_attrs.title}, %Accounts.User{id: user.id})

      assert {:error, _} =
               CMS.create_category(%CMS.Category{title: valid_attrs.title}, %Accounts.User{
                 id: user.id
               })
    end

    test "update category with valid attrs", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})

      {:ok, category} =
        CMS.create_category(%CMS.Category{title: valid_attrs.title}, %Accounts.User{id: user.id})

      assert category.title == valid_attrs.title
      {:ok, updated} = CMS.update_category(%CMS.Category{id: category.id, title: "new title"})

      assert updated.title == "new title"
    end

    test "update title to existing title fails", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})

      {:ok, category} =
        CMS.create_category(%CMS.Category{title: valid_attrs.title}, %Accounts.User{id: user.id})

      {:ok, category2} =
        CMS.create_category(%CMS.Category{title: "category2 title"}, %Accounts.User{id: user.id})

      {:error, _} = CMS.update_category(%CMS.Category{id: category.id, title: category2.title})
    end

    test "can set a category to a community", ~m(community category)a do
      {:ok, _} =
        CMS.set_category(%CMS.Community{id: community.id}, %CMS.Category{id: category.id})

      {:ok, found_community} = ORM.find(CMS.Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(CMS.Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id in assoc_categroies
      assert community.id in assoc_communities
    end

    test "can unset a category to a community", ~m(community category)a do
      {:ok, _} =
        CMS.set_category(%CMS.Community{id: community.id}, %CMS.Category{id: category.id})

      CMS.unset_category(%CMS.Community{id: community.id}, %CMS.Category{id: category.id})

      {:ok, found_community} = ORM.find(CMS.Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(CMS.Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id not in assoc_categroies
      assert community.id not in assoc_communities
    end
  end

  # this logic is move to resolver
  # describe "[cms community]" do
  # test "create a community with a existing user", ~m(user)a do
  # community_args = %{
  # title: "elixir community",
  # desc: "function pragraming for everyone",
  # user_id: user.id,
  # raw: "elixir",
  # logo: "http: ..."
  # }

  # assert {:error, _} = ORM.find_by(CMS.Community, title: "elixir community")
  # {:ok, community} = CMS.create_community(community_args)
  # assert community.title == community_args.title
  # end

  # test "create a community with a empty title fails", ~m(user)a do
  # invalid_community_args = %{
  # title: "",
  # desc: "function pragraming for everyone",
  # user_id: user.id
  # }

  # assert {:error, %Ecto.Changeset{}} = CMS.create_community(invalid_community_args)
  # end

  # test "create a community with a non-exist user fails" do
  # community_args = %{
  # title: "elixir community",
  # desc: "function pragraming for everyone",
  # user_id: 10000
  # }

  # assert {:error, _} = CMS.create_community(community_args)
  # end
  # end

  describe "[cms community thread]" do
    test "can create thread" do
      title = "post"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      assert thread.title == title
    end

    test "create thread with exsit title fails" do
      title = "post"
      raw = title
      {:ok, _} = CMS.create_thread(~m(title raw)a)
      assert {:error, _error} = CMS.create_thread(~m(title raw)a)
    end

    test "can add a thread to community", ~m(community)a do
      title = "post"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      thread_id = thread.id
      community_id = community.id
      {:ok, ret_community} = CMS.add_thread_to_community(~m(thread_id community_id)a)
      assert ret_community.id == community.id
    end
  end

  describe "[cms community editors]" do
    test "can add editor to a community, editor has default passport", ~m(user community)a do
      title = "chief editor"

      {:ok, _} =
        CMS.add_editor_to_community(
          %Accounts.User{id: user.id},
          %CMS.Community{id: community.id},
          title
        )

      related_rules = Certification.passport_rules(cms: title)

      {:ok, editor} = CMS.CommunityEditor |> ORM.find_by(user_id: user.id)
      {:ok, user_passport} = CMS.get_passport(%Accounts.User{id: user.id})

      assert editor.user_id == user.id
      assert editor.community_id == community.id
      assert Map.equal?(related_rules, user_passport)
    end

    test "user can get paged-editors of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)
      title = "chief editor"

      Enum.each(
        users,
        &CMS.add_editor_to_community(
          %Accounts.User{id: &1.id},
          %CMS.Community{id: community.id},
          title
        )
      )

      {:ok, results} =
        CMS.community_members(:editors, %CMS.Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_entries == 25
    end
  end

  describe "[cms community subscribe]" do
    test "user can subscribe a community", ~m(user community)a do
      {:ok, record} =
        CMS.subscribe_community(%Accounts.User{id: user.id}, %CMS.Community{id: community.id})

      assert community.id == record.id
    end

    test "user can get paged-subscribers of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id})
      )

      {:ok, results} =
        CMS.community_members(:subscribers, %CMS.Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end
  end
end
