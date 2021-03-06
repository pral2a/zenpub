# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.AdminResolver do
  
  def admin(_, _info), do: {:ok, %{}}

  def resolve_flag(%{flag_id: _id}, _info) do
    {:ok, nil}
  end

end
