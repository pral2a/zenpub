defmodule MoodleNet.WorkerPool.TaskSupervisor do

  use GenServer
  alias MoodleNet.Common.Time

  alias MoodleNet.WorkerPool.TaskService
  alias Timex.Duration

  @store_name __MODULE__.Store
  def start_link(_), do: GenServer.start_link(TaskService, {%{},%{}})

  
  # def start_task()

  # def lock(key, duration) do
  #   ttl = Duration.to_milliseconds(duration)
  #   Cachex.put(TaskService, key, true, ttl: ttl)
  # end

  # defp lock_timer(key, duration) do
  #   millis = Time.
  #   Process.send_after self(), {:timeout, key}, 
  # end

  # def unlock(key), do: Cachex.del(TaskService, key)

  # def init(_) do
  #   {:ok, {%{}, %{}}, {:continue, []}}
  # end

  # def handle_continue(_, state) do
  #   Process.flag(:trap_exit, true)
  # end
  

end
