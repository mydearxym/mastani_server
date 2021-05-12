defmodule GroupherServer.Test.CMS.AbuseReports.JobReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community job_attrs)a}
  end

  describe "[article job report/unreport]" do
    @tag :wip3
    test "list article reports should work", ~m(community user user2 job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user2)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)

      report = all_reports.entries |> List.first()
      assert report.article.id == job.id
      assert report.article.thread == :job
    end

    @tag :wip3
    test "report a job should have a abuse report record", ~m(community user job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.article.id == job.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login

      {:ok, job} = ORM.find(CMS.Job, job.id)
      assert job.is_reported
      assert job.meta.reported_count == 1
    end

    @tag :wip3
    test "can undo a report", ~m(community user job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.undo_report_article(:job, job.id, user)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)
      assert all_reports.total_count == 0
    end

    @tag :wip3
    test "can undo a report with other user report it too",
         ~m(community user user2 job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user2)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:job, job.id, user)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    @tag :wip3
    test "different user report a comment should have same report with different report cases",
         ~m(community user user2 job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:job, job.id, "reason2", "attr_info 2", user2)

      filter = %{content_type: :job, content_id: job.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    @tag :wip3
    test "same user can not report a comment twice", ~m(community job_attrs user)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      assert {:error, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
    end
  end
end
