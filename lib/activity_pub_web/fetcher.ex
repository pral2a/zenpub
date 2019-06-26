# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.Fetcher do
  @moduledoc """
  Handles fetching AS2 objects from remote instances.
  """

  alias MoodleNet.Repo
  alias ActivityPub.HTTP
  require Logger

  @doc """
  Checks if an object exists in the database and fetches it if it doesn't.

  Currently only returns a decoded JSON.
  TODO: normalise (in transmogrifier module?) and insert the object into database.
  """
  def fetch_object_from_id(id) do
    if entity = ActivityPub.get_by_id(id) do
      {:ok, entity}
    else
      with {:ok, data} <- fetch_remote_object_from_id(id) do
        {:ok, data}
      end
    end
  end

  @doc """
  Fetches an AS2 object from remote AP ID.
  """
  def fetch_remote_object_from_id(id) do
    Logger.info("Fetching object #{id} via AP")

    with true <- String.starts_with?(id, "http"),
         {:ok, %{body: body, status: code}} when code in 200..299 <-
           HTTP.get(
             id,
             [{:Accept, "application/activity+json"}]
           ),
         {:ok, data} <- Jason.decode(body) do
      {:ok, data}
    end
  end
end