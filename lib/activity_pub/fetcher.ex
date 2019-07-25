# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.Fetcher do
  @moduledoc """
  Handles fetching AS2 objects from remote instances.
  """

  alias ActivityPub.HTTP
  alias ActivityPub.Object
  alias ActivityPubWeb.Transmogrifier
  require Logger

  @doc """
  Checks if an object exists in the database and fetches it if it doesn't.
  """
  def fetch_object_from_id(id) do
    if object = Object.get_by_ap_id(id) do
      {:ok, object}
    else
      with {:ok, data} <- fetch_remote_object_from_id(id),
           {:ok, data} <- contain_origin(data),
           {:ok, object} <- Transmogrifier.handle_object(data),
           {:ok} <- check_if_public(object.public) do
        {:ok, object}
      else
        {:error, e} -> {:error, e}
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
         {:ok, data} <- Jason.decode(body),
         {:ok, data} <- contain_uri(id, data) do
      {:ok, data}
    else
      {:ok, %{status: code}} when code in [404, 410] ->
        {:error, "Object has been deleted"}

      {:error, e} ->
        {:error, e}

      e ->
        {:error, e}
    end
  end

  @actor_and_collection_types [
    "Person",
    ["Group", "MoodleNet:Community"],
    ["Group", "MoodleNet:Collection"],
    "Collection",
    "OrderedCollection",
    "CollectionPage",
    "OrderedCollectionPage"
  ]
  defp contain_origin(%{"id" => id} = data) do
    if data["type"] in @actor_and_collection_types do
      {:ok, data}
    else
      actor = get_actor(data)
      actor_uri = URI.parse(actor)
      id_uri = URI.parse(id)

      if id_uri.host == actor_uri.host do
        {:ok, data}
      else
        {:error, "Object containment error"}
      end
    end
  end

  defp get_actor(%{"actor" => nil, "attributedTo" => actor} = _data), do: actor

  defp get_actor(%{"actor" => actor} = _data), do: actor

  defp check_if_public(public) when public == true, do: {:ok}

  defp check_if_public(_public), do: {:error, "Not public"}

  defp contain_uri(id, %{"id" => json_id} = data) do
    id_uri = URI.parse(id)
    json_id_uri = URI.parse(json_id)

    if id_uri.host == json_id_uri.host do
      {:ok, data}
    else
      {:error, "URI containment error"}
    end
  end
end
