# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Workers.ActivityWorker do
  use Oban.Worker, queue: "mn_activities", max_attempts: 1

  require Logger

  alias MoodleNet.{Activities, Communities, Collections, Common, Meta, Repo, Users, Comments}
  alias MoodleNet.Common.{Follow, Like}
  alias MoodleNet.Comments.{Comment, Thread}
  alias MoodleNet.Communities.Community
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Users
  alias MoodleNet.Users.User
  import Ecto.Query

  @impl Worker
  def perform(
        %{
          "verb" => verb,
          "user_id" => user_id,
          "context_id" => context_id,
          "target_id" => target_id
        },
        _job
      ) do
    Repo.transaction(fn ->
      {:ok, user} = Users.fetch(user_id)
      context = context_id |> Meta.find!() |> Meta.follow!()

      {:ok, activity} = Activities.create(context, user, %{"verb" => verb, "is_local" => true})
      # created user is always notified
      {:ok, _} = insert_outbox(user, activity)

      target = target_id |> Meta.find!() |> Meta.follow!()
      {:ok, _} = insert_outbox(target, activity)
    end)
  end

  defp fetch_target!(%Follow{} = follow) do
    %Follow{followed: followed} = Common.preload_follow(follow)
    Meta.follow!(followed)
  end

  defp fetch_target!(%Like{} = like) do
    %Like{liked: liked} = Common.preload_like(like)
    Meta.follow!(liked)
  end

  defp fetch_target!(%Comment{} = comment) do
    {:ok, thread} = Comments.fetch_comment_thread(comment)
    # TODO: include reply_to comment
    thread
  end

  defp fetch_target!(%Thread{} = thread) do
    {:ok, context} = Comments.fetch_thread_context(thread)
    context
  end

  defp insert_outbox!(%User{} = user, activity) do
    Repo.insert!(Users.Outbox.changeset(user, activity))
  end

  defp insert_outbox!(%Community{} = community, activity) do
    Repo.insert!(Communities.Outbox.changeset(community, activity))
  end

  defp insert_outbox!(%Collection{} = collection, activity) do
    Repo.insert!(Collections.Outbox.changeset(collection, activity))

    {:ok, comm} = Communities.fetch(collection.community_id)
    insert_outbox!(comm, activity)
  end

  defp insert_outbox!(%{__struct__: type}, _activity) do
    Logger.warn("Unsupported type for outbox: #{to_string(type)}")
  end

  defp insert_inbox!(%Collection{} = collection, activity) do
    insert_follower_inbox!(collection, activity)

    {:ok, community} = Communities.fetch(collection.community_id)
    insert_inbox!(community, activity)
  end

  defp insert_inbox!(%Thread{} = thread, activity) do
    insert_follower_inbox!(thread, activity)

      if user.id != community.creator_id do
        {:ok, _} = insert_outbox(Communities.fetch_creator(community), activity)
      end
    end)
  end

  defp insert_inbox!(other, activity) do
    insert_follower_inbox!(other, activity)
  end

  defp insert_follower_inbox!(target, %{id: activity_id} = activity) do
    for follow <- Common.list_by_followed(target) do
      follower_id = follow.follower_id
      %Follow{follower: follower} = Common.preload_follow(follow)

      # FIXME: handle duplicates
      follower
      |> Users.Inbox.changeset(activity)
      |> Repo.insert!()
    end
  end
end
