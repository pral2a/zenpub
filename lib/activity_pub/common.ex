defmodule ActivityPub.SQL.Common do
  alias ActivityPub.Entity

  import ActivityPub.Guards

  def local_id(%ActivityPub.SQL.AssociationNotLoaded{local_id: local_id})
       when not is_nil(local_id),
       do: local_id

  def local_id(entity) when has_local_id(entity),
    do: Entity.local_id(entity)

  def local_id(entity) when is_entity(entity),
    do: raise ArgumentError, "Entity must be loaded to persist correctly"

  def local_id(id) when is_integer(id), do: id
end
