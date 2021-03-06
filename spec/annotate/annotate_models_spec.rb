require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'rubygems'
require 'activesupport'

describe AnnotateModels do
  
  before(:all) do
    require "tmpdir"
    @dir = Dir.tmpdir + "/#{Time.now.to_i}" + "/annotate_models"
    FileUtils.mkdir_p(@dir)
  end
  
  module ::ActiveRecord
     class Base
     end
   end
   
   def create(file, body="hi")
     File.open(@dir + '/' + file, "w") do |f|
       f.puts(body)
     end
     @dir + '/' + file
   end
   
  def mock_klass(stubs={})
     mock("Klass", stubs)
  end

  def mock_column(stubs={})
     mock("Column", stubs)
  end

  it { AnnotateModels.quote(nil).should eql("NULL") }
  it { AnnotateModels.quote(true).should eql("TRUE") }
  it { AnnotateModels.quote(false).should eql("FALSE") }
  it { AnnotateModels.quote(25).should eql("25") }
  it { AnnotateModels.quote(25.6).should eql("25.6") }
  it { AnnotateModels.quote(1e-20).should eql("1.0e-20") }
  
  describe "schema info" do

    before(:each) do
@schema_info =  <<-EOS
# Schema Info
#
# Table name: users
#
#  id   :integer         not null, primary key
#  name :string(50)      not null
#

EOS
        
        AnnotateModels.model_dir = @dir
        @user_file = create('user.rb', <<-EOS)
class User < ActiveRecord::Base
end
        EOS
      @mock = mock_klass(
        :connection => mock("Conn", :indexes => []),
        :table_name => "users",
        :primary_key => "id",
        :column_names => ["id","name"],
        :columns => [
          mock_column(:type => "integer", :default => nil, :null => false, :name => "id", :limit => nil),
          mock_column(:type => "string", :default => nil, :null => false, :name => "name", :limit => 50)
        ])
    end
 
    it "should get schema info" do
      AnnotateModels.get_schema_info(@mock , "Schema Info").should eql(@schema_info)
    end
  
    it "should write the schema before (default)" do
      AnnotateModels.stub!(:get_schema_info).and_return @schema_info
      AnnotateModels.do_annotations
      File.read(@user_file).should eql(<<-EOF)
# Schema Info
#
# Table name: users
#
#  id   :integer         not null, primary key
#  name :string(50)      not null
#

class User < ActiveRecord::Base
end
EOF
          
   end
   
   it "should write the schema after" do
     AnnotateModels.stub!(:get_schema_info).and_return @schema_info
     AnnotateModels.do_annotations(:position => :after)
     File.read(@user_file).should eql(<<-EOF)
class User < ActiveRecord::Base
end

# Schema Info
#
# Table name: users
#
#  id   :integer         not null, primary key
#  name :string(50)      not null
#

EOF

      end
 end
 
  describe "#get_model_class" do
 
     before :all do     
      create('foo.rb', <<-EOS)
        class Foo < ActiveRecord::Base
        end
      EOS
      create('foo_with_macro.rb', <<-EOS)
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
    end
    
    it "should work" do
      klass = AnnotateModels.get_model_class("foo.rb")
      klass.name.should == "Foo"
    end
    
    it "should not care about unknown macros" do
      klass = AnnotateModels.get_model_class("foo_with_macro.rb")
      klass.name.should == "FooWithMacro"
    end
    
  end

end
