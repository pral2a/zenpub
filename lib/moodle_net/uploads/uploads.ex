# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads do

  alias Ecto.Changeset
  alias MoodleNet.Common.NotFoundError
  alias MoodleNet.Changeset.Common
  alias MoodleNet.Meta.Pointers
  alias MoodleNet.Repo
  alias MoodleNet.Users.User
  alias MoodleNet.Uploads.{Content, ContentUpload, ContentMirror, Storage, Queries}

  def one(filters), do: Repo.single(Queries.query(Content, filters))

  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Content, filters))}

  @doc """
  Attempt to store a file, returning an upload, for any parent item that
  participates in the meta abstraction, providing the actor responsible for
  the upload.
  """
  @spec upload(upload_def :: any, uploader :: User.t(), file :: any, attrs :: map) ::
          {:ok, Content.t()} | {:error, Changeset.t()}
  def upload(upload_def, %User{} = uploader, file, attrs) do
    with {:ok, file} <- parse_file(file),
         {:ok, file} <- allow_extension(upload_def, file),
         {:ok, content} <- insert_content(upload_def, uploader, file, attrs),
         {:ok, url} <- remote_url(content) do
      {:ok, %{ content | url: url }}
    end
  end

  defp insert_content(upload_def, uploader, file, attrs) do
    # FIXME: delegate to Storage
    Repo.transact_with(fn ->
      if is_remote_file?(file) do
        insert_content_mirror(uploader, file, attrs)
      else
        insert_content_upload(upload_def, uploader, file, attrs)
      end
    end)
  end

  defp insert_content_mirror(uploader, %{url: url} = file, attrs) do
    with {:ok, file_info} <- TwinkleStar.from_uri(url),
         {:ok, mirror} <- Repo.insert(ContentMirror.changeset(%{url: url})),
         attrs = file_info_to_content(file_info, attrs),
         {:ok, content} <- Repo.insert(Content.mirror_changeset(mirror, uploader, attrs)) do
      {:ok, %{ content | content_mirror: mirror }}
    else
      # match behaviour of uploads
      {:error, {:request_failed, 404}} -> {:error, :enoent}
    end
  end

  defp insert_content_upload(upload_def, uploader, file, attrs) do
    storage_opts = [scope: uploader.id]

    with {:ok, file_info} <- Storage.store(upload_def, file, storage_opts) do
      upload_attrs = %{path: file_info.path, size: file_info.info.size}

      with {:ok, upload} <- Repo.insert(ContentUpload.changeset(upload_attrs)),
            attrs = file_info_to_content(file_info, attrs),
            {:ok, content} <- Repo.insert(Content.upload_changeset(upload, uploader, attrs)) do
        {:ok, %{ content | content_upload: upload }}
      else
        e ->
          # rollback file changes on failure
          Storage.delete(file_info.path)
          e
      end
    end
  end

  @doc """
  Attempt to fetch a remotely accessible URL for the associated file in an upload.
  """
  def remote_url(%Content{content_mirror: mirror, content_mirror_id: id}) when is_binary(id),
    do: {:ok, mirror.url}

  def remote_url(%Content{content_upload: upload, content_upload_id: id}) when is_binary(id),
    do: Storage.remote_url(upload.path)

  @doc """
  Delete an upload, removing it from indexing, but the files remain available.
  """
  @spec soft_delete(Content.t()) :: {:ok, Content.t()} | {:error, Changeset.t()}
  def soft_delete(%Content{} = content), do: MoodleNet.Common.soft_delete(content)

  @doc """
  Delete an upload, removing any associated files.
  """
  @spec hard_delete(Content.t()) :: :ok | {:error, Changeset.t()}
  def hard_delete(%Content{} = content) do
    resp = Repo.transaction(fn ->
      with {:ok, content} <- Repo.delete(content),
           {:ok, _} <- Storage.delete(content.content_upload.path) do
        :ok
      end
    end)

    with {:ok, v} <- resp, do: v
  end

  defp is_remote_file?(%{url: url}), do: is_remote_file?(url)

  defp is_remote_file?(url) when is_binary(url) do
    uri = URI.parse(url)
    not (is_nil(uri.scheme) or is_nil(uri.host) or is_nil(uri.path))
   end

  defp is_remote_file?(_other), do: false

  defp file_info_to_content(file_info, attrs) do
    attrs
    |> Map.put(:media_type, file_info.media_type)
    |> Map.put(:metadata, file_info[:metadata])
  end

  defp parse_file(%{url: url, path: path}) when is_binary(url) and is_binary(path) do
    {:error, :both_url_and_path_should_not_be_set}
  end

  defp parse_file(%{url: url} = file) when is_binary(url) do
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) ->
        file = file
        |> Map.put(:filename, Path.basename(path))
        |> Map.put(:url, URI.encode(url))

        {:ok, file}

      _other ->
        {:error, :invalid_url}
    end
  end

  defp parse_file(file), do: {:ok, file}

  defp allow_extension(upload_def, %{filename: filename} = file) do
    case upload_def.allowed_extensions() do
      :all ->
        {:ok, file}

      allowed ->
        if MoodleNet.File.has_extension?(filename, allowed) do
          {:ok, file}
        else
          {:error, :extension_denied}
        end
    end
  end
end
