module WLBud
  
  class WL
    include WLBud
    
    attr_reader :wl_callback, :wl_callback_step, :wl_callback_id
    
    # Register a callback triggered during the tick at the moment specified by
    # *step*, it will execute &blk
    #
    # Note that option :wl_test must be set for the wlbud instance otherwise
    # callback are ignored. This callback are used for test and must not be used
    # for production.
    #
    # * :callback_step_received_on_chan called in the tick just after inbound
    #   has been flushed into chan
    # * :callback_step_write_on_chan, :callback_step_write_on_chan_2 two
    #   callback called just after writing on channel
    # * :callback_step_end_tick is called at the end of the tick with self as
    #   argument
    #
    # === return
    # the callback id useful to unregister the callback later
    #
    def register_wl_callback(step, &blk)
      unless @wl_callback_step.include? step
        raise WLBud::WLErrorCallback, "no such callback step #{step}"
      end
      if @wl_callback.has_key? @wl_callback_id
        raise WLBud::WLErrorCallback, "callback duplicate key"
      end
      @wl_callback[@wl_callback_id] = [step, blk]
      cb_id = @wl_callback_id
      @wl_callback_id += 1
      return cb_id
    end

    # Unregister the callback by id given during registration
    #
    def unregister_wl_callback(cb_id)
      raise WLBud::WLErrorCallback, "missing callback: #{cb_id.inspect}" unless @wl_callback.has_key? cb_id
      @wl_callback.delete(cb_id)
    end
  end
end