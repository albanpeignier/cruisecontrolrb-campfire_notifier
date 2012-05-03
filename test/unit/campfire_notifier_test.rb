require 'test_helper'
require 'campfire_notifier'

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
        assert_equal false, @campfire_notifier.only_fixed_and_broken_builds
        assert_equal false, @campfire_notifier.only_first_failure
      end

      should "not be enabled" do
        assert_nil @campfire_notifier.enabled?
      end

      should "not be able to connect" do
        @campfire_notifier.connect
        Broach.expects(:settings=).never
      end
    end

    context "when campfire account information is invalid" do
      setup do
        @campfire_notifier.account = "account"
        @campfire_notifier.token = "badtoken"
        @campfire_notifier.room = "room"

        @campfire_notifier.expects(:connect).raises(
          Broach::AuthenticationError,
          'Campfire Connection Error: x'
        )
      end

      should "show error message" do
        assert_raise RuntimeError do
          @campfire_notifier.notify_of_build_outcome(nil, nil)
        end
      end
    end

    context "when account, token, and room are provided" do
      setup do
        @campfire_notifier.account = "account"
        @campfire_notifier.token = "token"
        @campfire_notifier.room = "Office"
        @campfire_notifier.broken_image = "broken image"
        @campfire_notifier.fixed_image = "fixed image"

        test_url = 'http://cruisecontrolrb.org/project/test_project'
        @build = stub('Build', :successful? => false, :label => "abcdef",
                              :project => stub(
                                'Project', :name => "Test Project"),
                              :changeset => "test changeset",
                              :url => test_url)
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
          @campfire_notifier.expects(:notify_of_build_outcome).with(
            @build, "PASSED"
          )
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

        context "and only_first_failure is true" do
          setup do
            @campfire_notifier.only_first_failure = true
          end

          should "notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).with(
              @build, "PASSED"
            )
            @campfire_notifier.build_finished(@build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @campfire_notifier.only_fixed_and_broken_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_finished(@build)
          end
        end

      end

      context "on failed build" do
        setup do
          @build.stubs(:successful?).returns(false)
        end

        should "notify of build outcome" do
          @campfire_notifier.expects(:notify_of_build_outcome).with(
            @build, "FAILED!"
          )
          @campfire_notifier.build_finished(@build)
        end

        context "and only_failed_builds is true" do
          setup do
            @campfire_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).with(
              @build,"FAILED!"
            )
            @campfire_notifier.build_finished(@build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @campfire_notifier.only_first_failure = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_finished(@build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @campfire_notifier.only_fixed_and_broken_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_finished(@build)
          end
        end

      end


      context "on broken build (when previous build was success)" do
        setup do
          @previous_build = stub('Previous Build')
        end

        should "not notify of build outcome" do
          @campfire_notifier.expects(:notify_of_build_outcome).never
          @campfire_notifier.build_broken(@build,@previous_build)
        end

        context "and only_failed_builds is true" do
          setup do
            @campfire_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_broken(@build,@previous_build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @campfire_notifier.only_first_failure = true
          end

          should "notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).with(
              @build, "BROKE!"
            )
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_broken(@build,@previous_build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @campfire_notifier.only_fixed_and_broken_builds = true
          end

          should "notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).with(
              @build, "BROKE!"
            )
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_broken(@build,@previous_build)
          end
        end

      end

      context "on fixed build (when previous build was broken)" do
        setup do
          @previous_build = stub('Previous Build')
        end

        should "not notify of build outcome" do
          @campfire_notifier.expects(:notify_of_build_outcome).never
          @campfire_notifier.build_fixed(@build,@previous_build)
        end

        context "and only_failed_builds is true" do
          setup do
            @campfire_notifier.only_failed_builds = true
          end
          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_fixed(@build,@previous_build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @campfire_notifier.only_first_failure = true
          end

          should "not notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_fixed(@build,@previous_build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @campfire_notifier.only_fixed_and_broken_builds = true
          end

          should "notify of build outcome" do
            @campfire_notifier.expects(:notify_of_build_outcome).with(
              @build, "WAS FIXED"
            )
            @campfire_notifier.expects(:notify_of_build_outcome).never
            @campfire_notifier.build_fixed(@build,@previous_build)
          end
        end

      end

      context "and trac url provided" do
        setup do
          @campfire_notifier.trac_url = 'http://temptracuri.org'
          @revisions = stub(
            'Revisions',
            :first => stub('first', :number => '123'),
            :last => stub('last', :number => '234')
          )
        end

        should "return trac url with query" do
          url = @campfire_notifier.trac_url_with_query(@revisions)
          assert_equal "http://temptracuri.org?new=123&old=234", url
        end
      end

      context "and changeset exists" do
        setup do
          changeset = <<-TXT
Build was manually requested.
Revision ...a124eaf committed by John Smith  <jsmith@company.com> on 2009-12-20 09:58:14

    made change

app/controllers/application_controller.rb |    4 ++--
1 files changed, 2 insertions(+), 2 deletions(-)
TXT
          @build = stub(
            'Build',
            :changeset => changeset, :project => stub(
              'Project', :source_control => stub(
                'source control', :class => 'SourceControl')))
        end

        should "return changeset committers" do
          committers = @campfire_notifier.get_changeset_committers(@build)
          assert_equal ["committerabc"], committers
        end
      end

      should "show build label, image, project name, and message in campfire" do
        office_room = stub('Room', :name => 'Office')
        @campfire_notifier.stubs(:connect).returns(office_room)
        @campfire_notifier.stubs(:get_changeset_committers).returns([])
        office_room.expects(:speak).with("fixed image")
        office_room.expects(:speak).with(
          "Build abcdef of Test Project SUCCESSFUL"
        )
        office_room.expects(:paste).with(@build.changeset)
        office_room.expects(:speak).with(
          'http://cruisecontrolrb.org/project/test_project'
        )

        @campfire_notifier.notify_of_build_outcome(@build, "SUCCESSFUL")
      end
    end
  end
end
