# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.Publisher do
  alias ActivityPub.Actor
  alias ActivityPub.HTTP
  alias ActivityPub.Instances
  alias ActivityPubWeb.Transmogrifier

  require Logger

  @behaviour ActivityPubWeb.Federator.Publisher

  @public_uri "https://www.w3.org/ns/activitystreams#Public"

  def is_representable?(_activity), do: true

  @doc """
  Publish a single message to a peer.  Takes a struct with the following
  parameters set:

  * `inbox`: the inbox to publish to
  * `json`: the JSON message body representing the ActivityPub message
  * `actor`: the actor which is signing the message
  * `id`: the ActivityStreams URI of the message
  """
  def publish_one(%{inbox: inbox, json: json, actor: %Actor{} = actor, id: id} = params) do
    Logger.info("Federating #{id} to #{inbox}")
    host = URI.parse(inbox).host

    digest = "SHA-256=" <> (:crypto.hash(:sha256, json) |> Base.encode64())

    date =
      NaiveDateTime.utc_now()
      |> Timex.format!("{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} GMT")

    signature =
      ActivityPub.Signature.sign(actor, %{
        host: host,
        "content-length": byte_size(json),
        digest: digest,
        date: date
      })

    with {:ok, %{status: code}} when code in 200..299 <-
           result =
             HTTP.post(
               inbox,
               json,
               [
                 {"Content-Type", "application/activity+json"},
                 {"Date", date},
                 {"signature", signature},
                 {"digest", digest}
               ]
             ) do
      if !Map.has_key?(params, :unreachable_since) || params[:unreachable_since],
        do: Instances.set_reachable(inbox)

      result
    else
      {_post_result, response} ->
        unless params[:unreachable_since], do: Instances.set_unreachable(inbox)
        {:error, response}
    end
  end

  def publish_one(%{actor_username: username} = params) do
    {:ok, actor} = Actor.get_cached_by_username(username)

    params
    |> Map.delete(:actor_username)
    |> Map.put(:actor, actor)
    |> publish_one()
  end

  defp recipients(actor, activity) do
    {:ok, followers} =
      if actor.data["followers"] in ((activity.data["to"] || []) ++ (activity.data["cc"] || [])) do
        Actor.get_external_followers(actor)
      else
        {:ok, []}
      end

    Actor.remote_users(actor, activity) ++ followers
  end

  defp maybe_use_sharedinbox(%{data: data}),
    do: (is_map(data["endpoints"]) && Map.get(data["endpoints"], "sharedInbox")) || data["inbox"]

  defp maybe_federate_to_mothership(recipients, activity) do
    if System.get_env("CONNECT_WITH_MOTHERSHIP", "false") == "true" and activity.public do
      recipients ++ [System.get_env("MOTHERSHIP_AP_INBOX_URL", "https://mothership.moodle.net/pub/shared_inbox" )]
    else
      recipients
    end
  end

  @doc """
  Determine a user inbox to use based on heuristics.  These heuristics
  are based on an approximation of the ``sharedInbox`` rules in the
  [ActivityPub specification][ap-sharedinbox].

  Please do not edit this function (or its children) without reading
  the spec, as editing the code is likely to introduce some breakage
  without some familiarity.

     [ap-sharedinbox]: https://www.w3.org/TR/activitypub/#shared-inbox-delivery
  """
  def determine_inbox(
        %{data: activity_data},
        %{data: %{"inbox" => inbox}} = user
      ) do
    to = activity_data["to"] || []
    cc = activity_data["cc"] || []
    type = activity_data["type"]

    cond do
      type == "Delete" ->
        maybe_use_sharedinbox(user)

      @public_uri in to || @public_uri in cc ->
        maybe_use_sharedinbox(user)

      length(to) + length(cc) > 1 ->
        maybe_use_sharedinbox(user)

      true ->
        inbox
    end
  end

  def publish(actor, activity) do
    {:ok, data} = Transmogrifier.prepare_outgoing(activity.data)
    json = Jason.encode!(data)
    #ActivityPub.maybe_forward_activity(activity)

    recipients(actor, activity)
    |> Enum.map(fn actor ->
      determine_inbox(activity, actor)
    end)
    |> Enum.uniq()
    |> maybe_federate_to_mothership(activity)
    |> Instances.filter_reachable()
    |> Enum.each(fn {inbox, unreachable_since} ->
    ActivityPubWeb.Federator.Publisher.enqueue_one(__MODULE__, %{
      inbox: inbox,
      json: json,
      actor_username: actor.username,
      id: activity.data["id"],
      unreachable_since: unreachable_since
    })
    end)
  end

  def gather_webfinger_links(actor) do
    [
      %{"rel" => "self", "type" => "application/activity+json", "href" => actor.data["id"]},
      %{
        "rel" => "self",
        "type" => "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\"",
        "href" => actor.data["id"]
      }
    ]
  end
end
