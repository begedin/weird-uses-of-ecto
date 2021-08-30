defmodule WUE.Pictures.QueryMacros do
  @moduledoc """
  Badly named and placed module, served to hold macro(s) used in the
  `WUE.Pictures` context.
  """
  import Ecto.Query, only: [join: 5]
  alias Ecto.Query

  @doc """
  Adds a named binding join to the query only if there is no such named binding
  in the query already.

  See `WUE.Pictures.Filter` for examples of this being used.

  This can be useful when building flexible filtering logic, but works best if
  a convention is established where specific joins are always named a specific
  way.

  For example, a picture could have multiple contributing artists, but only one
  primary artist.

  To avoid issues, the join on contributing artists should always be named
  `:contributing_artist`, while the join on the primary artist should always be
  `:primary_artist`.

  """
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
