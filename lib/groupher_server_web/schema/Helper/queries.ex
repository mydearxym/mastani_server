defmodule GroupherServerWeb.Schema.Helper.Queries do
  @moduledoc """
  common fields
  """
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  @article_threads get_config(:article, :article_threads)

  defmacro article_search_queries() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        @desc unquote("get #{thread} by id")
        field unquote(:"search_#{thread}s"), unquote(:"paged_#{thread}s") do
          arg(:title, non_null(:string))
          arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

          resolve(&R.CMS.search_contents/3)
        end
      end
    end)
  end

  @doc """
  query generator for threads, like:

  post, page_posts ...
  """
  defmacro article_queries(thread) do
    quote do
      @desc unquote("get #{thread} by id")
      field unquote(thread), non_null(unquote(thread)) do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        resolve(&R.CMS.read_article/3)
      end

      @desc unquote("get paged #{thread}s")
      field unquote(:"paged_#{thread}s"), unquote(:"paged_#{thread}s") do
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))
        arg(:filter, non_null(unquote(:"paged_#{thread}s_filter")))

        middleware(M.PageSizeProof)
        resolve(&R.CMS.paged_articles/3)
      end
    end
  end

  defmacro article_reacted_users_query(action, resolver) do
    quote do
      @desc unquote("get paged #{action}ed users of an article")
      field unquote(:"#{action}ed_users"), :paged_users do
        arg(:id, non_null(:id))
        arg(:thread, :thread, default_value: :post)
        arg(:filter, non_null(:paged_filter))

        middleware(M.PageSizeProof)
        resolve(unquote(resolver))
      end
    end
  end
end
