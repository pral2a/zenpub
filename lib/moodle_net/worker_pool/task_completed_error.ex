# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool.TaskCompletedError do
  @enforce_keys [:task]
  defstruct @enforce_keys

  alias MoodleNet.WorkerPool.Task

  @type t :: %__MODULE__{task: %Task{}}

  @spec new(task :: %Task{}) :: t
  @doc "Create a new TaskCompletedError"
  def new(%Task{}=task), do: %__MODULE__{task: task}

end
