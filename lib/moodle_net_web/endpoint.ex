# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNetWeb.Endpoint do
  @moduledoc """
  MoodleNet Phoenix Endpoint
  """
  use Phoenix.Endpoint, otp_app: :moodle_net

  if is_binary(System.get_env("SENTRY_DSN")) and is_binary(System.get_env("SENTRY_ENV")) do
    use Sentry.Phoenix.Endpoint
  end

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(MoodleNetWeb.Plugs.Static)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason,
    length: 10_000_000,
    body_reader: {MoodleNetWeb.Plugs.DigestPlug, :read_body, []}
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(
    Plug.Session,
    store: :cookie,
    key: "_moodle_net_key",
    signing_salt: "CqAoopA2"
  )

  plug(CORSPlug)
  plug(MoodleNetWeb.Router)

  @doc """
  Dynamically loads configuration from the system environment on startup.

  It receives the endpoint configuration from the config files and must return the updated configuration.
  """
  def load_from_system_env(config) do
    port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
    {:ok, Keyword.put(config, :http, [:inet6, port: port])}
  end
end
