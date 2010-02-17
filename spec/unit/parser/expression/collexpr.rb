#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::CollExpr do

  ast = Puppet::Parser::Expression

  before :each do
    @scope = Puppet::Parser::Scope.new
  end

  describe "when evaluating with two operands" do
    before :each do
      @test1 = mock 'test1'
      @test1.expects(:denotation).returns("test1")
      @test2 = mock 'test2'
      @test2.expects(:denotation).returns("test2")
    end

    it "should evaluate both" do
      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper=>"==")
      collexpr.compute_denotation
    end

    it "should produce a textual representation and code of the expression" do
      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper=>"==")
      result = collexpr.compute_denotation
      result[0].should == "param_values.value = 'test2' and param_names.name = 'test1'"
      result[1].should be_an_instance_of(Proc)
    end

    it "should propagate expression type and form to child if expression themselves" do
      [@test1, @test2].each do |t|
        t.expects(:is_a?).returns(true)
        t.expects(:form).returns(false)
        t.expects(:type).returns(false)
        t.expects(:type=)
        t.expects(:form=)
      end

      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper=>"==", :form => true, :type => true)
      result = collexpr.compute_denotation
    end

    describe "and when evaluating the produced code" do
      before :each do
        @resource = mock 'resource'
        @resource.expects(:[]).with("test1").at_least(1).returns("test2")
      end

      it "should evaluate like the original expression for ==" do
        collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper => "==")
        collexpr.compute_denotation[1].call(@resource).should === (@resource["test1"] == "test2")
      end

      it "should evaluate like the original expression for !=" do
        collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper => "!=")
        collexpr.compute_denotation[1].call(@resource).should === (@resource["test1"] != "test2")
      end
    end

    it "should warn if this is an exported collection containing parenthesis (unsupported)" do
      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper=>"==", :parens => true, :form => :exported)
      Puppet.expects(:warning)
      collexpr.compute_denotation
    end

    %w{and or}.each do |op|
      it "should raise an error if this is an exported collection with #{op} operator (unsupported)" do
        collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @test1, :test2 => @test2, :oper=> op, :form => :exported)
        lambda { collexpr.compute_denotation }.should raise_error(Puppet::ParseError)
      end
    end
  end

  describe "when evaluating with tags" do
    before :each do
      @tag = stub 'tag', :denotation => 'tag'
      @value = stub 'value', :denotation => 'value'

      @resource = stub 'resource'
      @resource.stubs(:tagged?).with("value").returns(true)
    end

    it "should produce a textual representation of the expression" do
      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @tag, :test2 => @value, :oper=>"==")
      result = collexpr.compute_denotation
      result[0].should == "puppet_tags.name = 'value'"
    end

    it "should inspect resource tags if the query term is on tags" do
      collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => @tag, :test2 => @value, :oper => "==")
      collexpr.compute_denotation[1].call(@resource).should be_true
    end
  end

  [:exported,:virtual].each do |mode|
  it "should check for array member equality if resource parameter is an array for == in mode #{mode}" do
    array = mock 'array', :denotation => "array"
    test1 = mock 'test1'
    test1.expects(:denotation).returns("test1")

    resource = mock 'resource'
    resource.expects(:[]).with("array").at_least(1).returns(["test1","test2","test3"])
    collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :test1 => array, :test2 => test1, :oper => "==", :form => mode)
    collexpr.compute_denotation[1].call(resource).should be_true
  end
  end

  it "should raise an error for invalid operator" do
    lambda { collexpr = Puppet::Parser::Expression::CollExpr.new(:scope => ((@scope)), :oper=>">") }.should raise_error
  end

end
