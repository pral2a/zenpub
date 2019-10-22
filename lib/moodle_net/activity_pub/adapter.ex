defmodule MoodleNet.ActivityPub.Adapter do
  alias MoodleNet.Actors

  @behaviour ActivityPub.Adapter

  def get_actor_by_username(username) do
    Actors.fetch_by_username(username)
  end

  defp maybe_fix_image_object(url) when is_binary(url), do: url
  defp maybe_fix_image_object(%{"url" => url}), do: url
  defp maybe_fix_image_object(_), do: nil

  def create_remote_actor(actor, username) do
    create_attrs = %{
      preferred_username: username,
      name: actor["name"],
      summary: actor["summary"],
      icon: maybe_fix_image_object(actor["icon"]),
      image: maybe_fix_image_object(actor["image"]),
      is_public: true
    }

    Actors.create(create_attrs)
  end

  def maybe_create_remote_actor(actor) do
    host = URI.parse(actor.data["id"]).host
    username = actor.data["preferredUsername"] <> "@" <> host

    case Actors.fetch_by_username(username) do
      {:error, _} ->
        with {:ok, _actor} <- create_remote_actor(actor.data, username) do
          :ok
        else
          _e -> {:error, "Couldn't create remote actor"}
        end

      _ ->
        :ok
    end
  end

  def handle_activity(activity) do
    activity
    |> Map.from_struct()
    |> run()
  end

  @spec run(Map.t()) :: :ok | {:error, any()}
  def run(_map) do
    :ok
  end
end
