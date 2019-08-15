# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SignatureTest do
  use MoodleNet.DataCase

  import ExUnit.CaptureLog
  import MoodleNet.Factory
  import Tesla.Mock

  alias ActivityPub.Signature

  setup do
    mock(fn env -> apply(HttpRequestMock, :request, [env]) end)
    :ok
  end

  defp make_fake_signature(key_id), do: "keyId=\"#{key_id}\""

  defp make_fake_conn(key_id),
    do: %Plug.Conn{req_headers: %{"signature" => make_fake_signature(key_id <> "#main-key")}}

  describe "fetch_public_key/1" do
    test "works" do
      id = "https://kawen.space/users/karen"

      {:ok, {:RSAPublicKey, _, _}} = Signature.fetch_public_key(make_fake_conn(id))
    end

    test "it returns error when not found user" do
      assert capture_log(fn ->
               assert Signature.fetch_public_key(make_fake_conn("test-ap_id")) == {:error, :error}
             end)
    end
  end

  describe "refetch_public_key/2" do
    test "works" do
      id = "https://kawen.space/users/karen"

      {:ok, {:RSAPublicKey, _, _}} = Signature.refetch_public_key(make_fake_conn(id))
    end

    test "it returns error when not found user" do
      assert capture_log(fn ->
               assert Signature.refetch_public_key(make_fake_conn("test-id")) ==
                        {:error, {:error, false}}
             end)
    end
  end

  describe "sign/2" do
    test "works" do
      actor = actor()

      _signature =
        Signature.sign(actor, %{
          host: "test.test",
          "content-length": 100
        })
    end
  end
end
