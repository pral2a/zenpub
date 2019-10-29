# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool.TaskModuleNotFoundError do
  @enforce_keys [:module]
  defstruct @enforce_keys

  @type t :: %__MODULE__{module: atom}

  @spec new(module :: atom) :: t
  @doc "Create a new TaskModuleNotFoundError"
  def new(module) when is_atom(module), do: %__MODULE__{module: module}

end
