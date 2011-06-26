require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActiveDsl" do
  describe "Factory" do
    describe "attributes" do
      before(:all) do
        class SprocketFactory < ActiveDSL::Factory
          field :name
        end
      end

      it "should be possible to specify configuration by string" do
        SprocketFactory.new("name 'Coffee Mug'").to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to specify configuration by block" do
        SprocketFactory.new do 
          name "Coffee Mug"
        end.to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to give an attribute a value from the DSL" do
        dsl = "name 'Coffee Mug'"
        SprocketFactory.new(dsl).to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to override a previous value" do
        dsl = "name 'Coffee Mug'
               name 'Tea Cup'"
        SprocketFactory.new(dsl).to_hash[:name].should == "Tea Cup"
      end
    end

    describe "has-many associations" do
      before(:all) do
        class ComponentFactory < ActiveDSL::Factory
          field :name
        end

        class SprocketFactory < ActiveDSL::Factory
          field :name
          has_many :components
        end

      end

      it "should work with has-many associations" do
        dsl = %( name 'Coffee Mug'
                 component do
                   name 'handle'
                 end
                 component do
                   name 'cup'
                 end
               )

        sprocket = SprocketFactory.new(dsl).to_hash
        sprocket[:components][0][:name].should == "handle"
        sprocket[:components][1][:name].should == "cup"
      end
    end
  end
end
