# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool do
  @moduledoc """
  The worker pool is responsible for performing tasks in the
  background. These could be triggered by user actions where we don't
  want to hold up a response until the task has completed, or they may
  be scheduled maintenance tasks.

  ## Task Structure

  A task is a module with 2 callback functions: `init/1` and `run/1`.
 
  * `init/1` - called to initialise the task. This will typically
    involve querying the database for enough information to determine
    the extent of the scope of the operation.
  * `run/1` - called to perform the work itself.

  As an optimisation, since you will often have to perform a similar
  query to the one you'd use in `init/1`, we have a mechanism for
  skipping the call to `init` and using a provided state object
  instead.

  Tasks:

  * Feed publishing
  * MN-ActivityPub bidirectional sync
  * Garbage collection (old content, soft deleted content etc.)
  * Automated backups
  
  Persistent task submission (in your non-worker code):

  1. Write a job record to the database in your own transaction
  2. If the transaction successfully commits, submit the job to
     avoid waiting for the poller to notice it in the database.

  Note that this introduces a race condition. There is a small
  probability (higher at shorter poll times) that the background
  polling task will notice the job in the database before it has been
  submitted to the worker pool. In such a case, we lose the ability to
  avoid calling init() and so we (probably) end up doing more work.
  """
  alias MoodleNet.WorkerPool.{PoolService, Task, TaskModuleNotFoundError}
  alias Ecto.Changeset
  
  @type not_found :: %TaskModuleNotFoundError{}

  @doc """
  Returns a Task representing the a call to the provided module and
  function with the provided arg.

  Will one day take an optional metadata argument, allowing for
  priorities, scheduling etc.
  """
  @spec task(module :: atom, function :: atom, arg :: map) :: {:ok, %Task{}} | {:error, not_found}
  def task(module, function, %{}=arg) when is_atom(module) and is_atom(function) do
    Task.new(module, function, arg)
    |> check_task_function_exists()
  end
  
  @doc """
  
  """
  @spec submit(%Task{}) :: {:ok, %Task{}}
  def submit(%Task{}=task) do
    with {:ok, _} <- check_task_function_exists(task),
      do: PoolService.submit(task)
  end

  defp check_task_function_exists(%Task{module: module}=task) do
    if Kernel.function_exported?(module, :run, 1),
      do: {:ok, task},
      else: {:error, TaskModuleNotFoundError.new(module)}
  end

  @spec fetch_task(id :: binary) :: {:ok, %Task{}} | {:error, Changeset.t}
  def fetch_task(id), do: Repo.fetch(Task, id)

end
