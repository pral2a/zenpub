# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Meta.Table do
  @moduledoc """
  A Table represents a database table participating in the meta
  system. It allows new tables to be dynamically added to the system
  during migrations.

  DO NOT INSERT OR DELETE OUTSIDE OF MIGRATIONS. That is why there are
  no changeset functions in here!
  """

  use MoodleNet.Common.Schema

  @type t :: %__MODULE__{}

  table_schema "mn_table" do
    field :table, :string
    field :schema, :any, virtual: true
  end
end
