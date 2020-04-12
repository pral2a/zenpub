# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.FollowsSchema do

  use Absinthe.Schema.Notation
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Communities.Community
  alias MoodleNet.Threads.Thread
  alias MoodleNet.Users.User
  alias MoodleNetWeb.GraphQL.{CommonResolver, FollowsResolver, UsersResolver}

  object :follows_queries do

    @desc "Retrieves a follow by id"
    field :follow, :follow do
      arg :follow_id, non_null(:string)
      resolve &FollowsResolver.follow/2
    end

  end

  object :follows_mutations do

    @desc "Follow a community, collection or thread returning the follow"
    field :create_follow, :follow do
      arg :context_id, non_null(:string)
      resolve &FollowsResolver.create_follow/2
    end

    @desc "Follow a community, collection or a user by their canonical url returning the follow"
    field :create_follow_by_url, :follow do
      arg :url, non_null(:string)
      resolve &FollowsResolver.follow_remote_actor/2
    end

  end

  @desc "A record that a user follows something"
  object :follow do
    @desc "An instance-local UUID identifying the user"
    field :id, non_null(:string)
    @desc "A url for the flag, may be to a remote instance"
    field :canonical_url, :string

    @desc "Whether the follow is local to the instance"
    field :is_local, non_null(:boolean)
    @desc "Whether the follow is public"
    field :is_public, non_null(:boolean) do
      resolve &CommonResolver.is_public_edge/3
    end

    @desc "When the follow was created"
    field :created_at, non_null(:string) do
      resolve &CommonResolver.created_at_edge/3
    end
    @desc "When the follow was last updated"
    field :updated_at, non_null(:string)

    @desc "The user who followed"
    field :creator, :user do
      resolve &UsersResolver.creator_edge/3
    end

    @desc "The thing that is being followed"
    field :context, non_null(:follow_context) do
      resolve &CommonResolver.context_edge/3
    end
  end

  union :follow_context do
    description "A thing that can be followed"
    types [:collection, :community, :thread, :user]
    resolve_type fn
      %Collection{}, _ -> :collection
      %Community{},  _ -> :community
      %Thread{},     _ -> :thread
      %User{},       _ -> :user
    end
  end

  object :follows_page do
    field :page_info, non_null(:page_info)
    field :edges, non_null(list_of(non_null(:follow)))
    field :total_count, non_null(:integer)
  end

end
