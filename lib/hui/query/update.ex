defmodule Hui.Query.Update do
  @moduledoc """
  Struct related to Solr updating.

  ## Example
  ```
      alias Hui.Query
      alias Hui.Encoder

      # Update / index 2 documents, commit them within 1s
      iex> doc1 = %{"name" => "The Turin Horse", "directed_by" => ["Béla Tarr"], "genre" => ["Drama"], "id" => "tt1316540"}
      %{
        "directed_by" => ["Béla Tarr"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "name" => "The Turin Horse"
      }
      iex> doc2 = %{"name" => "I Wish", "directed_by" => ["Hirokazu Koreeda"], "genre" => ["Drama"], "id" => "tt1650453"}
      %{
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drama"],
        "id" => "tt1650453",
        "name" => "I Wish"
      }
      iex> x = %Query.Update{doc: [doc1, doc2], commit: true, commitWithin: 1000}
      %Hui.Query.Update{
        commit: true,
        commitWithin: 1000,
        delete_id: nil,
        delete_query: nil,
        doc: [
          %{
            "directed_by" => ["Béla Tarr"],
            "genre" => ["Drama"],
            "id" => "tt1316540",
            "name" => "The Turin Horse"
          },
          %{
            "directed_by" => ["Hirokazu Koreeda"],
            "genre" => ["Drama"],
            "id" => "tt1650453",
            "name" => "I Wish"
          }
        ],
        expungeDeletes: nil,
        maxSegments: nil,
        optimize: nil,
        overwrite: nil,
        rollback: nil,
        waitSearcher: nil
      }
      iex> x |> Encoder.encode
      "{\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"The Turin Horse\\\",\\\"id\\\":\\\"tt1316540\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Béla Tarr\\\"]}},\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"I Wish\\\",\\\"id\\\":\\\"tt1650453\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Hirokazu Koreeda\\\"]}},\\\"commit\\\":{}}"

      # Delete the documents by ID
      iex> %Query.Update{delete_id: ["tt1316540", "tt1650453"]} |> Encoder.encode
      "{\\\"delete\\\":{\\\"id\\\":\\\"tt1316540\\\"},\\\"delete\\\":{\\\"id\\\":\\\"tt1650453\\\"}}"

      # Delete the documents by filter query
      iex> %Query.Update{delete_query: "id:tt*"} |> Encoder.encode
      "{\\\"delete\\\":{\\\"query\\\":\\\"id:tt*\\\"}}"

      # Commits the docs, make them visible and remove previously deleted docs from the index
      iex> %Query.Update{commit: true, waitSearcher: true, expungeDeletes: true} |> Encoder.encode
      "{\\\"commit\\\":{\\\"waitSearcher\\\":true,\\\"expungeDeletes\\\":true}}"

      # Optimise the index, and keep the number of index segments 10 max
      iex> %Query.Update{optimize: true, maxSegments: 10} |> Encoder.encode
      "{\\\"optimize\\\":{\\\"maxSegments\\\":10}}"
  ```
  """

  defstruct [
    :commit,
    :commitWithin,
    :delete_id,
    :delete_query,
    :doc,
    :expungeDeletes,
    :maxSegments,
    :optimize,
    :overwrite,
    :rollback,
    :waitSearcher
  ]

  @typedoc """
  Struct related to Solr [updating](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html).
  """
  @type t :: %__MODULE__{
          commit: boolean,
          commitWithin: integer,
          delete_id: binary | list(binary),
          delete_query: binary | list(binary),
          doc: map | list(map),
          expungeDeletes: boolean,
          maxSegments: integer,
          optimize: boolean,
          overwrite: boolean,
          rollback: boolean,
          waitSearcher: boolean
        }

  @doc false
  @spec encode(Query.Update.t()) :: binary
  @deprecated "testing"
  # coveralls-ignore-start
  def encode(%__MODULE__{} = s) do
    a = "#{_encode(doc: s.doc, within: s.commitWithin, overwrite: s.overwrite)}"
    b = "#{_encode(delete_id: s.delete_id)}"
    c = "#{_encode(delete_query: s.delete_query)}"
    d = "#{_encode(commit: s.commit, wait: s.waitSearcher, expunge: s.expungeDeletes)}"
    e = "#{_encode(optimize: s.optimize, wait: s.waitSearcher, max: s.maxSegments)}"
    f = "#{_encode(rollback: s.rollback)}"

    x = [a, b, c, d, e, f] |> Enum.filter(fn x -> x != "" end)
    "{#{Enum.join(x, ",")}}"
  end

  defp _encode(doc) when is_map(doc), do: Poison.encode!(doc)

  defp _encode(doc: doc, within: w, overwrite: o) when is_map(doc),
    do: "\"add\":{#{_encode(within: w)}#{_encode(overwrite: o)}\"doc\":#{_encode(doc)}}"

  defp _encode(doc: [h | t], within: w, overwrite: o) when is_map(h),
    do: Enum.map_join([h] ++ t, ",", &_encode(doc: &1, within: w, overwrite: o))

  defp _encode(doc: _, within: _, overwrite: _), do: ""

  defp _encode(within: w) when is_integer(w), do: "\"commitWithin\":#{w},"
  defp _encode(within: _), do: ""

  defp _encode(overwrite: o) when is_boolean(o), do: "\"overwrite\":#{o},"
  defp _encode(overwrite: _), do: ""

  defp _encode(commit: true, wait: w, expunge: e) when is_boolean(w) and is_boolean(e),
    do: "\"commit\":{\"waitSearcher\":#{w},\"expungeDeletes\":#{e}}"

  defp _encode(commit: true, wait: w, expunge: nil) when is_boolean(w),
    do: "\"commit\":{\"waitSearcher\":#{w}}"

  defp _encode(commit: true, wait: nil, expunge: e) when is_boolean(e),
    do: "\"commit\":{\"expungeDeletes\":#{e}}"

  defp _encode(commit: true, wait: nil, expunge: nil), do: "\"commit\":{}"
  defp _encode(commit: _, wait: _, expunge: _), do: ""

  defp _encode(optimize: true, wait: w, max: m) when is_boolean(w) and is_integer(m),
    do: "\"optimize\":{\"waitSearcher\":#{w},\"maxSegments\":#{m}}"

  defp _encode(optimize: true, wait: w, max: nil) when is_boolean(w),
    do: "\"optimize\":{\"waitSearcher\":#{w}}"

  defp _encode(optimize: true, wait: nil, max: m) when is_integer(m),
    do: "\"optimize\":{\"maxSegments\":#{m}}"

  defp _encode(optimize: true, wait: nil, max: nil), do: "\"optimize\":{}"
  defp _encode(optimize: _, wait: _, max: _), do: ""

  defp _encode(delete_id: id) when is_binary(id), do: "\"delete\":{\"id\":\"#{id}\"}"

  defp _encode(delete_id: id) when is_list(id),
    do: Enum.map_join(id, ",", &_encode(delete_id: &1))

  defp _encode(delete_id: _), do: ""

  defp _encode(delete_query: q) when is_binary(q), do: "\"delete\":{\"query\":\"#{q}\"}"

  defp _encode(delete_query: q) when is_list(q),
    do: Enum.map_join(q, ",", &_encode(delete_query: &1))

  defp _encode(delete_query: _), do: ""

  defp _encode(rollback: true), do: "\"rollback\":{}"
  defp _encode(rollback: _), do: ""
  # coveralls-ignore-stop
end
