# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Follows.Queries do

  alias MoodleNet.Follows.Follow
  alias MoodleNet.Meta.PointersQueries
  alias MoodleNet.Users.User
  import MoodleNet.Common.Query, only: [match_admin: 0]
  import Ecto.Query

  def query(Follow) do
    from f in Follow, as: :follow
  end

  def query(query, filters), do: filter(query(query), filters)

  def join_to(q, rel, jq \\ :left)

  def join_to(q, {jq, join}, _jq), do: join_to(q, join, jq)

  def join_to(q, :context, jq) do
    join q, jq, [follow: f], c in assoc(f, :context), as: :pointer
  end

  @doc "Filter the query according to arbitrary criteria"
  def filter(q, filter_or_filters)

  ## by many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by join

  def filter(q, {:join,{rel, jq}}), do: join_to(q, rel, jq)

  def filter(q, {:join, rel}), do: join_to(q, rel)

  ## by users
  
  def filter(q, {:user, match_admin()}) do
    filter(q, :deleted)
  end

  def filter(q, {:user, %User{id: id}}) do
    q
    |> where([follow: f], not is_nil(f.published_at) or f.creator_id == ^id)
    |> filter(:deleted)
  end

  def filter(q, {:user, nil}) do # guest
    filter q, ~w(deleted private)a
  end

  ## by status
  
  def filter(q, :deleted) do
    where q, [follow: f], is_nil(f.deleted_at)
  end

  def filter(q, :private) do
    where q, [follow: f], not is_nil(f.published_at)
  end

  # by field values

  def filter(q, {:id, id}) when is_binary(id) do
    where q, [follow: f], f.id == ^id
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where q, [follow: f], f.id in ^ids
  end

  def filter(q, {:context_id, id}) when is_binary(id) do
    where q, [follow: f], f.context_id == ^id
  end

  def filter(q, {:context_id, ids}) when is_list(ids) do
    where q, [follow: f], f.context_id in ^ids
  end

  def filter(q, {:creator_id, id}) when is_binary(id) do
    where q, [follow: f], f.creator_id == ^id
  end

  def filter(q, {:creator_id, ids}) when is_list(ids) do
    where q, [follow: f], f.creator_id in ^ids
  end

  def filter(q, {:id, id}) when is_binary(id) do
    where q, [follow: f], f.id == ^id
  end

  def filter(q, {:id, {:lte, id}}) when is_binary(id) do
    where q, [follow: f], f.id <= ^id
  end

  def filter(q, {:id, {:gte, id}}) when is_binary(id) do
    where q, [follow: f], f.id >= ^id
  end

  ## by foreign field

  def filter(q, {:table_id, ids}), do: PointersQueries.filter(q, table_id: ids)

  def filter(q, {:table, tables}), do: PointersQueries.filter(q, table: tables)

  ## by order

  def filter(q, {:order, :timeline_desc}), do: filter(q, {:order, [desc: :created]})

  def filter(q, {:order, [desc: :created]}) do
    order_by q, [follow: f], [desc: f.id]
  end

  ## by group / count

  def filter(q, {:group_count, key}) when is_atom(key) do
    filter q, group: key, count: key
  end
    
  def filter(q, {:group, key}) when is_atom(key) do
    group_by q, [follow: f], field(f, ^key)
  end

  def filter(q, {:count, key}) when is_atom(key) do
    select q, [follow: f], {field(f, ^key), count(f.id)}
  end

  def filter(q, {:preload, :context}) do
    preload q, [pointer: p], [context: p]
  end

  def filter(q, {:limit, limit}) do
    limit(q, ^limit)
  end

  def filter(q, {:page, [desc: [created: page_opts]]}) do
    q
    |> filter(order: [desc: :created])
    |> page(page_opts, [desc: :created])
  end


  defp page(q, %{after: [id], limit: limit}, [desc: :created]) do
    filter(q, id: {:lte, id}, limit: limit + 2)
  end

  defp page(q, %{before: [id], limit: limit}, [desc: :created]) do
    filter(q, id: {:gte, id}, limit: limit + 2)
  end

  defp page(q, %{limit: limit}, _) do
    filter(q, limit: limit + 1)
  end

end
