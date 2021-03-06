# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Likes.LikerCounts do
  alias MoodleNet.Repo
  alias MoodleNet.GraphQL.Fields
  alias MoodleNet.Likes.{LikerCount, LikerCountsQueries}

  def one(filters), do: Repo.single(LikerCountsQueries.query(LikerCount, filters))

  def many(filters \\ []) do
    {:ok, Repo.all(LikerCountsQueries.query(LikerCount, filters))}
  end

  def fields(group_fn, filters \\ [])
  when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

end
