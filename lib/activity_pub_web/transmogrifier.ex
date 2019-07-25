# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.Transmogrifier do
  @moduledoc """
  This module normalises outgoing data to conform with AS2/AP specs
  and handles incoming objects and activities
  """

  alias ActivityPub.Entity
  alias ActivityPub.Object
  require ActivityPub.Guards, as: APG

  @doc """
  Translates MN Entity to an AP compatible format
  """
  def prepare_outgoing(entity) do
    entity
    |> Entity.aspects()
    |> Enum.flat_map(&filter_by_aspect(entity, &1))
    |> Enum.into(%{})
    |> set_type(entity.type)
    |> set_context()
    |> set_streams(entity)
    |> set_public()
    |> maybe_inject_object()
  end

  def prepare_embedded(entity) do
    entity
    |> Entity.aspects()
    |> Enum.flat_map(&filter_by_aspect_embedded(entity, &1))
    |> Enum.into(%{})
    |> Map.delete("likersCount")
    |> set_type(entity.type)
    |> maybe_put_id(entity)
  end

  defp filter_by_aspect(entity, aspect) do
    fields_name = filter_fields_by_definition(aspect)

    entity
    |> Map.take(fields_name)
    |> Enum.concat(Entity.assocs(entity))
    |> Enum.filter(&filter_by_value/1)
    |> normalize()
    |> common_fields(entity)
    |> custom_fields(entity, aspect)
  end

  defp filter_by_aspect_embedded(entity, aspect) do
    fields_name = filter_fields_by_definition(aspect)

    entity
    |> Map.take(fields_name)
    |> Enum.concat(Entity.assocs(entity))
    |> Enum.filter(&filter_by_value/1)
    |> normalize()
  end

  defp common_fields(ret, entity) do
    ret
    |> Map.put("id", entity.id)
    |> Map.put("type", entity.type)
    |> Map.put("@context", entity["@context"])
    |> Map.delete("likersCount")
  end

  defp maybe_put_id(%{"type" => "Image"} = ret, _entity), do: ret

  defp maybe_put_id(ret, entity), do: Map.put(ret, "id", entity.id)

  defp maybe_inject_object(%{"object" => object} = entity) when is_map(object) do
    object =
      object
      |> Map.put("@context", entity["@context"])
      |> Map.put("attributedTo", entity["actor"])
      |> Map.put("to", entity["to"])
      |> Map.put("cc", entity["cc"])

    entity
    |> Map.put("object", object)
  end

  defp maybe_inject_object(entity), do: entity

  defp custom_fields(ret, _entity, ActivityPub.ActorAspect) do
    ret
    |> add_endpoints()
  end

  defp custom_fields(ret, entity, _)
       when APG.has_type(entity, "CollectionPage")
       when APG.has_type(entity, "MoodleNet:Community")
       when APG.has_type(entity, "MoodleNet:Collection"),
       do: ret

  defp custom_fields(ret, entity, ActivityPub.CollectionAspect)
       when APG.has_type(entity, "CollectionPage"),
       do: ret

  defp custom_fields(ret, entity, ActivityPub.CollectionAspect) do
    ret
    |> Map.put("first", ActivityPub.CollectionPage.id(entity))

    # |> Map.delete("items")
  end

  defp custom_fields(ret, _, _), do: ret

  defp add_endpoints(ret) do
    endpoints = %{"sharedInbox" => ActivityPub.UrlBuilder.base_url() <> "/shared_inbox"}
    Map.put(ret, "endpoints", endpoints)
  end

  defp extension_fields(entity) do
    entity
    |> Entity.extension_fields()
    |> Enum.filter(&filter_by_value/1)
    |> Enum.map(&normalize_value/1)
  end

  # FIXME this can be calculated in compilation time :)
  defp filter_fields_by_definition(aspect) do
    aspect.__aspect__(:fields)
    |> Enum.map(&aspect.__aspect__(:field, &1))
    |> Enum.reduce([], fn
      %{name: :items}, acc -> [:items | acc]
      %{virtual: true}, acc -> acc
      %{name: name}, acc -> [name | acc]
    end)
  end

  defp filter_by_value({_, nil}), do: false
  defp filter_by_value({_, []}), do: false
  defp filter_by_value({_, map}) when map == %{}, do: false
  defp filter_by_value({_, %ActivityPub.SQL.FieldNotLoaded{}}), do: false
  defp filter_by_value({_, %ActivityPub.SQL.AssociationNotLoaded{}}), do: false
  defp filter_by_value(_), do: true

  defp normalize(entity) do
    entity
    |> Enum.map(&normalize_key_value/1)
    |> Enum.into(%{})
  end

  defp normalize_key_value({key, value}),
    do: {Recase.to_camel(to_string(key)), normalize_value(value)}

  defp normalize_value(%{"und" => value} = map) when map_size(map) == 1 and is_binary(value),
    do: normalize_value(value)

  defp normalize_value([value]), do: normalize_value(value)

  defp normalize_value(list) when is_list(list),
    do: Enum.map(list, &normalize_value/1)

  defp normalize_value(entity) when APG.is_entity(entity) do
    case entity.type do
      ["Object", "Collection"] -> entity.id
      ["Object", _] -> prepare_embedded(entity)
      _ -> entity.id
    end
  end

  defp normalize_value(value), do: value

  defp set_type(json, type), do: Map.put(json, "type", custom_type(type))

  defp custom_type(["Object", "Collection"]), do: "Collection"
  defp custom_type(["Object", "Collection", "CollectionPage"]), do: "CollectionPage"
  defp custom_type(["Object", object_type]), do: object_type
  defp custom_type(["Object", "Actor", "Person"]), do: "Person"
  defp custom_type(["Object", "Activity", activity_type]), do: activity_type

  defp custom_type(type) do
    cond do
      "MoodleNet:Community" in type -> ["Group", "MoodleNet:Community"]
      "MoodleNet:Collection" in type -> ["Group", "MoodleNet:Collection"]
      "MoodleNet:EducationalResource" in type -> ["Page", "MoodleNet:EducationalResource"]
      true -> type
    end
  end

  @context [
    "https://www.w3.org/ns/activitystreams",
    "https://w3id.org/security/v1",
    %{
      "MoodleNet" => "http://vocab.moodle.net/",
      "@language" => "en",
      "Emoji" => "toot:Emoji",
      "Hashtag" => "as:Hashtag",
      "PropertyValue" => "schema:PropertyValue",
      "manuallyApprovesFollowers" => "as:manuallyApprovesFollowers",
      "schema" => "http://schema.org",
      "toot" => "http://joinmastodon.org/ns#",
      "totalItems" => "as:totalItems",
      "value" => "schema:value",
      "sensitive" => "as:sensitive"
    }
  ]
  defp set_context(json),
    do: Map.put(json, "@context", @context)

  defp set_streams(json, entity) when APG.has_type(entity, "MoodleNet:Community") do
    {streams, json} = Map.split(json, ["collections", "subcommunities"])
    Map.put(json, "streams", streams)
  end

  defp set_streams(json, entity) when APG.has_type(entity, "MoodleNet:Collection") do
    {streams, json} = Map.split(json, ["resources", "subcollections"])
    Map.put(json, "streams", streams)
  end

  defp set_streams(json, _entity), do: json

  defp set_public(%{"public" => true} = json) do
    json
    |> Map.delete("public")
    |> add_public_address()
  end

  defp set_public(%{"public" => false} = json), do: Map.delete(json, "public")
  defp set_public(json), do: json

  @public_address "https://www.w3.org/ns/activitystreams#Public"
  defp add_public_address(%{"to" => value} = json) when is_binary(value),
    do: Map.put(json, "to", [value, @public_address])

  defp add_public_address(%{"to" => list} = json) when is_list(list),
    do: Map.put(json, "to", [@public_address | list])

  defp add_public_address(json), do: Map.put(json, "to", @public_address)

  @doc """
  Normalises and inserts an incoming AS2 object. Returns Object.
  """

  @collection_types ["Collection", "OrderedCollection", "CollectionPage", "OrderedCollectionPage"]
  def handle_object(%{"type" => type} = data) when type in @collection_types do
    with {:ok, object} <- prepare_data(data) do
      {:ok, object}
    else
      {:error, e} -> {:error, e}
    end
  end

  def handle_object(data) do
    with {:ok, object} <- prepare_data(data),
         {:ok, object} <- Object.insert(object) do
      {:ok, object}
    else
      {:error, e} -> {:error, e}
    end
  end

  defp prepare_data(data) do
    data =
      %{}
      |> Map.put(:data, data)
      |> Map.put(:local, false)
      |> Map.put(:public, public?(data))

    {:ok, data}
  end

  defp public?(data) do
    recipients = (data["to"] || []) ++ (data["cc"] || [])

    cond do
      recipients == [] ->
        true

      Enum.member?(recipients, "https://www.w3.org/ns/activitystreams#Public") ->
        true

      true ->
        false
    end
  end
end
