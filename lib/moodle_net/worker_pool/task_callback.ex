defmodule MoodleNet.WorkerPool.TaskCallback do
  @moduledoc """
  The behaviour to implement for a background task
  """
  @callback init(map) :: {:ok, state :: term} \
                      |  {:ok, state :: term, new_timeout :: pos_integer} \
                      | {:error, term}
  @callback run(term, map) :: :ok | {:error, term}
end
