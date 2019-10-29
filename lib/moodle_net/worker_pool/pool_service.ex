# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool.PoolService do

  require Logger
  use Supervisor
  alias MoodleNet.WorkerPool
  alias MoodleNet.Common.NotFoundError
  alias MoodleNet.WorkerPool.{
    LockService,
    PoolService,
    Task,
    TaskModuleNotFoundError,
    TaskCompletedError,
    TaskFailedError,
    TaskLockedError,
  }

  # API
  @config_key   __MODULE__
  @service_name __MODULE__
  @pool_name    WorkerPool.Pool
  @worker_name  WorkerPool.TaskRunner
  @sup_name     WorkerPool.Supervisor

  def start_link(opts),
    do: Supervisor.start_link(__MODULE__, opts, name: @service_name)

  def submit(%Task{}=task) do
    options = []
    spawn(fn ->
      :poolboy.transaction(@pool_name, kick_off_task(task), 600000)
    end) # ten minutes
  end

  # Callbacks

  def init(_opts) do
    poolboy_config = [
      name: {:local, @pool_name},
      worker_module: @worker_name,
      size: get_pool_size(),
      max_overflow: 0
      # {:strategy, :fifo} # fairer, mildly slower, we don't much care
    ]
    child = :poolboy.child_spec(@pool_name, poolboy_config, [])
    supervise([child], strategy: :one_for_one, name: @sup_name)
  end    


  defp get_pool_size() do
    Application.get_env(:moodle_net, @config_key)
    |> Keyword.get(:concurrent_tasks, 1)
  end

  defp kick_off_task(task) do
    fn (pid) ->
      # notify(:started, task_id)
      # Tasks.run_task(task)
    end
  end

  defp begin_task(%Task{}=task) do
    if is_loaded?(task),
      do: begin_db_task(task),
      else: begin_local_task(task)
  end

  defp begin_db_task(%Task{}=task) do
    with {:ok, task} <- record_attempt(task), do: run_db_task(task)
  end

  defp begin_local_task(%Task{}=_task) do
  end

  def run_db_task(task) do
    # try do run_task(task)
    # catch  e -> task_threw(task, error)
    # rescue e -> task_threw(task, error)
    # else
    #   :ok -> task_succeeded(task)
    #   {:error, e} -> task_failed(task, e)
    #   e -> task_failed(task, e)
    # end
  end


  defp task_succeeded(%Task{}=task) do
    case Repo.insert(Task.completed_changeset(task)) do
      {:ok, _task} -> succeeded_succeeding(task)
      {:error, error} -> failed_succeeding(task, error)
    end	
  end

  defp task_threw(task, error) do
    Logger.error """
    [MoodleNet.WorkerPool.PoolService] Task threw!
    Task:  #{inspect(task)}
    Error: #{inspect(error)}
    """
    record_failed(task, error)
  end

  defp task_failed(task, error) do
    Logger.error """
    [MoodleNet.WorkerPool.PoolService] Task failed!
    Task:  #{inspect(task)}
    Error: #{inspect(error)}
    """
    record_failed(task, error)
  end


  defp record_attempt(%Task{}=task),
    do: Repo.insert(Task.attempt_changeset(task))

  defp record_failed(%Task{ttl: ttl}=task, e) do
    if ttl < 2 do
      case Repo.update(Task.task_failed_changeset(task)) do
	{:ok, _task} -> :ok
	{:error, e} -> failed_failing_task(task, e)
      end
    else
      case Repo.update(Task.attempt_failed_changeset(task)) do
	{:ok, _task} -> :ok
	{:error, e} -> failed_failing_attempt(task, e)
      end
    end
  end
  
  @lock_time 15
  @lock_unit :second
  defp lock_in_db(%Task{id: id}=task) do
    Repo.transact_with fn ->
      with {:ok, task} <- Repo.fetch(Task, id),
           :ok <- check_task_startable(task),
           {:ok, task} <- Repo.update(Task.lock_for(task, @lock_time, :second)),
           {:ok, _} <- Cachex.put do
	{:ok, task}
      end
    end
  end

  defp check_task_startable(%Task{}=task) do
    cond do
      is_deleted?(task) -> {:error, NotFoundError.new(task.id)}
      is_failed?(task) -> {:error, TaskFailedError.new(task)}
      is_completed?(task) -> {:error, TaskCompletedError.new(task)}
      is_dead?(task) -> {:error, TaskFailedError.new(task)}
      is_locked?(task) -> {:error, TaskLockedError.new(task)}
      true -> :ok
    end
  end

  defp is_deleted?(%Task{deleted_at: time}), do: not is_nil(time)

  defp is_failed?(%Task{failed_at: time}), do: not is_nil(time)

  defp is_completed?(%Task{completed_at: time}), do: not is_nil(time)

  defp is_locked?(%Task{attempted_at: time}), do: not is_nil(time)

  defp is_dead?(%Task{ttl: ttl}), do: ttl < 1

  defp meta_state(%{__meta__: %{state: state}}), do: state
  defp meta_state(_), do: nil

  defp is_loaded?(%Task{}=task), do: :loaded == meta_state(task)

  # Mostly logging

  defp succeeded_succeeding(%Task{id: id}) do
    Logger.info """
    [MoodleNet.WorkerPool.PoolService] Task #{id} completed successfully.
    """
    :ok
  end

  defp failed_succeeding(%Task{id: id}, error) do
    Logger.error """
    [MoodleNet.WorkerPool.PoolService] Failed to mark task #{id} a success!
    """
    :ok
  end

  defp failed_failing_attempt(%Task{id: id}, error) do
    Logger.error """
    [MoodleNet.WorkerPool.PoolService] Failed to mark task #{id} attempt a failure.
    Error: #{inspect(error)}
    """
    :ok
  end

  defp failed_failing_task(%Task{id: id}, error) do
    Logger.error """
    [MoodleNet.WorkerPool.PoolService] Failed to mark task #{id} a failure.
    Error: #{inspect(error)}
    """
    :ok
  end

end
    
