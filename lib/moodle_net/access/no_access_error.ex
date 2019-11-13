# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Access.NoAccessError do
  @enforce_keys []
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  @doc "Create a new TokenExpiredError with the given token"
  @spec new() :: t
  def new(), do: %__MODULE__{}
end