# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Communities do
  alias Ecto.Changeset
  alias MoodleNet.{Activities, Actors, Common, Feeds, Follows, Repo}
  alias MoodleNet.GraphQL.{Fields, Page, Pages}
  alias MoodleNet.Common.Contexts
  alias MoodleNet.Communities.{Community, Queries}
  alias MoodleNet.Feeds.FeedActivities
  alias MoodleNet.Users.User

  def cursor(:followers), do: &[&1.follower_count, &1.id]
  def test_cursor(:followers), do: &[&1["followerCount"], &1["id"]]

  @doc """
  Retrieves a single community by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for communities (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(Community, filters))

  @doc """
  Retrieves a list of communities by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for communities (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Community, filters))}

  def fields(group_fn, filters \\ [])
  when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of communities according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def page(cursor_fn, %{}=page_opts, base_filters, data_filters, count_filters) do
    Contexts.page Queries, Community,
      cursor_fn, page_opts, base_filters, data_filters, count_filters
  end

  @doc """
  Retrieves an Pages of communities according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(cursor_fn, group_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Contexts.pages Queries, Community,
      cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters
  end



  @spec create(User.t(), attrs :: map) :: {:ok, Community.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, %{} = attrs) do
    Repo.transact_with(fn ->
      with {:ok, actor} <- Actors.create(attrs),
           {:ok, comm_attrs} <- create_boxes(actor, attrs),
           {:ok, comm} <- insert_community(creator, actor, comm_attrs),
           act_attrs = %{verb: "created", is_local: is_nil(actor.peer_id)},
           {:ok, activity} <- Activities.create(creator, comm, act_attrs),
           {:ok, _follow} <- Follows.create(creator, comm, %{is_local: true}),
           :ok <- publish(creator, comm, activity, :created) do
        {:ok, comm}
      end
    end)
  end

  defp create_boxes(%{peer_id: nil}, attrs), do: create_local_boxes(attrs)
  defp create_boxes(%{peer_id: _}, attrs), do: create_remote_boxes(attrs)

  defp create_local_boxes(attrs) do
    with {:ok, inbox} <- Feeds.create(),
         {:ok, outbox} <- Feeds.create() do
      extra = %{inbox_id: inbox.id, outbox_id: outbox.id}
      {:ok, Map.merge(attrs, extra)}
    end
  end

  defp create_remote_boxes(attrs) do
    with {:ok, outbox} <- Feeds.create() do
      {:ok, Map.put(attrs, :outbox_id, outbox.id)}
    end
  end

  defp insert_community(creator, actor, attrs) do
    with {:ok, community} <- Repo.insert(Community.create_changeset(creator, actor, attrs)) do
      {:ok, %{ community | actor: actor }}
    end
  end

  defp publish(creator, community, activity, :created) do
    feeds = [community.outbox_id, creator.outbox_id, Feeds.instance_outbox_id()]
    with :ok <- FeedActivities.publish(activity, feeds) do
      ap_publish(community.id, creator.id, community.actor.peer_id)
    end
  end
  defp publish(community, :updated) do
    ap_publish(community.id, community.creator_id, community.actor.peer_id) # TODO: wrong if edited by admin
  end
  defp publish(community, :deleted) do
    ap_publish(community.id, community.creator_id, community.actor.peer_id) # TODO: wrong if edited by admin
  end

  defp ap_publish(context_id, user_id, nil) do
    MoodleNet.FeedPublisher.publish(%{
      "context_id" => context_id,
      "user_id" => user_id,
    })
  end
  defp ap_publish(_, _, _), do: :ok

  @spec update(%Community{}, attrs :: map) :: {:ok, Community.t()} | {:error, Changeset.t()}
  def update(%Community{} = community, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      with {:ok, comm} <- Repo.update(Community.update_changeset(community, attrs)),
           {:ok, actor} <- Actors.update(community.actor, attrs),
           community <- %{ comm | actor: actor },
           :ok <- publish(community, :updated)  do
        {:ok, %{ comm | actor: actor}}
      end
    end)
  end

  def outbox(%Community{outbox_id: id}, page_opts \\ %{}) do
    Activities.page(
      &(&1.id),
      join: {:feed_activity, :inner},
      feed_id: id,
      table: default_outbox_query_contexts(),
      distinct: [desc: :id], # this does the actual ordering *sigh*
      paginate: {:timeline_desc, page_opts} # this does an order too to appease ecto
    )
  end

  def soft_delete(%Community{} = community) do
    Repo.transact_with(fn ->
      with {:ok, community} <- Common.soft_delete(community),
           :ok <- publish(community, :deleted) do
        {:ok, community}
      end
    end)
  end

  # defp default_inbox_query_contexts() do
  #   Application.fetch_env!(:moodle_net, __MODULE__)
  #   |> Keyword.fetch!(:default_inbox_query_contexts)
  # end

  defp default_outbox_query_contexts() do
    Application.fetch_env!(:moodle_net, __MODULE__)
    |> Keyword.fetch!(:default_outbox_query_contexts)
  end

end
