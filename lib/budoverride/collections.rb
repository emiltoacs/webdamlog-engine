# Bud methods overridden in Webdamlog
module Bud

  # Add a delete methods used by deletion via provenance
  class BudCollection

    # Delete a tuple without propagating invalidation.
    #  This is used to delete via the provenance graph deletion propagation algorithm.
    #  @return the tuple deleted or nil if nothing has been deleted.
    def delete_without_invalidation tuple
      keycols = get_key_vals(tuple)
      if @storage[keycols] == tuple
        v = @storage.delete keycols
      end
      return v
    end
  end
end
