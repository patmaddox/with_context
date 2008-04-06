require "rubygems"
require "expand_path"
$:.unshift __FILE__.expand_path
require "spec_helper"
require "context"

describe "An object with a method declared in a context" do
  include InContext::WithContext
  
  class ContextualObject
    include InContext
    
    in_context :callable do
      def call
        @called = true
      end
    end

    def called?
      @called
    end
  end
  
  before(:each) do
    @object = ContextualObject.new
    @object.should_not be_called
  end
  
  it "should not respond to the method" do
    lambda { @object.call }.should raise_error(NoMethodError)
  end

  it "should respond to the method in a context" do
    with_context(:callable) { @object.call }
    @object.should be_called
  end

  it "should not respond to the method once the context is complete" do
    with_context(:callable) { @object.call }
    lambda { @object.call }.should raise_error(NoMethodError)
  end
end

describe "An object with an instance method, and the same method declared in a context" do
  include InContext::WithContext
  
  class OverrideInContext
    include InContext

    def the_context(collector)
      collector << :instance
    end

    in_context(:override) do
      def the_context(collector)
        collector << :singleton
      end
    end
  end

  before(:each) do
    @object = OverrideInContext.new
    @collector = []
  end

  it "should call the overridden method in context, and the original method in default context" do
    with_context(:override) { @object.the_context @collector }
    @object.the_context @collector
    @collector.should == [:singleton, :instance]
  end
end
