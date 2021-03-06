defmodule GroupherServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """

  alias GroupherServer.CMS.Delegate

  alias Delegate.{
    AbuseReport,
    ArticleCURD,
    ArticleCommunity,
    ArticleEmotion,
    CitedArtiment,
    CommentCurd,
    ArticleCollect,
    ArticleUpvote,
    CommentAction,
    CommentEmotion,
    ArticleTag,
    CommunitySync,
    CommunityCURD,
    CommunityOperation,
    PassportCURD,
    Search,
    Seeds
  }

  # do not pattern match in delegating func, do it on one delegating inside
  # see https://github.com/elixir-lang/elixir/issues/5306

  # Community CURD: editors, thread, tag
  defdelegate read_community(args), to: CommunityCURD
  defdelegate read_community(args, user), to: CommunityCURD
  defdelegate create_community(args), to: CommunityCURD
  defdelegate update_community(id, args), to: CommunityCURD
  # >> editor ..
  defdelegate update_editor(user, community, title), to: CommunityCURD
  # >> geo info ..
  defdelegate community_geo_info(community), to: CommunityCURD
  # >> subscribers / editors
  defdelegate community_members(type, community, filters), to: CommunityCURD
  # >> category
  defdelegate create_category(category_attrs, user), to: CommunityCURD
  defdelegate update_category(category_attrs), to: CommunityCURD
  # >> thread
  defdelegate create_thread(attrs), to: CommunityCURD
  defdelegate count(community, part), to: CommunityCURD
  # >> tag
  defdelegate create_article_tag(community, thread, attrs, user), to: ArticleTag
  defdelegate update_article_tag(tag_id, attrs), to: ArticleTag
  defdelegate delete_article_tag(tag_id), to: ArticleTag
  defdelegate set_article_tag(thread, article_id, tag_id), to: ArticleTag
  defdelegate unset_article_tag(thread, article_id, tag_id), to: ArticleTag
  defdelegate paged_article_tags(filter), to: ArticleTag

  # >> wiki & cheatsheet (sync with github)
  defdelegate get_wiki(community), to: CommunitySync
  defdelegate get_cheatsheet(community), to: CommunitySync
  defdelegate sync_github_content(community, thread, attrs), to: CommunitySync
  defdelegate add_contributor(content, attrs), to: CommunitySync

  # CommunityOperation
  # >> category
  defdelegate set_category(community, category), to: CommunityOperation
  defdelegate unset_category(community, category), to: CommunityOperation
  # >> editor
  defdelegate set_editor(community, title, user), to: CommunityOperation
  defdelegate unset_editor(community, user), to: CommunityOperation
  # >> thread
  defdelegate set_thread(community, thread), to: CommunityOperation
  defdelegate unset_thread(community, thread), to: CommunityOperation
  # >> subscribe / unsubscribe
  defdelegate subscribe_community(community, user), to: CommunityOperation
  defdelegate subscribe_community(community, user, remote_ip), to: CommunityOperation
  defdelegate unsubscribe_community(community, user), to: CommunityOperation
  defdelegate unsubscribe_community(community, user, remote_ip), to: CommunityOperation

  defdelegate subscribe_default_community_ifnot(user, remote_ip), to: CommunityOperation
  defdelegate subscribe_default_community_ifnot(user), to: CommunityOperation

  # ArticleCURD
  defdelegate read_article(thread, id), to: ArticleCURD
  defdelegate read_article(thread, id, user), to: ArticleCURD

  defdelegate paged_articles(queryable, filter), to: ArticleCURD
  defdelegate paged_articles(queryable, filter, user), to: ArticleCURD
  defdelegate paged_published_articles(queryable, filter, user), to: ArticleCURD

  defdelegate create_article(community, thread, attrs, user), to: ArticleCURD
  defdelegate update_article(article, attrs), to: ArticleCURD

  defdelegate mark_delete_article(thread, id), to: ArticleCURD
  defdelegate undo_mark_delete_article(thread, id), to: ArticleCURD
  defdelegate delete_article(article), to: ArticleCURD
  defdelegate delete_article(article, reason), to: ArticleCURD

  defdelegate update_active_timestamp(thread, article), to: ArticleCURD
  defdelegate sink_article(thread, id), to: ArticleCURD
  defdelegate undo_sink_article(thread, id), to: ArticleCURD

  defdelegate paged_citing_contents(type, id, filter), to: CitedArtiment

  defdelegate upvote_article(thread, article_id, user), to: ArticleUpvote
  defdelegate undo_upvote_article(thread, article_id, user), to: ArticleUpvote

  defdelegate upvoted_users(thread, article_id, filter), to: ArticleUpvote

  defdelegate collect_article(thread, article_id, user), to: ArticleCollect
  defdelegate collect_article_ifneed(thread, article_id, user), to: ArticleCollect

  defdelegate undo_collect_article(thread, article_id, user), to: ArticleCollect
  defdelegate undo_collect_article_ifneed(thread, article_id, user), to: ArticleCollect
  defdelegate collected_users(thread, article_id, filter), to: ArticleCollect

  defdelegate set_collect_folder(collect, folder), to: ArticleCollect
  defdelegate undo_set_collect_folder(collect, folder), to: ArticleCollect

  # ArticleCommunity
  # >> set flag on article, like: pin / unpin article
  defdelegate pin_article(thread, id, community_id), to: ArticleCommunity
  defdelegate undo_pin_article(thread, id, community_id), to: ArticleCommunity

  # >> community: set / unset
  defdelegate mirror_article(thread, article_id, community_id), to: ArticleCommunity
  defdelegate unmirror_article(thread, article_id, community_id), to: ArticleCommunity
  defdelegate move_article(thread, article_id, community_id), to: ArticleCommunity

  defdelegate emotion_to_article(thread, article_id, args, user), to: ArticleEmotion
  defdelegate undo_emotion_to_article(thread, article_id, args, user), to: ArticleEmotion

  # Comment CURD
  defdelegate paged_comments(thread, article_id, filters, mode), to: CommentCurd
  defdelegate paged_comments(thread, article_id, filters, mode, user), to: CommentCurd

  defdelegate paged_published_comments(user, thread, filters), to: CommentCurd
  defdelegate paged_published_comments(user, filters), to: CommentCurd

  defdelegate paged_folded_comments(thread, article_id, filters), to: CommentCurd
  defdelegate paged_folded_comments(thread, article_id, filters, user), to: CommentCurd

  defdelegate paged_comment_replies(comment_id, filters), to: CommentCurd
  defdelegate paged_comment_replies(comment_id, filters, user), to: CommentCurd

  defdelegate paged_comments_participants(thread, content_id, filters), to: CommentCurd

  defdelegate create_comment(thread, article_id, args, user), to: CommentCurd
  defdelegate update_comment(comment, content), to: CommentCurd
  defdelegate delete_comment(comment), to: CommentCurd
  defdelegate mark_comment_solution(comment, user), to: CommentCurd
  defdelegate undo_mark_comment_solution(comment, user), to: CommentCurd

  defdelegate upvote_comment(comment_id, user), to: CommentAction
  defdelegate undo_upvote_comment(comment_id, user), to: CommentAction
  defdelegate reply_comment(comment_id, args, user), to: CommentAction
  defdelegate lock_article_comments(thread, article_id), to: CommentAction
  defdelegate undo_lock_article_comments(thread, article_id), to: CommentAction

  defdelegate pin_comment(comment_id), to: CommentAction
  defdelegate undo_pin_comment(comment_id), to: CommentAction

  defdelegate fold_comment(comment_id, user), to: CommentAction
  defdelegate unfold_comment(comment_id, user), to: CommentAction

  defdelegate emotion_to_comment(comment_id, args, user), to: CommentEmotion
  defdelegate undo_emotion_to_comment(comment_id, args, user), to: CommentEmotion
  ###################
  ###################
  ###################
  ###################

  # TODO: move report to abuse report module
  defdelegate report_article(thread, article_id, reason, attr, user), to: AbuseReport
  defdelegate report_comment(comment_id, reason, attr, user), to: AbuseReport
  defdelegate report_account(account_id, reason, attr, user), to: AbuseReport
  defdelegate undo_report_account(account_id, user), to: AbuseReport
  defdelegate undo_report_article(thread, article_id, user), to: AbuseReport
  defdelegate paged_reports(filter), to: AbuseReport
  defdelegate undo_report_comment(comment_id, user), to: AbuseReport

  # Passport CURD
  defdelegate stamp_passport(rules, user), to: PassportCURD
  defdelegate erase_passport(rules, user), to: PassportCURD
  defdelegate get_passport(user), to: PassportCURD
  defdelegate paged_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user), to: PassportCURD

  # search
  defdelegate search_articles(thread, args), to: Search
  defdelegate search_communities(args), to: Search

  # seeds
  defdelegate seed_communities(opt), to: Seeds
  defdelegate seed_set_category(communities, category), to: Seeds
  defdelegate seed_bot, to: Seeds
end
