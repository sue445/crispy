require 'crispy/crispy_received_message'
require 'crispy/crispy_internal/spy_mixin'
require 'crispy/crispy_internal/with_stubber'

module Crispy
  module CrispyInternal
    class Spy < ::Module
      include SpyMixin
      include WithStubber

      def initialize target, stubs_map = {}
        super()
        @received_messages = []
        singleton_class =
          class << target
            self
          end
        initialize_stubber stubs_map
        prepend_stubber singleton_class

        prepend_features singleton_class
        target.__CRISPY_SPY__ = self
      end

      def prepend_features klass
        super
        klass.public_instance_methods.each do|method_name|
          self.module_eval { public define_wrapper(method_name) }
        end
        klass.protected_instance_methods.each do|method_name|
          self.module_eval { protected define_wrapper(method_name) }
        end
        klass.private_instance_methods.each do|method_name|
          self.module_eval { private define_wrapper(method_name) }
        end

        # define accessor after prepending to avoid to spy unexpectedly.
        module_eval { attr_accessor :__CRISPY_SPY__ }
      end

      def define_wrapper method_name
        define_method method_name do|*arguments, &attached_block|
          @__CRISPY_SPY__.received_messages <<
            ::Crispy::CrispyReceivedMessage.new(method_name, *arguments, &attached_block)
          super(*arguments, &attached_block)
        end
        method_name
      end
      private :define_wrapper

    end
  end
end
