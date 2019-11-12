# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Common.Tagging do
  use MoodleNet.Common.Schema

  meta_schema "mn_tag_category" do
    belongs_to(:tag, Tag)
    belongs_to(:tagger, User)
    belongs_to(:tagged, Pointer)
    field(:canonical_url, :string)
    field(:name, :string)
    field(:is_local, :boolean)
    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)
    timestamps(inserted_at: :created_at)
  end
end
