defmodule GroupherServerWeb.Schema.Helper.Mutations do
  @moduledoc """
  common fields
  """
  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  defmacro article_upvote_mutation(thread) do
    quote do
      @desc unquote("upvote to #{thread}")
      field unquote(:"upvote_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.upvote_article/3)
      end

      @desc unquote("undo upvote to #{thread}")
      field unquote(:"undo_upvote_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_upvote_article/3)
      end
    end
  end

  defmacro article_pin_mutation(thread) do
    quote do
      @desc unquote("pin to #{thread}")
      field unquote(:"pin_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.pin"))
        resolve(&R.CMS.pin_article/3)
      end

      @desc unquote("undo pin to #{thread}")
      field unquote(:"undo_pin_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.undo_pin"))
        resolve(&R.CMS.undo_pin_article/3)
      end
    end
  end

  defmacro article_trash_mutation(thread) do
    quote do
      @desc unquote("trash a #{thread}, not delete")
      field unquote(:"trash_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.trash"))

        resolve(&R.CMS.trash_content/3)
      end

      @desc unquote("undo trash a #{thread}, not delete")
      field unquote(:"undo_trash_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.undo_trash"))

        resolve(&R.CMS.undo_trash_content/3)
      end
    end
  end

  # TODO: if post belongs to multi communities, unset instead delete
  defmacro article_delete_mutation(thread) do
    quote do
      @desc unquote("delete a #{thread}, not delete")
      field unquote(:"delete_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: unquote(thread))
        middleware(M.Passport, claim: unquote("owner;cms->c?->#{to_string(thread)}.delete"))

        resolve(&R.CMS.delete_content/3)
      end
    end
  end

  defmacro article_emotion_mutation(thread) do
    quote do
      @desc unquote("emotion to #{thread}")
      field unquote(:"emotion_to_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:emotion, non_null(:article_emotion))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.emotion_to_article/3)
      end

      @desc unquote("undo emotion to #{thread}")
      field unquote(:"undo_emotion_to_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:emotion, non_null(:article_emotion))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_emotion_to_article/3)
      end
    end
  end

  defmacro article_report_mutation(thread) do
    quote do
      @desc unquote("report a #{thread}")
      field unquote(:"report_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:reason, non_null(:string))
        arg(:attr, :string, default_value: "")
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.report_article/3)
      end

      @desc unquote("undo report a #{thread}")
      field unquote(:"undo_report_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_report_article/3)
      end
    end
  end
end