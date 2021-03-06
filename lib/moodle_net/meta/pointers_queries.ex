# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Meta.PointersQueries do

  alias MoodleNet.Meta.{Pointer, TableService}
  import Ecto.Query

  def query(Pointer) do
    from p in Pointer, as: :pointer
  end

  def query(q, filters), do: filter(query(q), filters)

  @doc "Filter the query according to arbitrary criteria"
  def filter(q, filter_or_filters)

  ## by many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by fields

  def filter(q, {:id, id}) when is_binary(id) do
    where q, [pointer: p], p.id == ^id
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where q, [pointer: p], p.id in ^ids
  end

  def filter(q, {:table_id, id}) when is_binary(id) do
    where q, [pointer: p], p.table_id == ^id
  end

  def filter(q, {:table_id, ids}) when is_list(ids) do
    where q, [pointer: p], p.table_id in ^ids
  end

  def filter(q, {:table, table}) when is_atom(table) do
    id = TableService.lookup_id!(table)
    where q, [pointer: p], p.table_id == ^id
  end

  def filter(q, {:table, tables}) when is_list(tables) do
    ids = Enum.map(tables, &TableService.lookup_id!/1)
    where q, [pointer: p], p.table_id in ^ids
  end
  
end
