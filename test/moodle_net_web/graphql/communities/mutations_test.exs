# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.Communities.MutationsTest do
  use MoodleNetWeb.ConnCase, async: true
  alias MoodleNet.Test.Fake
  import MoodleNetWeb.Test.GraphQLAssertions
  import MoodleNetWeb.Test.GraphQLFields
  import MoodleNet.Test.Faking

  describe "create_community" do

    test "works for a user or instance admin" do
      alice = fake_user!()
      lucy = fake_user!(%{is_instance_admin: true})
      q = create_community_mutation()
      for conn <- [user_conn(alice), user_conn(lucy)] do
        ci = Fake.community_input()
        comm = grumble_post_key(q, conn, :create_community, %{community: ci})
        assert_community(ci, comm)
      end
    end

    test "does not work for a guest" do
      ci = Fake.community_input()
      q = create_community_mutation()
      assert err = grumble_post_errors(q, json_conn(), %{community: ci})
    end

  end

  describe "update_community" do

    test "works for the community owner or admin" do
      alice = fake_user!()
      lucy = fake_admin!()
      comm = fake_community!(alice)
      conns = [user_conn(alice), user_conn(lucy)]
      q = update_community_mutation()
      for conn <- conns do
        ci = Fake.community_update_input()
        vars = %{community: ci, community_id: comm.id}
        comm = grumble_post_key(q, conn, :update_community, vars)
        assert_community(ci, comm)
      end
    end

    test "does not work for a random or a guest" do
      [alice, bob] = some_fake_users!(2)
      comm = fake_community!(alice)
      for conn <- [user_conn(bob), json_conn()] do
        ci = Fake.community_update_input()
        vars = %{community: ci, community_id: comm.id}
        q = update_community_mutation()
        grumble_post_errors(q, conn, vars)
      end
    end

  end
  

end
