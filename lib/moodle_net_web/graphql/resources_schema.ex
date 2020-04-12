# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.ResourcesSchema do
  @moduledoc """
  GraphQL resource fields, associations, queries and mutations.
  """
  use Absinthe.Schema.Notation

  alias MoodleNetWeb.GraphQL.{
    CommonResolver,
    FlagsResolver,
    LikesResolver,
    ResourcesResolver,
    UsersResolver,
    UploadResolver,
  }

  object :resources_queries do

    @desc "Get a resource"
    field :resource, :resource do
      arg :resource_id, non_null(:string)
      resolve &ResourcesResolver.resource/2
    end

  end

  object :resources_mutations do

    @desc "Create a resource"
    field :create_resource, :resource do
      arg :collection_id, non_null(:string)
      arg :resource, non_null(:resource_input)
      resolve &ResourcesResolver.create_resource/2
    end

    @desc "Update a resource"
    field :update_resource, :resource do
      arg :resource_id, non_null(:string)
      arg :resource, non_null(:resource_input)
      resolve &ResourcesResolver.update_resource/2
    end

    @desc "Copy a resource"
    field :copy_resource, :resource do
      arg :resource_id, non_null(:string)
      arg :collection_id, non_null(:string)
      resolve &ResourcesResolver.copy_resource/2
    end

  end

  object :resource do
    @desc "An instance-local UUID identifying the user"
    field :id, non_null(:string)
    @desc "A url for the user, may be to a remote instance"
    field :canonical_url, :string

    @desc "A name field"
    field :name, non_null(:string)

    @desc "Possibly biographical information"
    field :summary, :string

    @desc "An avatar url"
    field :icon, :content do
      resolve &UploadResolver.icon_content_edge/3
    end

    @desc "A link to an external resource"
    field :content, :content do
      resolve &UploadResolver.resource_content_edge/3
    end

    @desc "What license is it available under?"
    field :license, :string

    @desc "The original author"
    field :author, :string

    # TODO: add these 3 fields to DB:

    # @desc "The file type"
    # field :mime_type, :string

    # @desc "The type of content that may be embeded"
    # field :embed_type, :string

    # @desc "The HTML code of content that may be embeded"
    # field :embed_code, :string

    # No longer or not yet in use:
    # @desc "approx reading time in minutes"
    # field :time_required, :integer
    # @desc "free text"
    # field :typical_age_range, :string
    # @desc "??? Something about link aliasing"
    # field :same_as, :string
    # @desc "Can you use this without an institutional email or such"
    # field :public_access, :boolean
    # @desc "Can you use it without paying?"
    # field :free_access, :boolean
    # @desc "???"
    # field :learning_resource_type, :string
    # @desc "???"
    # field :educational_use, list_of(non_null(:string))

    @desc "Whether the resource is local to the instance"
    field :is_local, non_null(:boolean) do
      resolve &ResourcesResolver.is_local_edge/3
    end
    @desc "Whether the resource is public"
    field :is_public, non_null(:boolean) do
      resolve &CommonResolver.is_public_edge/3
    end
    @desc "Whether an instance admin has hidden the resource"
    field :is_disabled, non_null(:boolean) do
      resolve &CommonResolver.is_disabled_edge/3
    end

    @desc "When the resource was created"
    field :created_at, non_null(:string) do
      resolve &CommonResolver.created_at_edge/3
    end
    @desc "When the resource was last updated"
    field :updated_at, non_null(:string)

    # @desc """
    # When the resource was last updated or a thread or a comment on it
    # was created or updated
    # """
    # field :last_activity, non_null(:string) do
    #   resolve &ResourcesResolver.last_activity/3
    # end

    @desc "The current user's like of the resource, if any"
    field :my_like, :like do
      resolve &LikesResolver.my_like_edge/3
    end

    @desc "The current user's flag of the resource, if any"
    field :my_flag, :flag do
      resolve &FlagsResolver.my_flag_edge/3
    end

    @desc "The user who created the resource"
    field :creator, :user do
      resolve &UsersResolver.creator_edge/3
    end

    @desc "The collection this resource is a part of"
    field :collection, :collection do
      resolve &ResourcesResolver.collection_edge/3
    end

    # @desc "Languages the resources is available in"
    # field :primary_language, :language do
    #   resolve &LocalisationResolver.primary_language/3
    # end

    @desc "Total number of likers, including those we can't see"
    field :liker_count, :integer do
      resolve &LikesResolver.liker_count_edge/3
    end

    @desc "Users who like the resource, most recently liked first"
    field :likers, :likes_page do
      arg :limit, :integer
      arg :before, list_of(non_null(:cursor))
      arg :after, list_of(non_null(:cursor))
      resolve &LikesResolver.likers_edge/3
    end

    @desc "Flags users have made about the resource, most recently created first"
    field :flags, :flags_page do
      arg :limit, :integer
      arg :before, list_of(non_null(:cursor))
      arg :after, list_of(non_null(:cursor))
      resolve &FlagsResolver.flags_edge/3
    end

    # @desc "Tags users have applied to the resource, most recently created first"
    # field :tags, :taggings_page do
    #   arg :limit, :integer
    #   arg :before, list_of(non_null(:cursor))
    #   arg :after, list_of(non_null(:cursor))
    #   resolve &CommonResolver.tags_edge/3
    # end

  end

  input_object :resource_input do
    field :name, non_null(:string)
    field :summary, :string
    field :license, :string
    # field :primary_language_id, :string
    field :author, :string
  end

  object :resources_page do
    field :page_info, non_null(:page_info)
    field :edges, non_null(list_of(non_null(:resource)))
    field :total_count, non_null(:integer)
  end

end
