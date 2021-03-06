# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.CommonResolver do

  alias Ecto.ULID
  alias MoodleNet.GraphQL
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Communities.Community
  alias MoodleNet.GraphQL.{Fields, Flow}
  alias MoodleNet.Resources.Resource
  alias MoodleNet.Likes.Like
  alias MoodleNet.Follows.Follow
  alias MoodleNet.Features.Feature
  alias MoodleNet.Flags.Flag
  alias MoodleNet.Threads.{Comment, Thread}
  alias MoodleNet.Meta.Pointers
  alias MoodleNet.Users.User
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def created_at_edge(%{id: id}, _, _), do: ULID.timestamp(id)

  def context_edge(%{context_id: id}, _, info) do
    Flow.fields(__MODULE__, :fetch_context_edge, id, info)
  end
  
  def fetch_context_edge(_, ids) do
    {:ok, ptrs} = Pointers.many(id: ids)
    Fields.new(Pointers.follow!(ptrs), &(&1.id))
  end

  # defp preload_context(%{context: %NotLoaded{}}=me), do: Repo.preload(me, :context)
  # defp preload_context(%{context: %{}}=me), do: me
  # defp preload_context(me), do: Repo.preload(me, :context)

  # def loaded_context(%Community{}=community), do: Repo.preload(community, :actor)
  # def loaded_context(%Collection{}=collection), do: Repo.preload(collection, :actor)
  # def loaded_context(%User{}=user), do: Repo.preload(user, :actor)
  # def loaded_context(other), do: other

  # def tag(%{tag_id: id}, info) do
  #   {:ok, Fake.tag()}
  #   |> GraphQL.response(info)
  # end
  # def tag_category(%{tag_category_id: id}, info) do
  #   {:ok, Fake.tag_category()}
  #   |> GraphQL.response(info)
  # end
  # def tag_category(_, _, info) do
  #   {:ok, Fake.tag_category()}
  #   |> GraphQL.response(info)
  # end
  # def tagging(%{tagging_id: id}, info) do
  #   {:ok, Fake.tagging()}
  #   |> GraphQL.response(info)
  # end
  # def taggings(_, _, info) do
  #   {:ok, Fake.long_edge_list(&Fake.tagging/0)}
  #   |> GraphQL.response(info)
  # end

  def is_public_edge(parent, _, _), do: {:ok, not is_nil(parent.published_at)}
  def is_local_edge(%{is_local: is_local}, _, _), do: {:ok, is_local}
  def is_disabled_edge(parent, _, _), do: {:ok, not is_nil(parent.disabled_at)}
  def is_hidden_edge(parent, _, _), do: {:ok, not is_nil(parent.hidden_at)}
  def is_deleted_edge(parent, _, _), do: {:ok, not is_nil(parent.deleted_at)}

  # def followed(%Follow{}=follow,_,info)

  def delete(%{context_id: id}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
         {:ok, pointer} <- Pointers.one(id: id) do
      context = Pointers.follow!(pointer)
      if allow_delete?(user, context) do
        do_delete(context)
      else
        GraphQL.not_permitted("delete")
      end
    end
  end

  defp do_delete(%Community{}=c), do: MoodleNet.Communities.soft_delete(c)
  defp do_delete(%Collection{}=c), do: MoodleNet.Collections.soft_delete(c)
  defp do_delete(%Resource{}=r), do: MoodleNet.Resources.soft_delete(r)
  defp do_delete(%Comment{}=c), do: MoodleNet.Threads.Comments.soft_delete(c)
  defp do_delete(%Feature{}=f), do: MoodleNet.Features.soft_delete(f)
  defp do_delete(%Thread{}=t), do: MoodleNet.Threads.soft_delete(t)
  defp do_delete(%Follow{}=f), do: MoodleNet.Follows.undo(f)
  defp do_delete(%Flag{}=f), do: MoodleNet.Flags.resolve(f)
  defp do_delete(%Like{}=l), do: MoodleNet.Likes.undo(l)

  defp do_delete(%User{}=u) do
    with {:ok, u} <- MoodleNet.Users.one([:default, id: u.id]) do
      MoodleNet.Users.soft_delete(u)
    end
  end

  defp do_delete(_), do: GraphQL.not_permitted("delete")

  # FIXME: boilerplate code
  defp allow_delete?(user, context) do
    user.local_user.is_instance_admin or allow_user_delete?(user, context)
  end

  defp allow_user_delete?(user, %{__struct__: type, creator_id: creator_id} = context) do
    type in [Flag, Like, Follow, Thread, Comment] and creator_id == user.id
  end

  defp allow_user_delete?(_, _), do: false

  # def tag(_, _, info) do
  #   {:ok, Fake.tag()}
  #   |> GraphQL.response(info)
  # end

  # def create_tagging(_, info) do
  #   {:ok, Fake.tagging()}
  #   |> GraphQL.response(info)
  # end

  # def tags(parent, _, info) do
  #   {:ok, Fake.long_edge_list(&Fake.tagging/0)}
  #   |> GraphQL.response(info)
  # end

end
