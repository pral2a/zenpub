# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SQL.Associations.ManyToMany do
  @moduledoc """
  Defines the struct with the properties for an ActivityPub.SQL association using a "join" table
  """
  @enforce_keys [:sql_aspect, :aspect, :name]
  defstruct sql_aspect: nil,
    aspect: nil,
    name: nil,
    type: :any,
    autogenerated: nil,
    table_name: nil,
    join_keys: nil
end
