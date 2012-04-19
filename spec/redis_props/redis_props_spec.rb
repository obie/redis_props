require 'spec_helper'
require 'sqlite3'
require 'active_record'

class Dog < ActiveRecord::Base
  include RedisProps

  establish_connection :adapter => 'sqlite3', :database => 'spec/foobar.db'
  connection.create_table :dogs, :force => true do |t|
    t.string :name
  end

  redis_props :has_medical_condition do
    define :fleas, default: false
  end
end

describe Dog do
  context "fleas" do
    let(:dog) { Dog.create!(name: "Wego") }
    it "should not have fleas" do
      dog.should_not have_medical_condition_fleas
    end
  end
end


