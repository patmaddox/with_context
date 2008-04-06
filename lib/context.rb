require "singleton"

module InContext
  def method_missing(method_name, *args, &block)
    if m = module_for_context(InContext::ContextHolder.instance.current_context)
      (class << self; self; end).send :include, m
      return send(method_name, *args, &block)
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
      InContext::ContextHolder.instance.with_context name, &block
    end
  end

  class ContextHolder
    include Singleton
    attr_reader :current_context
    
    def with_context(name, &block)
      @current_context = name
      block.call if block
      @current_context = nil
    end
  end
end
