module WLBud
#  class Module

    # Oldies
    # This method dynamically add a method to the current instance with a
    # webdamlog prefix as name and the block given in parameter as body for this
    # new method.
    #
    # Notes: A ruby block to be run before timestep 1.  one per module.
    #
#    def webdamlog(&block)
#      meth_name = "__webdamlog__#{Module.get_class_name(self)}".to_sym
#      define_method(meth_name, &block)
#    end
#  end
end
