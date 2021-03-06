# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Mail.MailService do
  @moduledoc """
  A service for sending email
  """
  use Bamboo.Mailer, otp_app: :moodle_net
end
