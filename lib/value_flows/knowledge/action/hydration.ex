defmodule ValueFlows.Knowledge.Action.Hydration do

  alias MoodleNetWeb.GraphQL.{
    ActorsResolver
  }

  def hydrate(blueprint) do
    %{
      # spatial_thing: %{
      #   canonical_url: [
      #     resolve: &ActorsResolver.canonical_url_edge/3
      #   ],
      #   display_username: [
      #     resolve: &ActorsResolver.display_username_edge/3
      #   ],
      #   in_scope_of: [
      #     resolve: &Geolocation.GraphQL.community_edge/3
      #   ],
      # },
      action_query: %{
        action: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.action/2
        ],
        all_actions: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.all_actions/3
        ]
      },
      action_mutation: %{
        create_intent: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.create_action/2
        ]
      }
    }
  end

end
