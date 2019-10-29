# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Common.Guards do
  @doc "Commonly used guard expressions"
  
  defguard is_positive(val) when val > 0

  defguard is_non_negative(val) when val >= 0

  defguard is_positive_integer(val)
    when is_integer(val) and is_positive(val)

  defguard is_non_negative_integer(val)
    when is_integer(val) and is_non_negative(val)

end
