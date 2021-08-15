defmodule WUE.Pictures.QueryMacros do
  import Ecto.Query, only: [join: 5]
  alias Ecto.Query

  defmacro maybe_join(query, qual, binding \\ [], expr, opts \\ []) do
    table_alias = Keyword.get(opts, :as)

    quote do
      if Query.has_named_binding?(unquote(query), unquote(table_alias)) do
        unquote(query)
      else
        join(
          unquote(query),
          unquote(qual),
          unquote(binding),
          unquote(expr),
          unquote(opts)
        )
      end
    end
  end
end
