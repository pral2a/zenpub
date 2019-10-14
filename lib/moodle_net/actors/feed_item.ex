# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Actors.FeedItem do
  use MoodleNet.Common.Schema
  alias Ecto.Changeset
  alias MoodleNet.Actors.Actor
  alias MoodleNet.Meta.Pointer

  standalone_schema "mn_actor_feed" do
    belongs_to :actor, Actor
    belongs_to :pointer, Pointer
    timestamps(updated_at: false)
  end

  @create_cast ~w()a
  @create_required @create_cast

  def create_changeset(actor = %Actor{}, pointer = %Pointer{}) do
    %__MODULE__{}
    |> Changeset.put_assoc(:actor, actor)
    |> Changeset.put_assoc(:pointer, pointer)
  end
end
