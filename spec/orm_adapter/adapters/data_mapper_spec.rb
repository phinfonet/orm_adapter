require 'spec_helper'

if !defined?(DataMapper)
  puts "** require 'dm-core' to run the specs in #{__FILE__}"
else  
  
  DataMapper.setup(:default, 'sqlite::memory:')
  
  module DmOrmSpec
    class User
      include DataMapper::Resource
      property :id,   Serial
      property :name, String
      has n, :notes, :child_key => [:owner_id]
    end

    class Note
      include DataMapper::Resource
      property :id,   Serial
      property :body, String
      belongs_to :owner, 'User'
    end
    
    require  'dm-migrations'
    DataMapper.finalize
    DataMapper.auto_migrate!
  
    # here be the specs!
    describe DataMapper::Resource::OrmAdapter do
      before do
        User.destroy
        Note.destroy
      end
      
      subject { DataMapper::Resource::OrmAdapter }
    
      specify "model_classes should return all of datamapper resources" do
        subject.model_classes.should == [User, Note]
      end
    
      describe "get!(klass, id)" do
        specify "should return the instance of klass with id if it exists" do
          user = User.create!
          User.to_adapter.get!(user.id).should == user
        end
      
        specify "should raise an error if the klass does not have an instance with that id" do
          lambda { User.to_adapter.get!(1) }.should raise_error
        end
      end
    
      describe "find_first(klass, conditions)" do
        specify "should return first model matching conditions, if it exists" do
          user = User.create! :name => "Fred"
          User.to_adapter.find_first(:name => "Fred").should == user
        end

        specify "should return nil if no conditions match" do
          User.to_adapter.find_first(:name => "Betty").should == nil
        end
      
        specify "should handle belongs_to objects in attributes hash" do
          user = User.create!
          note = Note.create! :owner => user
          Note.to_adapter.find_first(:owner => user).should == note
        end
      end
    
      describe "find_all(klass, conditions)" do
        specify "should return all models matching conditions" do
          user1 = User.create! :name => "Fred"
          user2 = User.create! :name => "Fred"
          user3 = User.create! :name => "Betty"
          User.to_adapter.find_all(:name => "Fred").should == [user1, user2]
        end

        specify "should return empty array if no conditions match" do
          User.to_adapter.find_all(:name => "Betty").should == []
        end
      
        specify "should handle belongs_to objects in conditions hash" do
          user1, user2 = User.create!, User.create!
          note1, note2 = user1.notes.create!, user2.notes.create!
          Note.to_adapter.find_all(:owner => user1).should == [note1]
        end
      end

      describe "create!(klass, attributes)" do
        it "should create a model using the given attributes" do
          User.to_adapter.create!(:name => "Fred")
          User.last.name.should == "Fred"
        end
      
        it "should raise error if the create fails" do
          lambda { subject.create!(:non_existent => true) }.should raise_error
        end
      
        it "should handle belongs_to objects in attributes hash" do
          user = User.create!
          Note.to_adapter.create!(:owner => user)
          Note.last.owner.should == user
        end
      
        it "should handle has_many objects in attributes hash" do
          notes = [Note.create!, Note.create!]
          User.to_adapter.create!(:notes => notes)
          User.last.notes.should == notes
        end
      end
      
      describe "<model class>#to_adapter" do
        it "should return an adapter instance for the receiver" do
          User.to_adapter.should be_a(OrmAdapter::Base)
          User.to_adapter.klass.should == User
        end
      end
    end
  end
end