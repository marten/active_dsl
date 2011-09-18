require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActiveDsl" do
  describe "Builder" do

    describe "building an instance" do
      before(:all) do
        class Sprocket
          attr_accessor :name
          attr_accessor :components
        end

        class Component
          attr_accessor :name
        end

        class ComponentBuilder < ActiveDSL::Builder
          builds Component
          field :name
        end

        class SprocketBuilder < ActiveDSL::Builder
          builds Sprocket
          field :name
          has_many :components
        end
      end

      it "should fill out fields" do
        builder = SprocketBuilder.new("name 'Coffee Mug'")
        instance = builder.to_instance
        instance.should be_a(Sprocket)
        instance.name.should == "Coffee Mug"
      end

      it "should build associations" do
        builder = SprocketBuilder.new(<<-END)
          name "Coffee Mug"
          component do
            name "Handle"
          end
          component do
            name "Cup"
          end
          component do
            name "Great coffee"
          end
        END
        instance = builder.to_instance
        instance.should be_a(Sprocket)
        instance.name.should == "Coffee Mug"
        instance.components.size.should == 3
        instance.components.map(&:class).should == [Component, Component, Component]
        instance.components.map(&:name).should == ["Handle", "Cup", "Great coffee"]
      end
    end

    describe "callbacks" do
      before(:all) do
        class Sprocket
          def save
            @saved = true
          end

          def saved?
            @saved || false
          end
        end
        class SprocketBuilder < ActiveDSL::Builder
          builds Sprocket
          after_build_instance do |instance|
            instance.save
          end
        end
      end

      it "should save the instance" do
        instance = SprocketBuilder.new("").to_instance
        instance.saved?.should be_true
      end
    end

    describe "attributes" do
      before(:all) do
        class SprocketBuilder < ActiveDSL::Builder
          field :name
        end
      end

      it "should be possible to specify configuration by string" do
        SprocketBuilder.new("name 'Coffee Mug'").to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to specify configuration by block" do
        SprocketBuilder.new do 
          name "Coffee Mug"
        end.to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to give an attribute a value from the DSL" do
        dsl = "name 'Coffee Mug'"
        SprocketBuilder.new(dsl).to_hash[:name].should == "Coffee Mug"
      end

      it "should be possible to override a previous value" do
        dsl = "name 'Coffee Mug'
               name 'Tea Cup'"
        SprocketBuilder.new(dsl).to_hash[:name].should == "Tea Cup"
      end
    end

    describe "has-many associations" do
      before(:all) do
        class ComponentBuilder < ActiveDSL::Builder
          field :name
        end

        class SprocketBuilder < ActiveDSL::Builder
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

        sprocket = SprocketBuilder.new(dsl).to_hash
        sprocket[:components][0][:name].should == "handle"
        sprocket[:components][1][:name].should == "cup"
      end
    end
  end
end
