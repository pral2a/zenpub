# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads.Queries do
  import Ecto.Query

  alias MoodleNet.Uploads.Content

  def query(Content) do
    from c in Content, as: :content,
      left_join: u in assoc(c, :content_upload), as: :content_upload,
      left_join: m in assoc(c, :content_mirror), as: :content_mirror,
      preload: [content_upload: u, content_mirror: m]
  end

  def query(q, filters), do: filter(query(q), filters)

  @doc "Filter the query according to arbitrary criteria"
  def filter(q, filter_or_filters)

  ## many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by status
  def filter(q, :deleted) do
    where q, [content: c], is_nil(c.deleted_at)
  end

  def filter(q, :private) do
    where q, [content: c], not is_nil(c.published_at)
  end

  # by field values

  def filter(q, {:id, id}) when is_binary(id) do
    where q, [content: c], c.id == ^id
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where q, [content: c], c.id in ^ids
  end

  def filter(q, {:uploader_id, id}) when is_binary(id) do
    where q, [content: c], c.uploader_id == ^id
  end

  def filter(q, {:uploader_id, ids}) when is_list(ids) do
    where q, [content: c], c.uploader_id in ^ids
  end
end
