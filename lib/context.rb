require __FILE__.expand_path("extensions/unbound_method")

module InContext
  def method_missing(method_name, *args, &block)
    if m = module_for_context(InContext::ContextHolder.current_context)
      if m.instance_methods.include?(method_name.to_s)
        (class << self; self; end).send :include, m
        InContext::ContextHolder.targets_with_contexts[self] = m
        return send(method_name, *args, &block)
      end
    end
    super
  end

  def module_for_context(context)
    self.class.module_for_context context
  end
  
  module ClassMethods
    def in_context(name, &block)
      m = module_for_context(name) || Module.new
      m.module_eval &block
      m.instance_methods.each do |meth|
        if instance_methods.include?(meth)
          default_context_methods << instance_method(meth)
          remove_method meth
        end
      end
      context_modules[name] = m
      name
    end

    def module_for_context(context)
      context && context_modules[context]
    end

    def context_modules
      @context_modules ||= { }
    end

    def default_context_methods
      @default_context_methods ||= []
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
  
  module WithContext
    def with_context(name, &block)
      InContext::ContextHolder.with_context name, &block
    end
  end

  class ContextHolder
    def self.current_context
      @current_context
    end
    
    def self.with_context(name, &block)
      @current_context = name
      block.call if block
      clear_targets_with_contexts
      @current_context = nil
    end

    def self.clear_targets_with_contexts
      targets_with_contexts.each do |target, mod|
        mod.instance_methods.each do |meth|
          (class << target; self; end).send(:define_method, meth) {|*args|
            target.class.default_context_methods.find {|m| m.name == meth }.bind(self).call(*args)
          }
        end
        targets_with_contexts.delete target
      end
    end

    def self.targets_with_contexts
      @targets_with_contexts ||= { }
    end
  end
end
