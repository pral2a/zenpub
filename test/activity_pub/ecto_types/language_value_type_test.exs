# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.LanguageValueTypeTest do
  use MoodleNet.DataCase, async: true

  alias ActivityPub.LanguageValueType, as: Subject
  describe "cast" do
    test "works without extra param" do
      assert :error == Subject.cast([])
      assert :error == Subject.cast(true)
      assert {:ok, %{}} == Subject.cast(nil)
      assert {:ok, %{"und" => "linux"}} == Subject.cast("linux")
      assert {:ok, %{"und" => ""}} == Subject.cast("")
      assert {:ok, %{"linux" => "bsd"}} == Subject.cast(%{"linux" => "bsd"})
    end

    test "works with extra param" do
      assert :error == Subject.cast([], "en")
      assert :error == Subject.cast(true, "en")
      assert {:ok, %{}} == Subject.cast(nil, "en")
      assert {:ok, %{"en" => "linux"}} == Subject.cast("linux", "en")
      assert {:ok, %{"en" => ""}} == Subject.cast("", "en")
      assert {:ok, %{"linux" => "bsd"}} == Subject.cast(%{"linux" => "bsd"}, "en")
    end
  end
end