# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool.TaskQueue do
  @moduledoc """
  The queue places an ordering over the tasks
  """
  use GenServer
  alias MoodleNet.WorkerPool.Task
  
  def start_link(_) do
  end

  def enqueue(%Task{}=task) do
    
  end

  def enqueue_with_state(%Task{}=task, state) do
  end

  def dequeue() do
    
  end

end
  
