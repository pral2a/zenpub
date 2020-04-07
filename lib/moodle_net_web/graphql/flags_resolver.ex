# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.FlagsResolver do

  alias MoodleNet.{Flags, GraphQL, Repo}
  alias MoodleNet.Flags.Flag
  alias MoodleNet.GraphQL.{Flow, PageFlow, PagesFlow}
  alias MoodleNet.Meta.Pointers
  alias MoodleNet.Users.User

  def flag(%{flag_id: id}, info) do
    with {:ok, %User{}=user} <- GraphQL.current_user_or_not_found(info) do
      Flags.one(id: id, user: user)
    end
  end

  def flags_edge(%{id: id}, %{}=page_opts, info) do
    vals = [&Ecto.ULID.cast/1]
    with {:ok, %User{}} <- GraphQL.current_user_or_empty_page(info) do
      opts = %{default_limit: 10}
      Flow.pages(__MODULE__, :fetch_flags_edge, page_opts, id, info, vals, opts)
    end
  end

  def fetch_flags_edge({page_opts, info}, ids) do
    user = GraphQL.current_user(info)
    PagesFlow.run(
      %PagesFlow{
        queries: Flags.Queries,
        query: Flag,
        cursor_fn: &[&1.id],
        group_fn: &(&1.context_id),
        page_opts: page_opts,
        base_filters: [:deleted, user: user, creator_id: ids],
        data_filters: [page: [desc: [created: page_opts]]],
        count_filters: [group_count: :creator_id],
      }
    )
  end

  def fetch_flags_edge(page_opts, info, ids) do
    user = GraphQL.current_user(info)
    PageFlow.run(
      %PageFlow{
        queries: Flags.Queries,
        query: Flag,
        cursor_fn: &[&1.id],
        page_opts: page_opts,
        base_filters: [:deleted, user: user, context_id: ids],
        data_filters: [page: [desc: [created: page_opts]]],
      }
    )
  end

  def is_resolved_edge(%Flag{}=flag, _, _), do: {:ok, not is_nil(flag.resolved_at)}

  def my_flag_edge(%{id: id}, _, info) do
    with {:ok, %User{}} <- GraphQL.current_user_or(info, nil) do
      Flow.fields __MODULE__, :fetch_my_flag_edge, id, info
    end
  end

  def fetch_my_flag_edge(_info, []), do: %{}
  def fetch_my_flag_edge(info, ids) do
    case GraphQL.current_user(info) do
      nil -> nil
      user ->
        {:ok, fields} = Flags.fields(
          &(&1.context_id),
          creator_id: user.id, context_id: ids
        )
        fields
    end
  end

  # TODO: store community id where appropriate
  def create_flag(%{context_id: id, message: message}, info) do
    Repo.transact_with(fn ->
      with {:ok, me} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, pointer} <- Pointers.one(id: id) do
        Flags.create(me, pointer, %{message: message, is_local: true})
      end
    end)
  end

end
