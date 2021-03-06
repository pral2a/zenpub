# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.FollowsTest do
  use MoodleNet.DataCase, async: true
  use Oban.Testing, repo: MoodleNet.Repo
  require Ecto.Query
  import MoodleNet.Test.Faking
  alias MoodleNet.{Blocks, Common, Features, Flags, Follows, Likes}
  alias MoodleNet.Test.Fake

  setup do
    {:ok, %{user: fake_user!()}}
  end

  def fake_followable!() do
    user = fake_user!()
    community = fake_community!(user)
    collection = fake_collection!(user, community)
    thread = fake_thread!(user, collection)
    Faker.Util.pick([user, community, collection, thread])
  end

  describe "many/1" do
    test "returns a list of follows for a user", %{user: follower} do
      follows =
        for _ <- 1..5 do
          followed = fake_followable!()
          assert {:ok, follow} = Follows.create(follower, followed, Fake.follow())
          follow
        end

      {:ok, fetched} = Follows.many(creator_id: follower.id)

      assert Enum.count(fetched) == Enum.count(follows)
    end

    test "returns a list of follows for an item" do
      followed = fake_followable!()

      follows =
        for _ <- 1..5 do
          follower = fake_user!()
          assert {:ok, follow} = Follows.create(follower, followed, Fake.follow())
          follow
        end

      {:ok, fetched} = Follows.many(context_id: followed.id)

      assert Enum.count(fetched) == Enum.count(follows)

      for follow <- fetched do
        assert follow.context
        assert follow.creator
      end
    end
  end

  describe "follow/3" do
    test "creates a follow for anything with an outbox", %{user: follower} do
      followed = fake_followable!()

      attrs = Fake.follow(%{is_public: true, is_muted: false})
      assert {:ok, follow} = Follows.create(follower, followed, attrs)

      assert follow.creator_id == follower.id
      assert follow.context_id == followed.id
      assert follow.published_at
      refute follow.muted_at
    end

    # test "can mute a follow", %{user: follower} do
    #   followed = fake_meta!()
    #   assert {:ok, follow} = Common.follow(follower, followed, Fake.follow(%{is_muted: true}))
    #   assert follow.muted_at
    # end

    test "fails to create a follow with missing attributes", %{user: follower} do
      followed = fake_followable!()
      assert {:error, _} = Follows.create(follower, followed, %{})
    end
  end

  describe "update_follow/2" do
    test "updates the attributes of an existing follow", %{user: follower} do
      followed = fake_followable!()
      assert {:ok, follow} =
        Follows.create(follower, followed, Fake.follow(%{is_public: false}))
      assert {:ok, updated_follow} =
        Follows.update(follow, Fake.follow(%{is_public: true}))
      assert follow != updated_follow
    end
  end

  describe "undo_follow/1" do
    test "removes a follower from a followed object", %{user: follower} do
      followed = fake_followable!()
      assert {:ok, follow} = Follows.create(follower, followed, Fake.follow())
      refute follow.deleted_at

      assert {:ok, follow} = Follows.undo(follow)
      assert follow.deleted_at
    end
  end

end
