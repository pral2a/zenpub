# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

# For the moment we don't need an endpoint for APWeb
# But I'll keep it for a while just in case
#defmodule ActivityPubWeb.Endpoint do
#  use Phoenix.Endpoint, otp_app: :activity_pub

#  socket "/socket", ActivityPubWeb.UserSocket,
#    websocket: true,
#    longpoll: false

#  # Serve at "/" the static files from "priv/static" directory.
#  #
#  # You should set gzip to true if you are running phx.digest
#  # when deploying your static files in production.
#  plug Plug.Static,
#    at: "/",
#    from: :activity_pub,
#    gzip: false,
#    only: ~w(css fonts images js favicon.ico robots.txt)

#  # Code reloading can be explicitly enabled under the
#  # :code_reloader configuration of your endpoint.
#  if code_reloading? do
#    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
#    plug Phoenix.LiveReloader
#    plug Phoenix.CodeReloader
#  end

#  plug Plug.RequestId
#  plug Plug.Logger

#  plug Plug.Parsers,
#    parsers: [:urlencoded, :multipart, :json],
#    pass: ["*/*"],
#    json_decoder: Phoenix.json_library()

#  plug Plug.MethodOverride
#  plug Plug.Head

#  # The session will be stored in the cookie and signed,
#  # this means its contents can be read but not tampered with.
#  # Set :encryption_salt if you would also like to encrypt it.
#  plug Plug.Session,
#    store: :cookie,
#    key: "_activity_pub_key",
#    signing_salt: "i4A5AOWF"

#  plug ActivityPubWeb.Router
#end
