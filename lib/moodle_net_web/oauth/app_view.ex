defmodule MoodleNetWeb.OAuth.AppView do
  @moduledoc """
  OAuth Application view
  """
  use MoodleNetWeb, :view

  def render("app.json", %{app: app}) do
    Map.take(app, [:client_name, :redirect_uri, :scopes, :website, :client_id, :client_secret])
  end
end
