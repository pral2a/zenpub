# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.WebFingerTest do
  use MoodleNet.DataCase

  alias ActivityPub.WebFinger

  import Tesla.Mock

  setup do
    mock(fn env -> apply(HttpRequestMock, :request, [env]) end)
    :ok
  end

  describe "incoming webfinger request" do
    test "works for fqns" do
      actor = Factory.actor()

      {:ok, result} =
        WebFinger.webfinger("#{actor.preferred_username}@#{MoodleNetWeb.Endpoint.host()}")

      assert is_map(result)
    end

    test "works for ap_ids" do
      actor = Factory.actor()

      {:ok, result} = WebFinger.webfinger(actor.id)
      assert is_map(result)
    end
  end

  describe "fingering" do
    test "works with pleroma" do
      user = "karen@kawen.space"

      {:ok, data} = WebFinger.finger(user)

      assert data["id"] == "https://kawen.space/users/karen"
    end

    test "works with mastodon" do
      user = "karen@niu.moe"

      {:ok, data} = WebFinger.finger(user)

      assert data["id"] == "https://niu.moe/users/karen"
    end
  end
end
