#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::MatchOperator do
  before :each do
    @scope = Puppet::Parser::Scope.new

    @lval = stub 'lval'
    @lval.stubs(:denotation).with(@scope).returns("this is a string")

    @rval = stub 'rval'
    @rval.stubs(:evaluate_match)

    @operator = Puppet::Parser::Expression::MatchOperator.new :lval => @lval, :rval => @rval, :operator => "=~"
  end

  it "should evaluate the left operand" do
    @lval.expects(:denotation).with(@scope)

    @operator.compute_denotation(@scope)
  end

  it "should fail for an unknown operator" do
    lambda { operator = Puppet::Parser::Expression::MatchOperator.new :lval => @lval, :operator => "unknown", :rval => @rval }.should raise_error
  end

  it "should evaluate_match the left operand" do
    @rval.expects(:evaluate_match).with("this is a string", @scope).returns(:match)

    @operator.compute_denotation(@scope)
  end

  { "=~" => true, "!~" => false }.each do |op, res|
    it "should return #{res} if the regexp matches with #{op}" do
      match = stub 'match'
      @rval.stubs(:evaluate_match).with("this is a string", @scope).returns(match)

      operator = Puppet::Parser::Expression::MatchOperator.new :lval => @lval, :rval => @rval, :operator => op
      operator.compute_denotation(@scope).should == res
    end

    it "should return #{!res} if the regexp doesn't match" do
      @rval.stubs(:evaluate_match).with("this is a string", @scope).returns(nil)

      operator = Puppet::Parser::Expression::MatchOperator.new :lval => @lval, :rval => @rval, :operator => op
      operator.compute_denotation(@scope).should == !res
    end
  end
end
