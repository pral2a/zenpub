# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Test.Faking do
  alias MoodleNet.Test.Fake
  alias MoodleNet.{
    Access,
    Activities,
    Actors,
    Comments,
    Communities,
    Collections,
    Meta,
    Peers,
    Users,
    Localisation,
    Resources,
    Access,
  }
  alias MoodleNet.Actors.Actor
  alias MoodleNet.Users.User

  def fake_register_email_domain_access!(domain \\ Fake.domain())
  when is_binary(domain) do
    {:ok, wl} = Access.create_register_email_domain(domain)
    wl
  end

  def fake_register_email_access!(email \\ Fake.email())
  when is_binary(email) do
    {:ok, wl} = Access.create_register_email(email)
    wl
  end

  def fake_language!(overrides \\ %{}) do
    overrides
    |> Map.get(:id, "en")
    |> Localisation.language!()
  end

  def fake_peer!(overrides \\ %{}) when is_map(overrides) do
    {:ok, peer} = Peers.create(Fake.peer(overrides))
    peer
  end

  def fake_activity!(user, context, overrides \\ %{}) do
    {:ok, activity} = Activities.create(user, context, Fake.activity(overrides))
    activity
  end

  def fake_actor!(overrides \\ %{}) when is_map(overrides) do
    {:ok, actor} = Actors.create(Fake.actor(overrides))
    actor
  end

  def fake_user!(overrides \\ %{}, opts \\ []) when is_map(overrides) and is_list(opts) do
    {:ok, user} = Users.register(Fake.user(overrides), public_registration: true)
    user
    |> maybe_confirm_user_email(opts)
  end

  defp maybe_confirm_user_email(user, opts) do
    if Keyword.get(opts, :confirm_email) do
      {:ok, user} = Users.confirm_email(user)
      user
    else
      user
    end
  end

  def fake_token!(%User{}=user) do
    {:ok, token} = Access.unsafe_put_token(user)
    token
  end

  def fake_community!(user, overrides \\ %{})
  def fake_community!(%User{}=user, %{}=overrides) do
    {:ok, community} = Communities.create(user, Fake.community(overrides))
    community
  end

  def fake_collection!(user, community, overrides \\ %{}) when is_map(overrides) do
    {:ok, collection} = Collections.create(user, community, Fake.collection(overrides))
    collection
  end

  def fake_resource!(user, collection, overrides \\ %{}) when is_map(overrides) do
    {:ok, resource} = Resources.create(user, collection, Fake.resource(overrides))
    resource
  end

  def fake_thread!(user, parent, overrides \\ %{}) when is_map(overrides) do
    {:ok, thread} = Comments.create_thread(user, parent, Fake.thread(overrides))
    thread
  end

  def fake_comment!(user, thread, overrides \\ %{}) when is_map(overrides) do
    {:ok, comment} = Comments.create_comment(user, thread, Fake.comment(overrides))
    comment
  end

end
