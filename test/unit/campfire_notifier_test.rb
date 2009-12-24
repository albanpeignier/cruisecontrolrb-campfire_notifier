require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../campfire_notifier'

module CruiseControl
  class Log
    def self.debug(message)
      true
    end
  end
end

class Configuration
  def self.dashboard_url
    "http://tempuri.org"
  end
end

class CampfireNotifierTest < Test::Unit::TestCase
  context "Campfire Notifier" do
    setup do
      @campfire_notifier = CampfireNotifier.new
    end

    context "when created" do
      should "have no initialized properties" do
        assert_nil @campfire_notifier.account
        assert_nil @campfire_notifier.token
        assert_nil @campfire_notifier.room
        assert_equal false, @campfire_notifier.ssl
        assert_equal false, @campfire_notifier.only_failed_builds
      end

      should "not be enabled" do
        assert_nil @campfire_notifier.enabled?
      end

      should "not be able to connect" do
        @campfire_notifier.connect
        Broach.expects(:settings=).never
      end
    end

    context "when account, token, and room are provided" do
      setup do
        @campfire_notifier.account = "account"
        @campfire_notifier.token = "token"
        @campfire_notifier.room = "Office"
        @campfire_notifier.broken_image = "broken image"
        @campfire_notifier.fixed_image = "fixed image"
        
        @build = stub('Build', :successful? => false, :label => "abcdef",
                              :project => stub('Project', :name => "Test Project"),
                              :changeset => "test changeset",
                              :url => 'http://cruisecontrolrb.org/project/test_project') 
      end

      should "be enabled" do
        assert_not_nil @campfire_notifier.enabled?
      end

      should "be able to connect" do
        office_room = stub('Room', :name => 'Office')
        business_room = stub('Room', :name => 'Business')
        Broach::Room.stubs(:all).returns([office_room, business_room])
        
        settings = {'account' => @campfire_notifier.account,
                    'token' => @campfire_notifier.token,
                    'use_ssl' => false}
        Broach.expects(:settings=).with(settings)
        
        client_room = @campfire_notifier.connect
        assert_equal 'Office', client_room.name
      end

      context "on successful build" do
        setup do
          @build.stubs(:successful?).returns(true)
        end

        should "notify of build outcome" do
          @campfire_notifier.expects(:notify_of_build_outcome).with(@build, "SUCCESS")
          @campfire_notifier.build_finished(@build)
        end

        context "and only_failed_builds is true" do
          setup do
            @campfire_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_finished(@build)
          end
        end
      end

      context "on failed build" do
        setup do
          @campfire_notifier.expects(:notify_of_build_outcome).with(@build, "BROKEN")
        end

        should "notify of build outcome" do
          @campfire_notifier.build_failed(@build, 
                                          previous_build = stub('Previous Build'))
        end
      end

      context "on fixed build" do
        setup do
          @campfire_notifier.expects(:notify_of_build_outcome).with(@build, "FIXED")
        end

        should "notify of build outcome" do
          @campfire_notifier.build_fixed(@build, 
                                         previous_build = stub('Previous Build'))
        end
      end

      should "show the build label, image, project name, and message in campfire" do
        office_room = stub('Room', :name => 'Office')
        @campfire_notifier.stubs(:connect).returns(office_room)
        @campfire_notifier.stubs(:get_changeset_committers).returns([])
        office_room.expects(:speak).with("fixed image")
        office_room.expects(:speak).with("Build abcdef of Test Project is SUCCESSFUL")
        office_room.expects(:paste).with(@build.changeset)
        office_room.expects(:speak).with('http://cruisecontrolrb.org/project/test_project')

        @campfire_notifier.notify_of_build_outcome(@build, "SUCCESSFUL")
      end
    end
  end
end
