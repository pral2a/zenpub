# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
import Config

alias MoodleNet.{
  Blocks,
  Collections,
  Communities,
  Features,
  Flags,
  Follows,
  Instance,
  Likes,
  Threads,
  Users,
}
alias MoodleNet.Blocks.Block
alias MoodleNet.Collections.Collection
alias MoodleNet.Communities.Community
alias MoodleNet.Flags.Flag
alias MoodleNet.Likes.Like
alias MoodleNet.Resources.Resource
alias MoodleNet.Threads.{Comment, Thread}
alias MoodleNet.Users.User

# stuff you might need to change to be viable

config :moodle_net, app_name: "MoodleNet"

config :moodle_net, MoodleNetWeb.Gettext, default_locale: "en", locales: ~w(en es)

# stuff you might want to change for your use case

config :moodle_net, Feeds,
  valid_contexts: [Collection, Comment, Community, Resource, Like],
  default_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Blocks,
  valid_contexts: [Collection, Community, User]

config :moodle_net, Instance,
  hostname: "moodlenet.local",
  description: "Local development instance",
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Collections,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Communities,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Features,
  valid_contexts: [Collection, Community]

config :moodle_net, Flags,
  valid_contexts: [Collection, Comment, Community, Resource, User]

config :moodle_net, Follows,
  valid_contexts: [Collection, Community, Thread, User, Geolocation, Organisation]

config :moodle_net, Likes,
  valid_contexts: [Collection, Community, Comment, Resource, User]

config :moodle_net, Threads,
  valid_contexts: [Collection, Community, Flag, Resource, User]

config :moodle_net, Users,
  public_registration: false,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

 # before compilation, replace this with the email deliver service adapter you want to use: https://github.com/thoughtbot/bamboo#available-adapters
  # api_key: System.get_env("MAIL_KEY"), # use API key from runtime environment variable (make sure to set it on the server or CI config), and fallback to build-time env variable
  # domain: System.get_env("MAIL_DOMAIN"), # use sending domain from runtime env, and fallback to build-time env variable
config :moodle_net, MoodleNet.Mail.MailService,
  adapter: Bamboo.MailgunAdapter

config :moodle_net, :mrf_simple,
  media_removal: [],
  media_nsfw: [],
  report_removal: [],
  accept: [],
  avatar_removal: [],
  banner_removal: []

config :moodle_net, Oban,
  repo: MoodleNet.Repo,
  prune: {:maxlen, 100_000},
  queues: [
    federator_incoming: 50,
    federator_outgoing: 50,
    ap_incoming: 10,
    mn_ap_publish: 30,
  ]

config :moodle_net, :workers,
  retries: [
    federator_incoming: 5,
    federator_outgoing: 5
  ]

config :moodle_net, MoodleNet.MediaProxy,
  impl: MoodleNet.DirectHTTPMediaProxy,
  path: "/media/"

### Standin data for values you'll have to provide in the ENV in prod

config :moodle_net, MoodleNetWeb.Endpoint,
  url: [host: "localhost"],
  protocol: "https",
  secret_key_base: "aK4Abxf29xU9TTDKre9coZPUgevcVCFQJe/5xP/7Lt4BEif6idBIbjupVbOrbKxl",
  render_errors: [view: MoodleNetWeb.ErrorView, accepts: ["json", "activity+json"]],
  pubsub: [name: MoodleNet.PubSub, adapter: Phoenix.PubSub.PG2],
  secure_cookie_flag: true

version =
  with {version, 0} <- System.cmd("git", ["rev-parse", "HEAD"]) do
    "MoodleNet #{Mix.Project.config()[:version]} #{String.trim(version)}"
  else
    _ -> "MoodleNet #{Mix.Project.config()[:version]} dev"
  end

config :moodle_net, :instance,
  version: version,
  name: "MoodleNet",
  email: "moodlenet-moderators@moodle.com",
  description: "An instance of MoodleNet, a federated server for educators",
  federation_publisher_modules: [ActivityPubWeb.Publisher],
  federation_reachability_timeout_days: 7,
  federating: true,
  rewrite_policy: []

### Stuff you probably won't want to change

config :moodle_net, ecto_repos: [MoodleNet.Repo]

config :moodle_net, MoodleNet.Repo,
  migration_primary_key: [name: :id, type: :binary_id]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime, :types, %{
  "application/activity+json" => ["json"],
  "application/ld+json" => ["json"],
  "application/jrd+json" => ["json"]
}

config :argon2_elixir,
  argon2_type: 2 # argon2id, see https://hexdocs.pm/argon2_elixir/Argon2.Stats.html

# Configures http settings, upstream proxy etc.
config :moodle_net, :http,
  proxy_url: nil,
  send_user_agent: true,
  adapter: [
    ssl_options: [
      # Workaround for remote server certificate chain issues
      partial_chain: &:hackney_connect.partial_chain/1,
      # We don't support TLS v1.3 yet
      versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"]
    ]
  ]


config :phoenix, :format_encoders, json: Jason
config :phoenix, :json_library, Jason

config :furlex, Furlex.Oembed,
  oembed_host: "https://oembed.com"

config :tesla, adapter: Tesla.Adapter.Hackney

config :http_signatures, adapter: ActivityPub.Signature

config :moodle_net, ActivityPub.Adapter, adapter: MoodleNet.ActivityPub.Adapter

config :sentry,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
