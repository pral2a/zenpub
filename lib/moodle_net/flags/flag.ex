# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Flags.Flag do
  @moduledoc """
  A flag is a report that something is breaking the rules

  Flags participate in the meta system and must be created from a pointer
  """
  use MoodleNet.Common.Schema

  import MoodleNet.Common.Changeset, only: [change_synced_timestamp: 3]

  alias MoodleNet.Meta.Pointer
  alias MoodleNet.Communities.Community
  alias MoodleNet.Users.User
  alias Ecto.Changeset

  table_schema "mn_flag" do
    belongs_to(:creator, User)
    belongs_to(:context, Pointer)
    belongs_to(:community, Community)
    field(:canonical_url, :string)
    field(:message, :string)
    field(:is_local, :boolean)
    field(:is_resolved, :boolean, virtual: true)
    field(:resolved_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)
    timestamps()
  end

  @required ~w(message is_local)a
  @cast @required ++ ~w(canonical_url is_resolved)a

  def create_changeset(%User{id: creator_id}, community, %{id: context_id}, attrs) do
    %__MODULE__{}
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.change(creator_id: creator_id, context_id: context_id)
    |> Changeset.foreign_key_constraint(:creator_id)
    |> Changeset.foreign_key_constraint(:context_id)
    |> maybe_community(community)
    |> change_synced_timestamp(:is_resolved, :resolved_at)
  end

  defp maybe_community(changeset, nil), do: changeset
  defp maybe_community(changeset, %{id: id}) do
    changeset
    |> Changeset.put_change(:community_id, id)
    |> Changeset.foreign_key_constraint(:community_id)
  end

end
