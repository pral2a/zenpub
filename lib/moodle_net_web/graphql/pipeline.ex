defmodule MoodleNetWeb.GraphQL.Pipeline do

  alias MoodleNetWeb.GraphQL.Phase.Arguments
  alias Absinthe.{Phase, Pipeline}

  def default_pipeline(config, opts) do
    Absinthe.Plug.default_pipeline(config, opts)
    |> Pipeline.replace(Phase.Document.Execution.Resolution, MoodleNetWeb.GraphQL.Phase.ExecutionResolution)
    # |> Pipeline.insert_before(Phase.Document.Result, MoodleNetWeb.GraphQL.Phase.Debug)
    # |> Pipeline.insert_before(Phase.Document.Arguments.Parse, Arguments.Parse)
    # |> Pipeline.insert_before(Phase.Document.Arguments.Parse, Arguments.Debug)
    # |> Pipeline.insert_after(Phase.Document.Arguments.Parse, Arguments.Debug)
    # # |> Pipeline.replace(Phase.Document.Arguments.FlagInvalid, Arguments.FlagInvalid)
    # |> Pipeline.replace(Phase.Document.Arguments.Data, Arguments.Data)
  end

end
