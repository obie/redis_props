require 'spec_helper'
require 'sqlite3'
require 'active_record'

class Dog < ActiveRecord::Base
  include RedisProps

  establish_connection :adapter => 'sqlite3', :database => 'spec/foobar.db'
  connection.create_table :dogs, :force => true do |t|
    t.string :name
    t.timestamps
  end

  props :has_medical_condition do
    define :fleas, default: false
    define :pants, default: true
  end

  props :appearance, touch: true do
    define :coat
  end
end

class User < ActiveRecord::Base
  include RedisProps

  establish_connection :adapter => 'sqlite3', :database => 'spec/foobar.db'
  connection.create_table :users, :force => true do |t|
    t.string :name
    t.timestamp :saved_at
  end

  props :flags, touch: :saved_at do
    define :weekly_digest, default: true
  end

  props :number_of do
    define :records, default: 0
  end

  props :stats do
    define :temperature, default: 98.7
  end
end

describe RedisProps do
  let(:clean_dog) { Dog.create!(name: "Wego") }
  let(:dirty_dog) { Dog.create!(name: "Bodiddly") }
  let(:user) { User.create!(name: "Hugo", saved_at: 1.day.ago) }

  context "props options" do
    it "should touch the AR object's updated_at if touch: true" do
      orig_updated_at = clean_dog.updated_at
      clean_dog.appearance_coat = "Scruffy"
      clean_dog.save
      Dog.find_by_name("Wego").updated_at.should_not == orig_updated_at
    end
    it "should touch the AR object's saved_at if touch: :saved_at" do
      orig_saved_at = user.saved_at
      user.flags_weekly_digest = false
      user.save
      User.find_by_name("Hugo").saved_at.should_not == orig_saved_at
    end
  end

  context "props definitions" do
    it "creates persistent attributes" do
      dirty_dog.has_medical_condition_fleas = true
      dirty_dog = Dog.find_by_name "Bodiddly"
      dirty_dog.should have_medical_condition_fleas
    end

    it "sets defaults if provided" do
      clean_dog.should have_medical_condition_pants
      clean_dog.should_not have_medical_condition_fleas
    end

    context "do type inference based on default values provided" do
      it "works for booleans" do
        user.flags_weekly_digest = false
        user.flags_weekly_digest.should == false
      end
      it "works for integers" do
        user.number_of_records = 42
        User.find(user.id).number_of_records.should == 42
      end
      it "works for floats" do
        user.stats_temperature = 99.9
        User.find(user.id).stats_temperature.should == 99.9
      end
    end
  end

  context "default behavior" do
    it "is to remove associated redis keys when parent AR object is destroyed" do
      user.class_eval { public :r }
      user.flags_weekly_digest = false
      user.r["flags_weekly_digest"].get.should == "false"
      user.destroy
      user.r["flags_weekly_digest"].get.should == nil
    end
  end
end


