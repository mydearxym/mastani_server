defmodule GroupherServerWeb.Resolvers.CMS do
  @moduledoc false

  import ShortMaps
  import Ecto.Query, warn: false

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.{Community, Category, Thread, CommunityWiki, CommunityCheatsheet}

  alias Helper.ORM

  # #######################
  # community ..
  # #######################
  def community(_root, args, %{context: %{cur_user: user}}) do
    case Enum.empty?(args) do
      false -> CMS.read_community(args, user)
      true -> {:error, "please provide community id or title or raw"}
    end
  end

  def community(_root, args, _info) do
    case Enum.empty?(args) do
      false -> CMS.read_community(args)
      true -> {:error, "please provide community id or title or raw"}
    end
  end

  def paged_communities(_root, ~m(filter)a, _info), do: Community |> ORM.find_all(filter)

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    Community |> ORM.create(args)
  end

  def update_community(_root, args, _info), do: Community |> ORM.find_update(args)

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete!(id)

  # #######################
  # community thread (post, job), login user should be logged
  # #######################
  def read_article(_root, %{thread: thread, id: id}, %{context: %{cur_user: user}}) do
    CMS.read_article(thread, id, user)
  end

  def read_article(_root, %{thread: thread, id: id}, _info) do
    CMS.read_article(thread, id)
  end

  def paged_articles(_root, ~m(thread filter)a, %{context: %{cur_user: user}}) do
    CMS.paged_articles(thread, filter, user)
  end

  def paged_articles(_root, ~m(thread filter)a, _info) do
    CMS.paged_articles(thread, filter)
  end

  def paged_reports(_root, ~m(filter)a, _) do
    CMS.paged_reports(filter)
  end

  def wiki(_root, ~m(community)a, _info), do: CMS.get_wiki(%Community{raw: community})
  def cheatsheet(_root, ~m(community)a, _info), do: CMS.get_cheatsheet(%Community{raw: community})

  def create_article(_root, ~m(community_id thread)a = args, %{context: %{cur_user: user}}) do
    CMS.create_article(%Community{id: community_id}, thread, args, user)
  end

  def update_article(_root, %{passport_source: content} = args, _info) do
    CMS.update_article(content, args)
  end

  def delete_article(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # #######################
  # content flag ..
  # #######################
  def pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.pin_article(thread, id, community_id)
  end

  def undo_pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.undo_pin_article(thread, id, community_id)
  end

  def mark_delete_article(_root, ~m(id thread)a, _info) do
    CMS.mark_delete_article(thread, id)
  end

  def undo_mark_delete_article(_root, ~m(id thread)a, _info) do
    CMS.undo_mark_delete_article(thread, id)
  end

  def report_article(_root, ~m(thread id reason attr)a, %{context: %{cur_user: user}}) do
    CMS.report_article(thread, id, reason, attr, user)
  end

  def undo_report_article(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_report_article(thread, id, user)
  end

  # #######################
  # thread reaction ..
  # #######################
  def lock_article_comment(_root, ~m(id thread)a, _info), do: CMS.lock_article_comment(thread, id)

  def undo_lock_article_comment(_root, ~m(id thread)a, _info) do
    CMS.undo_lock_article_comment(thread, id)
  end

  def sink_article(_root, ~m(id thread)a, _info), do: CMS.sink_article(thread, id)
  def undo_sink_article(_root, ~m(id thread)a, _info), do: CMS.undo_sink_article(thread, id)

  def upvote_article(_root, ~m(id thread)a, %{context: %{cur_user: user}}) do
    CMS.upvote_article(thread, id, user)
  end

  def undo_upvote_article(_root, ~m(id thread)a, %{context: %{cur_user: user}}) do
    CMS.undo_upvote_article(thread, id, user)
  end

  def upvoted_users(_root, ~m(id thread filter)a, _info) do
    CMS.upvoted_users(thread, id, filter)
  end

  def collected_users(_root, ~m(id thread filter)a, _info) do
    CMS.collected_users(thread, id, filter)
  end

  def emotion_to_article(_root, ~m(id thread emotion)a, %{context: %{cur_user: user}}) do
    CMS.emotion_to_article(thread, id, emotion, user)
  end

  def undo_emotion_to_article(_root, ~m(id thread emotion)a, %{context: %{cur_user: user}}) do
    CMS.undo_emotion_to_article(thread, id, emotion, user)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title raw)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%{title: title, raw: raw}, user)
  end

  def delete_category(_root, %{id: id}, _info), do: Category |> ORM.find_delete!(id)

  def update_category(_root, ~m(id title)a, %{context: %{cur_user: _}}) do
    CMS.update_category(~m(%Category id title)a)
  end

  def set_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.set_category(%Community{id: community_id}, %Category{id: category_id})
  end

  def unset_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.unset_category(%Community{id: community_id}, %Category{id: category_id})
  end

  # #######################
  # thread ..
  # #######################
  def paged_threads(_root, ~m(filter)a, _info), do: Thread |> ORM.find_all(filter)

  def create_thread(_root, ~m(title raw index)a, _info),
    do: CMS.create_thread(~m(title raw index)a)

  def set_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.set_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  def unset_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.unset_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  # #######################
  # editors ..
  # #######################
  def set_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.set_editor(%Community{id: community_id}, title, %User{id: user_id})
  end

  def unset_editor(_root, ~m(community_id user_id)a, _) do
    CMS.unset_editor(%Community{id: community_id}, %User{id: user_id})
  end

  def update_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.update_editor(%Community{id: community_id}, title, %User{id: user_id})
  end

  def paged_community_editors(_root, ~m(id filter)a, _info) do
    CMS.community_members(:editors, %Community{id: id}, filter)
  end

  # #######################
  # geo infos ..
  # #######################
  def community_geo_info(_root, ~m(id)a, _info) do
    CMS.community_geo_info(%Community{id: id})
  end

  # #######################
  # tags ..
  # #######################
  def create_article_tag(_root, %{thread: thread, community_id: community_id} = args, %{
        context: %{cur_user: user}
      }) do
    CMS.create_article_tag(%Community{id: community_id}, thread, args, user)
  end

  def update_article_tag(_root, %{id: id} = args, _info) do
    CMS.update_article_tag(id, args)
  end

  def delete_article_tag(_root, %{id: id}, _info) do
    CMS.delete_article_tag(id)
  end

  def set_article_tag(_root, ~m(id thread article_tag_id)a, _info) do
    CMS.set_article_tag(thread, id, article_tag_id)
  end

  def unset_article_tag(_root, ~m(id thread article_tag_id)a, _info) do
    CMS.unset_article_tag(thread, id, article_tag_id)
  end

  def paged_article_tags(_root, %{filter: filter}, _info) do
    CMS.paged_article_tags(filter)
  end

  # #######################
  # community subscribe ..
  # #######################
  def subscribe_community(_root, ~m(community_id)a, %{context: ~m(cur_user remote_ip)a}) do
    CMS.subscribe_community(%Community{id: community_id}, cur_user, remote_ip)
  end

  def subscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_community(%Community{id: community_id}, cur_user)
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: ~m(cur_user remote_ip)a}) do
    CMS.unsubscribe_community(%Community{id: community_id}, cur_user, remote_ip)
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.unsubscribe_community(%Community{id: community_id}, cur_user)
  end

  def paged_community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %Community{id: id}, filter)
  end

  def paged_community_subscribers(_root, ~m(community filter)a, _info) do
    CMS.community_members(:subscribers, %Community{raw: community}, filter)
  end

  def paged_community_subscribers(_root, _args, _info), do: {:error, "invalid args"}

  def mirror_article(_root, ~m(thread id community_id)a, _info) do
    CMS.mirror_article(thread, id, community_id)
  end

  def unmirror_article(_root, ~m(thread id community_id)a, _info) do
    CMS.unmirror_article(thread, id, community_id)
  end

  def move_article(_root, ~m(thread id community_id)a, _info) do
    CMS.move_article(thread, id, community_id)
  end

  # #######################
  # comemnts ..
  # #######################
  def paged_article_comments(_root, ~m(id thread filter mode)a, %{context: %{cur_user: user}}) do
    case mode do
      :replies -> CMS.paged_article_comments(thread, id, filter, :replies, user)
      :timeline -> CMS.paged_article_comments(thread, id, filter, :timeline, user)
    end
  end

  def paged_article_comments(_root, ~m(id thread filter mode)a, _info) do
    case mode do
      :replies -> CMS.paged_article_comments(thread, id, filter, :replies)
      :timeline -> CMS.paged_article_comments(thread, id, filter, :timeline)
    end
  end

  def paged_article_comments_participators(_root, ~m(id thread filter)a, _info) do
    CMS.paged_article_comments_participators(thread, id, filter)
  end

  def create_article_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.create_article_comment(thread, id, body, user)
  end

  def update_article_comment(_root, ~m(body passport_source)a, _info) do
    comment = passport_source
    CMS.update_article_comment(comment, body)
  end

  def delete_article_comment(_root, ~m(passport_source)a, _info) do
    comment = passport_source
    CMS.delete_article_comment(comment)
  end

  def reply_article_comment(_root, ~m(id body)a, %{context: %{cur_user: user}}) do
    CMS.reply_article_comment(id, body, user)
  end

  def upvote_article_comment(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.upvote_article_comment(id, user)
  end

  def undo_upvote_article_comment(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.undo_upvote_article_comment(id, user)
  end

  def emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.emotion_to_comment(id, emotion, user)
  end

  def undo_emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.undo_emotion_to_comment(id, emotion, user)
  end

  def mark_comment_solution(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.mark_comment_solution(id, user)
  end

  def undo_mark_comment_solution(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.undo_mark_comment_solution(id, user)
  end

  ############
  ############
  ############

  def paged_comment_replies(_root, ~m(id filter)a, %{context: %{cur_user: user}}) do
    CMS.paged_comment_replies(id, filter, user)
  end

  def paged_comment_replies(_root, ~m(id filter)a, _info) do
    CMS.paged_comment_replies(id, filter)
  end

  def stamp_passport(_root, ~m(user_id rules)a, %{context: %{cur_user: _user}}) do
    CMS.stamp_passport(rules, %User{id: user_id})
  end

  # #######################
  # sync github content ..
  # #######################
  def sync_wiki(_root, ~m(community_id readme last_sync)a, %{context: %{cur_user: _user}}) do
    CMS.sync_github_content(%Community{id: community_id}, :wiki, ~m(readme last_sync)a)
  end

  def add_wiki_contributor(_root, ~m(id contributor)a, %{context: %{cur_user: _user}}) do
    CMS.add_contributor(%CommunityWiki{id: id}, contributor)
  end

  def sync_cheatsheet(_root, ~m(community_id readme last_sync)a, %{context: %{cur_user: _user}}) do
    CMS.sync_github_content(%Community{id: community_id}, :cheatsheet, ~m(readme last_sync)a)
  end

  def add_cheatsheet_contributor(_root, ~m(id contributor)a, %{context: %{cur_user: _user}}) do
    CMS.add_contributor(%CommunityCheatsheet{id: id}, contributor)
  end

  def search_communities(_root, %{title: title}, _info) do
    CMS.search_communities(title)
  end

  def search_articles(_root, %{thread: thread, title: title}, _info) do
    CMS.search_articles(thread, %{title: title})
  end

  # ##############################################
  # counts just for manngers to use in admin site ..
  # ##############################################
  def threads_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :threads)
  end

  def article_tags_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :article_tags)
  end
end
