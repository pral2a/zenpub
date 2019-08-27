# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Factory do
  @moduledoc """
  Factory to build entities
  """

  defp username(name) do
    name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]/, "")
    size = byte_size(name)
    cond do
      size > 16 -> String.slice(name, 0, 16)
      size < 3 -> name <> name <> name # we tried. hope it's not zero
      true -> name
    end
  end

  def attributes(:user) do
    name = Faker.Name.name()

    %{
      "email" => Faker.Internet.safe_email(),
      "name" => name,
      "preferred_username" => username(name),
      "password" => "password",
      "locale" => "es",
      "icon" => attributes(:image),
      "primary_language" => "es",
      "summary" => Faker.Lorem.sentence(),
      "location" => %{type: "Place", content: Faker.Pokemon.location()}
    }
  end

  def attributes(:oauth_app) do
    url = Faker.Internet.url()

    %{
      "client_name" => Faker.App.name(),
      "redirect_uri" => url,
      "scopes" => "read",
      "website" => url,
      "client_id" => url
    }
  end

  def attributes(:community) do
    %{
      "content" => Faker.Lorem.sentence(),
      "preferred_username" => username(Faker.Internet.user_name()),
      "name" => Faker.Pokemon.name(),
      "summary" => Faker.Lorem.sentence(),
      "primary_language" => "es",
      "icon" => attributes(:image)
    }
  end

  def attributes(:collection) do
    %{
      "content" => Faker.Lorem.sentence(),
      "name" => Faker.Beer.brand(),
      "icon" => attributes(:image),
      "preferred_username" => username(Faker.Internet.user_name()),
      "summary" => Faker.Lorem.sentence(),
      "primary_language" => "es"
    }
  end

  def attributes(:resource) do
    %{
      "content" => Faker.Lorem.sentence(),
      "name" => Faker.Industry.industry(),
      "url" => Faker.Internet.url(),
      "summary" => Faker.Lorem.sentence(),
      "icon" => attributes(:image),
      "primary_language" => "es",
      "same_as" => "https://hq.moodle.net/r/98765",
      "in_language" => ["en-GB"],
      "public_access" => true,
      "is_accesible_for_free" => true,
      "license" => "http://creativecommons.org/licenses/by-nc-sa/3.0/",
      "learning_resource_type" => "?",
      "educational_use" => ["group work", "assignment"],
      "time_required" => 60,
      "typical_age_range" => "10-12"
    }
  end

  def attributes(:comment) do
    %{
      "content" => Faker.Lorem.sentence(),
      "primary_language" => "fr"
    }
  end

  def attributes(:image) do
    %{
      "type" => "Image",
      "url" => image_url(),
      "width" => 405,
      "height" => 275
    }
  end

  def attributes(:icon) do
    %{
      "type" => "Image",
      "url" => Faker.Avatar.image_url(300, 300),
      "width" => 300,
      "height" => 300
    }
  end

  def attributes(factory_name, attrs) do
    attrs =
      Enum.into(attrs, %{}, fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} when is_binary(k) -> {k, v}
      end)

    factory_name
    |> attributes()
    |> Map.merge(attrs)
  end

  def image_url(),
    do: "https://picsum.photos/405/275=#{Faker.random_between(1, 1000)}"

  alias MoodleNet.Accounts

  def full_user(attrs \\ %{}) do
    attrs = attributes(:user, attrs)
    Accounts.add_email_to_whitelist(attrs[:email] || attrs["email"])
    {:ok, ret} = Accounts.register_user(attrs)
    ret
  end

  def user(attrs \\ %{}), do: full_user(attrs).user
  def actor(attrs \\ %{}), do: full_user(attrs).actor

  alias MoodleNet.OAuth

  def oauth_token(%MoodleNet.Accounts.User{id: user_id}) do
    {:ok, token} = OAuth.create_token(user_id)
    token
  end

  def oauth_app(attrs \\ %{}) do
    attrs = attributes(:oauth_app, attrs)
    {:ok, app} = OAuth.create_app(attrs)
    app
  end

  def community(actor, attrs \\ %{}) do
    attrs = attributes(:community, attrs)
    {:ok, c} = MoodleNet.create_community(actor, attrs)
    c
  end

  def collection(actor, community, attrs \\ %{}) do
    attrs = attributes(:collection, attrs)
    {:ok, c} = MoodleNet.create_collection(actor, community, attrs)
    c
  end

  def resource(actor, context, attrs \\ %{}) do
    attrs = attributes(:resource, attrs)
    {:ok, c} = MoodleNet.create_resource(actor, context, attrs)
    c
  end

  def comment(author, context, attrs \\ %{}) do
    attrs = attributes(:comment, attrs)
    {:ok, c} = MoodleNet.create_thread(author, context, attrs)
    c
  end

  def reply(author, in_reply_to, attrs \\ %{}) do
    attrs = attributes(:comment, attrs)
    {:ok, c} = MoodleNet.create_reply(author, in_reply_to, attrs)
    c
  end

  def instance(since \\ nil) do
    ActivityPub.Instances.set_unreachable("domain.com", since)
  end
end
