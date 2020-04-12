# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.CommunitiesResolver do
  @moduledoc """
  Performs the GraphQL Community queries.
  """
  alias MoodleNet.{Activities, Collections, Communities, GraphQL, Repo}
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Communities.Community
  alias MoodleNet.GraphQL.{
    FieldsFlow,
    Flow,
    Page,
    PageFlow,
    PagesFlow,
    ResolveField,
    ResolvePage,
    ResolvePages,
    ResolveRootPage,
  }
  def community(%{community_id: id}, info) do
    ResolveField.run(
      %ResolveField{
        module: __MODULE__,
        fetcher: :fetch_community,
        context: id,
        info: info,
      }
    )
  end

  def fetch_community(info, id) do
    Communities.one([
      :default,
      id: id,
      user: GraphQL.current_user(info)])
  end

  def communities(%{}=page_opts, info) do
    ResolveRootPage.run(
      %ResolveRootPage{
        module: __MODULE__,
        fetcher: :fetch_communities,
        page_opts: page_opts,
        info: info,
        cursor_validators: [&(is_integer(&1) and &1 >= 0), &Ecto.ULID.cast/1], # followers
      }
    )
  end

  def fetch_communities(page_opts, info) do
    PageFlow.run(
      %PageFlow{
        queries: Communities.Queries,
        query: Community,
        cursor_fn: Communities.cursor(:followers),
        page_opts: page_opts,
        base_filters: [user: GraphQL.current_user(info)],
        data_filters: [page: [desc: [followers: page_opts]], preload: :actor],
      }
    )
  end

  def collection_count_edge(%Community{id: id}, _, info) do
    Flow.fields __MODULE__, :fetch_collection_count_edge, id, info, default: 0
  end

  def fetch_collection_count_edge(_, ids) do
    FieldsFlow.run(
      %FieldsFlow{
        queries: Collections.Queries,
        query: Collection,
        group_fn: &elem(&1, 0),
        map_fn: &elem(&1, 1),
        filters: [community_id: ids, group_count: :community_id],
      }
    )
  end

  def collections_edge(%Community{id: id}, %{}=page_opts, info) do
    ResolvePages.run(
      %ResolvePages{
        module: __MODULE__,
        fetcher: :fetch_collections_edge,
        context: id,
        page_opts: page_opts,
        info: info,
      }
    )
  end

  # def collections_edge(%Community{collections: cs}, _, _info) when is_list(cs), do: {:ok, cs}
  # def collections_edge(%Community{id: id}, %{}=page_opts, info) do
  #   opts = %{default_limit: 10}
  #   Flow.pages(__MODULE__, :fetch_collections_edge, page_opts, id, info, opts)
  # end

  def fetch_collections_edge({page_opts, info}, ids) do
    user = GraphQL.current_user(info)
    PagesFlow.run(
      %PagesFlow{
        queries: Collections.Queries,
        query: Collection,
        cursor_fn: Collections.cursor(:followers),
        group_fn: &(&1.community_id),
        page_opts: page_opts,
        base_filters: [community_id: ids, user: user],
        data_filters: [page: [desc: [followers: page_opts]]],
        count_filters: [group_count: :community_id]
      }
    )
  end

  def fetch_collections_edge(page_opts, info, ids) do
    user = GraphQL.current_user(info)
    PageFlow.run(
      %PageFlow{
        queries: Collections.Queries,
        query: Collection,
        cursor_fn: Collections.cursor(:followers),
        page_opts: page_opts,
        base_filters: [community_id: ids, user: user],
        data_filters: [page: [desc: [followers: page_opts]]],
      }
    )
  end

  def inbox_edge(_community, _, _info) do
    {:ok, Page.new([], [], &(&1.id), %{})}
  end

  def outbox_edge(%Community{outbox_id: id}, page_opts, info) do
    Flow.pages(__MODULE__, :fetch_outbox_edge, page_opts, id, info, %{default_limit: 10})
  end

  ### def fetch_outbox_edge({page_opts, user}, id) do

  def fetch_outbox_edge(page_opts, _info, id) do
    Activities.page(
      &(&1.id),
      page_opts,
      [join: :feed_activity,
       feed_id: id,
       table: default_outbox_query_contexts(),
       distinct: [desc: :id], # this does the actual ordering *sigh*
       order: :timeline_desc] # this is here because ecto has made questionable choices
    )
  end

  defp default_outbox_query_contexts() do
    Application.fetch_env!(:moodle_net, Communities)
    |> Keyword.fetch!(:default_outbox_query_contexts)
  end

  # def batch_outbox_edge({page_opts, user}, ids) do
  # end

  def last_activity_edge(_, _, _info), do: {:ok, DateTime.utc_now()}


  ### mutations


  def create_community(%{community: attrs}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      Communities.create(user, attrs)
    end
  end

  def update_community(%{community: changes, community_id: id}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, community} <- community(%{community_id: id}, info) do
        cond do
          user.local_user.is_instance_admin ->
            Communities.update(community, changes)

          community.creator_id == user.id ->
            Communities.update(community, changes)

          is_nil(community.published_at) -> GraphQL.not_found()

          true -> GraphQL.not_permitted()
        end
      end
    end)
  end

  # def delete(%{community_id: id}, info) do
  #   Repo.transact_with(fn ->
  #     with {:ok, user} <- GraphQL.current_user(info),
  #          {:ok, actor} <- Users.fetch_actor(user),
  #          {:ok, community} <- Communities.fetch(id) do
  #       if community.creator_id == actor.id do
  # 	  with {:ok, _} <- Communities.soft_delete(community), do: {:ok, true}
  #       else
  #         GraphQL.not_permitted()
  #       end
  #     end
  #   end)
  #   |> GraphQL.response(info)
  # end


end
