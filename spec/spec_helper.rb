require "rubygems"
require "expand_path"
$:.unshift __FILE__.expand_path("/spec/vendor/rspec/lib")
require "spec"
$:.unshift __FILE__.expand_path("../lib")
