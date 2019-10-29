# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.WorkerPool.Task do

  use MoodleNet.Common.Schema
  alias MoodleNet.WorkerPool.Task
  alias Ecto.UUID

  standalone_schema("mn_worker_task") do
    field :module, :any, virtual: true
    field :module_name, :string
    field :arg, :map
    field :metadata, :map, default: %{}
    field :ttl, :integer, default: 1
    field :attempts, :integer, default: 0
    field :attempted_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :deleted_at, :utc_datetime_usec
    timestamps()
  end

  import MoodleNet.Common.Changeset,
    only: [ validate_positive_integer: 3,
	    soft_delete_changeset: 3 ]

  @create_cast ~w(module arg metadata ttl)a
  @create_required ~w(module arg)
  def create_changeset(args) do
    %Task{}
    |> Ecto.cast(args, @create_cast)
    |> Changeset.validate_required(@create_required)
    |> Changeset.validate_module()
  end

  # There is an annoying tradeoff going on here. We don't want to
  # penalise tasks that get killed in the event of a node crash
  # (unikely, but never say never...), but the worse (and more likely)
  # outcome is that an attempt to commit an update to a task could
  # fail. We don't really have a good answer for that beyond a
  # periodic sweep, alas.
  def attempt_changeset(%Task{}=task) do
    task
    |> soft_delete_changeset(:attempted_at, "already attempted")
    |> Changeset.put_change(:ttl, task.ttl - 1)
    |> Changeset.put_change(:attempts, task.attempts + 1)
    |> validate_positive_integer(:ttl, "must have a positive ttl")
  end

  def attempt_failed_changeset(%Task{}=task) do
    task
    |> Changeset.cast(%{}, [])
    |> Changeset.put_change(:attempted_at, nil)
  end

  def task_failed_changeset(%Task{}=task) do
    task
    |> soft_delete_changeset(:failed_at, "already failed")
    |> Changeset.put_change(:ttl, task.ttl -1)
  end

  def task_completed_changeset(%Task{}=task),
    do: soft_delete_changeset(task, :completed_at, "already completed")

  # reconstitutes the module name from the stored value if necessary
  def inflate(%Task{module: nil, module_name: module_name} = task) do
    module = String.to_existing_atom(module_name)
    %{task | module: module}
  end
  def inflate(%Task{}=task), do: task

  def validate_module(changeset) do
    Changeset.validate_change changeset, :module, fn _, val ->
      if is_task_module_atom?(val),
        do: [],
        else: [module: "must be a valid task module"]
    end
  end

  defp is_task_module_atom?(val) when not is_atom(val), do: false
  defp is_task_module_atom?(val) do
    Code.ensure_loaded?(val) and
      Module.defines?(val, {:init, 1}) and
      Module.defines?(val, {:run, 1})
  end

end
