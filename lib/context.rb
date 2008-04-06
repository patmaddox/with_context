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
    context && self.class.context_modules[context]
  end
  
  module ClassMethods
    def in_context(name, &block)
      m = Module.new
      m.module_eval &block
      context_modules[name] = m
      name
    end

    def context_modules
      @context_modules ||= { }
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
          (class << target; self; end).send(:define_method, meth) {
            raise NoMethodError(meth)
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
