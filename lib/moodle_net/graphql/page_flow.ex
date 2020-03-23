# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.GraphQL.PageFlow do
  @enforce_keys [:queries, :query, :cursor_fn, :page_opts]
  defstruct [
    :queries,
    :query,
    :cursor_fn,
    :page_opts,
    base_filters: [],
    data_filters: [],
    count_filters: [],
    count_with: :count,
    data_transform: nil,
    count_transform: nil,
  ]

  alias MoodleNet.Repo
  alias MoodleNet.GraphQL.{Page, PageFlow}

  @type t :: %PageFlow{
    queries: atom,
    query: atom,
    cursor_fn: (term -> term),
    page_opts: map,
    base_filters: list,
    data_filters: list,
    count_filters: list,
    count_with: :count | :all,
    data_transform: ([term] -> [term]) | nil,
    count_transform: (term -> term) | nil,
  }

  def run(
    %PageFlow{
      queries: queries,
      query: query,
      cursor_fn: cursor_fn,
      page_opts: page_opts,
      base_filters: base_filters,
      data_filters: data_filters,
      count_filters: count_filters,
      count_with: count_with,
      data_transform: data_transform,
      count_transform: count_transform,
    }
  ) do
    base_q = apply(queries, :query, [query, base_filters])
    data_q = apply(queries, :filter, [base_q, data_filters])
    count_q = apply(queries, :filter, [base_q, count_filters])
    {:ok, [data, count]} = Repo.transact_many([{:all, data_q}, {count_with, count_q}])
    data = transform(data_transform, data)
    count = transform(count_transform, count)
    {:ok, Page.new(data, count, cursor_fn, page_opts)}
  end

  defp transform(nil, data), do: data
  defp transform(fun, data) when is_function(fun, 1), do: fun.(data)

end
