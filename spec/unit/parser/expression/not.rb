#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::Not do
  before :each do
    @scope = Puppet::Parser::Scope.new
    @true_ast = Puppet::Parser::Expression::Boolean.new( :value => true)
    @false_ast = Puppet::Parser::Expression::Boolean.new( :value => false)
  end

  it "should evaluate its child expression" do
    val = stub "val"
    val.expects(:denotation)

    operator = Puppet::Parser::Expression::Not.new :scope => ((@scope)), :value => val
    operator.compute_denotation
  end

  it "should return true for ! false" do
    operator = Puppet::Parser::Expression::Not.new :scope => ((@scope)), :value => @false_ast
    operator.compute_denotation.should == true
  end

  it "should return false for ! true" do
    operator = Puppet::Parser::Expression::Not.new :scope => ((@scope)), :value => @true_ast
    operator.compute_denotation.should == false
  end

end
