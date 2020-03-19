# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.NodeinfoController do
  use ActivityPubWeb, :controller

  alias MoodleNet.Config

  def schemas(conn, _params) do
    response = %{
      links: [
        %{
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
          href: MoodleNetWeb.base_url() <> "/.well-known/nodeinfo/2.0"
        },
        %{
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
          href: MoodleNetWeb.base_url() <> "/.well-known/nodeinfo/2.1"
        }
      ]
    }

    json(conn, response)
  end

  def raw_nodeinfo do
    %{
      version: "2.0",
      software: %{
        name: Mix.Project.config()[:name],
        version: Mix.Project.config()[:version]
      },
      protocols: ["ActivityPub"],
      services: %{
        inbound: [],
        outbound: []
      },
      openRegistrations: Config.get([MoodleNet.Users, :public_registration]),
      usage: %{},
      metadata: %{
        nodeName: Config.get([:instance, :name]),
        nodeDescription: Config.get([:instance, :description]),
        federation: Config.get([:instance, :federating])
      }
    }
  end

  def nodeinfo(conn, %{"version" => "2.0"}) do
    conn
    |> put_resp_header(
      "content-type",
      "application/json; profile=http://nodeinfo.diaspora.software/ns/schema/2.0#; charset=utf-8"
    )
    |> json(raw_nodeinfo())
  end

  def nodeinfo(conn, %{"version" => "2.1"}) do
    raw_response = raw_nodeinfo()

    updated_software =
      raw_response
      |> Map.get(:software)
      |> Map.put(:repository, Mix.Project.config()[:source_url])

    response =
      raw_response
      |> Map.put(:software, updated_software)
      |> Map.put(:version, "2.1")

    conn
    |> put_resp_header(
      "content-type",
      "application/json; profile=http://nodeinfo.diaspora.software/ns/schema/2.1#; charset=utf-8"
    )
    |> json(response)
  end

  def nodeinfo(conn, _) do
    json(conn, %{"error" => "Nodeinfo schema version not handled"})
  end
end
