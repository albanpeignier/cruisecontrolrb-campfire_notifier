require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../campfire_notifier'

module CruiseControl
  class Log
    def self.debug(message)
      true
    end
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
        assert_nil @campfire_notifier.connected?
      end
    end

    context "when account, token, and room are provided" do
      setup do
        @campfire_notifier.account = "account"
        @campfire_notifier.token = "token"
        @campfire_notifier.room = "Office"
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
          @successful_build = stub('Build', :successful? => true) 
        end

        should "notify of build outcome" do
          @campfire_notifier.expects(:notify_of_build_outcome).with(@successful_build, "SUCCESS")
          @campfire_notifier.build_finished(@successful_build)
        end

        context "and only_failed_builds is true" do
          setup do
            @campfire_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_finished(@successful_build)
          end
        end
      end

      context "on failed build" do
        setup do
          @failed_build = stub('Build') 
          @campfire_notifier.expects(:notify_of_build_outcome).with(@failed_build, "BROKEN")
        end

        should "notify of build outcome" do
          @campfire_notifier.build_failed(@failed_build, 
                                          previous_build = stub('Previous Build'))
        end
      end

      context "on fixed build" do
        setup do
          @fixed_build = stub('Build') 
          @campfire_notifier.expects(:notify_of_build_outcome).with(@fixed_build, "FIXED")
        end

        should "notify of build outcome" do
          @campfire_notifier.build_fixed(@fixed_build, 
                                         previous_build = stub('Previous Build'))
        end
      end
    end
  end
end
