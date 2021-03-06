# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Common.Schema do
  @moduledoc "Macros for defining Ecto Schemas"

  @doc "Uses Ecto.Schema and imports the contents of this module"
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import MoodleNet.Common.Schema
    end
  end

  @doc """
  Creates a schema for a non-meta table:
  * ULID primary key, autogenerated
  * Foreign keys default to UUID
  * Timestamp columns default to microsecond resolution UTC
  """
  defmacro table_schema(table, body) do
    quote do
      @primary_key {:id, Ecto.ULID, autogenerate: true}
      @foreign_key_type Ecto.ULID
      @timestamps_opts [type: :utc_datetime_usec, inserted_at: false]
      schema(unquote(table), unquote(body))
    end
  end

  @doc """
  Creates a schema for a non-meta table:
  * UUIDv4 primary key, autogenerated
  * Foreign keys default to UUID
  * Timestamp columns default to microsecond resolution UTC
  """
  defmacro uuidv4_schema(table, body) do
    quote do
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type Ecto.ULID
      @timestamps_opts [type: :utc_datetime_usec, inserted_at: :created_at]
      schema(unquote(table), unquote(body))
    end
  end

  @doc """
  Declares a schema for a view:
  * No primary key
  * Foreign keys default to UUID
  * Timestamp columns default to microsecond resolution UTC
  """
  defmacro view_schema(view, body) do
    quote do
      @primary_key false
      @foreign_key_type Ecto.ULID
      schema(unquote(view), unquote(body))
    end
  end

end
