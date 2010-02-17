#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::Function do
  before :each do
    @scope = mock 'scope'
  end

  describe "when initializing" do
    it "should not fail if the function doesn't exist" do
      Puppet::Parser::Functions.stubs(:function).returns(false)

      lambda{ Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "dontexist" }.should_not raise_error(Puppet::ParseError)

    end
  end

  it "should return its representation with to_s" do
    args = stub 'args', :is_a? => true, :to_s => "[a, b]"

    Puppet::Parser::Expression::Function.new(:scope => ((@scope)), :name => "func", :arguments => args).to_s.should == "func(a, b)"
  end

  describe "when evaluating" do

    it "should fail if the function doesn't exist" do
      Puppet::Parser::Functions.stubs(:function).returns(false)
      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "dontexist"

      lambda{ func.compute_denotation }.should raise_error(Puppet::ParseError)
    end

    it "should fail if the function is a statement used as rvalue" do
      Puppet::Parser::Functions.stubs(:function).with("exist").returns(true)
      Puppet::Parser::Functions.stubs(:rvalue?).with("exist").returns(false)

      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "exist", :ftype => :rvalue

      lambda{ func.compute_denotation }.should raise_error(Puppet::ParseError, "Function 'exist' does not return a value")
    end

    it "should fail if the function is an rvalue used as statement" do
      Puppet::Parser::Functions.stubs(:function).with("exist").returns(true)
      Puppet::Parser::Functions.stubs(:rvalue?).with("exist").returns(true)

      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "exist", :ftype => :statement

      lambda{ func.compute_denotation }.should raise_error(Puppet::ParseError,"Function 'exist' must be the value of a statement")
    end

    it "should evaluate its arguments" do
      argument = stub 'arg'
      Puppet::Parser::Functions.stubs(:function).with("exist").returns(true)
      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "exist", :ftype => :statement, :arguments => argument
      @scope.stubs(:function_exist)

      argument.expects(:denotation).returns("argument")

      func.compute_denotation
    end

    it "should call the underlying ruby function" do
      argument = stub 'arg', :denotation => "nothing"
      Puppet::Parser::Functions.stubs(:function).with("exist").returns(true)
      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "exist", :ftype => :statement, :arguments => argument

      @scope.expects(:function_exist).with("nothing")

      func.compute_denotation
    end

    it "should return the ruby function return for rvalue functions" do
      argument = stub 'arg', :denotation => "nothing"
      Puppet::Parser::Functions.stubs(:function).with("exist").returns(true)
      func = Puppet::Parser::Expression::Function.new :scope => ((@scope)), :name => "exist", :ftype => :statement, :arguments => argument
      @scope.stubs(:function_exist).with("nothing").returns("returning")

      func.compute_denotation.should == "returning"
    end

  end
end
