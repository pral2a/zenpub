# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Common.Schema do

  @moduledoc "Macros for defining Ecto Schemas"

  @doc "Uses Ecto.Schema and imports the contents of this module"
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      require MoodleNet.Common.Schema
      import MoodleNet.Common.Schema
    end
  end

  @doc """
  Creates a schema for a non-meta table:
  * UUID primary key, autogenerated
  * Foreign keys default to UUID
  * Timestamp columns default to microsecond resolution UTC
  """
  defmacro standalone_schema(table, body) do
    quote do
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
      schema(unquote(table), unquote(body))
    end
  end

  @doc """
  Declares a schema for a meta table:
  * UUID primary key, not autogenerated
  * Foreign keys default to UUID
  * Timestamp columns default to microsecond resolution UTC
  """
  defmacro meta_schema(table, body) do
    quote do
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
      schema(unquote(table), unquote(body))
    end
  end

end