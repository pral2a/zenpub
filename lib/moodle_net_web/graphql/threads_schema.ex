# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.ThreadsSchema do
  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.{
    CommentsResolver,
    CommonResolver,
    FollowsResolver,
    ThreadsResolver,
  }
  alias MoodleNet.Communities.Community
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Flags.Flag
  alias MoodleNet.Resources.Resource

  object :threads_queries do

    @desc "Get a thread"
    field :thread, :thread do
      arg :thread_id, non_null(:string)
      resolve &ThreadsResolver.thread/2
    end

  end

  object :threads_mutations do

    @desc "Create a new thread"
    field :create_thread, :comment do
      arg :context_id, non_null(:string)
      arg :comment, non_null(:comment_input)
      resolve &ThreadsResolver.create_thread/2
    end

  end

  @desc "A thread is essentially a list of comments"
  object :thread do
    @desc "An instance-local UUID identifying the thread"
    field :id, non_null(:string)
    @desc "A url for the user, may be to a remote instance"
    field :canonical_url, :string

    @desc "Whether the thread is local to the instance"
    field :is_local, non_null(:boolean)
    @desc "Whether the thread is publically visible"
    field :is_public, non_null(:boolean) do
      resolve &CommonResolver.is_public_edge/3
    end
    @desc "Whether an instance admin has hidden the thread"
    field :is_hidden, non_null(:boolean) do
      resolve &CommonResolver.is_hidden_edge/3
    end

    @desc "When the thread was created"
    field :created_at, non_null(:string) do
      resolve &CommonResolver.created_at_edge/3
    end
    @desc "When the thread was last updated"
    field :updated_at, non_null(:string)
    @desc "The last time the thread or a comment on it was created or updated"
    field :last_activity, non_null(:string) do
      resolve &ThreadsResolver.last_activity_edge/3
    end

    @desc "The current user's follow of the community, if any"
    field :my_follow, :follow do
      resolve &FollowsResolver.my_follow_edge/3
    end

    @desc "The object the thread is attached to"
    field :context, :thread_context do
      resolve &CommonResolver.context_edge/3
    end

    @desc "Comments in the thread, most recently created first"
    field :comments, :comments_page do
      arg :limit, :integer
      arg :before, list_of(non_null(:cursor))
      arg :after,  list_of(non_null(:cursor))
      resolve &CommentsResolver.comments_edge/3
    end

    @desc "Total number of followers, including those we can't see"
    field :follower_count, :integer do
      resolve &FollowsResolver.follower_count_edge/3
    end

    @desc "Users following the collection, most recently followed first"
    field :followers, :follows_page do
      arg :limit, :integer
      arg :before, list_of(non_null(:cursor))
      arg :after,  list_of(non_null(:cursor))
      resolve &FollowsResolver.followers_edge/3
    end

  end
    
  union :thread_context do
    description "The thing the comment is about"
    types [:collection, :community, :flag, :resource]
    resolve_type fn
      %Collection{}, _ -> :collection
      %Community{},  _ -> :community
      %Flag{},       _ -> :flag
      %Resource{},   _ -> :resource
    end
  end

  object :threads_page do
    field :page_info, non_null(:page_info)
    field :edges, non_null(list_of(non_null(:thread)))
    field :total_count, non_null(:integer)
  end

end
