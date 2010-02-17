#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::Nop do

  before do
    @scope = mock 'scope'
  end

  it "should do nothing on evaluation" do
    Puppet::Parser::Expression.expects(:safeevaluate).never
    Puppet::Parser::Expression::Nop.new({}).evaluate(@scope)
  end

  it "should not return anything" do
    Puppet::Parser::Expression::Nop.new({}).evaluate(@scope).should be_nil
  end

end
