# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Repo.Migrations.Flagging do
  use ActivityPub.Migration

  def change do

    alter table(:mn_collection_flags) do
      add_foreign_key(:community_object_id, "activity_pub_objects")
    end

    alter table(:mn_resource_flags) do
      add_foreign_key(:community_object_id, "activity_pub_objects")
    end

    alter table(:mn_comment_flags) do
      add_foreign_key(:community_object_id, "activity_pub_objects")
    end

  end

end
