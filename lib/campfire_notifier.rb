require 'broach'

unless defined?(BuilderPlugin)
  # Define a dummy Plugin class if not already available
  # This allows for compatibility with very old cc.rb 1.4 deployments
  class BuilderPlugin
  end
end

class CampfireNotifier < BuilderPlugin
  attr_accessor :account, :token, :room, :trac_url, :broken_image, :fixed_image
  attr_accessor :ssl, :only_failed_builds, :only_fixed_and_broken_builds, :only_first_failure

  def initialize(project=nil)
    @account = nil
    @token = nil
    @room = nil
    @ssl = false
    @only_failed_builds = false
    @only_fixed_and_broken_builds = false
    @only_first_failure = false
  end

  alias_method :password=, :token=

  def enabled?
    account && token && room
  end

  def connect
    return unless self.enabled?

    CruiseControl::Log.debug("Campfire notifier: connecting to campfire")
    Broach.settings = {
      'account' => account,
      'token' => token,
      'use_ssl' => ssl
    }
    return Broach::Room.find_by_name(room)
  end

  def build_finished(build)
    return if only_fixed_and_broken_builds
    if build.successful?
      notify_of_build_outcome(build, "PASSED") unless only_failed_builds
    else
      notify_of_build_outcome(build, "FAILED!") unless only_first_failure
    end
  end

  def build_broken(broken_build, previous_build)
    notify_of_build_outcome(broken_build, "BROKE!") if only_first_failure || only_fixed_and_broken_builds
  end

  def build_fixed(fixed_build, previous_build)
    notify_of_build_outcome(fixed_build, "WAS FIXED") if only_fixed_and_broken_builds
  end

  def trac_url_with_query(revisions)
    first_rev = revisions.first.number
    last_rev = revisions.last.number
    "#{trac_url}?new=#{first_rev}&old=#{last_rev}"
  end

  def get_changeset_committers(build)
    log_parser = eval("#{build.project.source_control.class}::LogParser").new
    revisions = log_parser.parse( build.changeset.split("\n") ) rescue []
    committers = revisions.collect { |rev| rev.committed_by }.uniq
    committers
  end

  def notify_of_build_outcome(build, message)
    return unless self.enabled?

    begin
      client_room = self.connect
    rescue Broach::AuthenticationError => e
      raise "Campfire Connection Error: #{e.message}"
    end

    CruiseControl::Log.debug("Campfire notifier: sending notices")

    committers = self.get_changeset_committers(build) || []

    title_parts = []
    title_parts << "#{committers.to_sentence}:" if committers.any?
    title_parts << "Build #{build.label} of #{build.project.name}"

    title_parts << message
    image = (message == "BROKEN" ? broken_image : fixed_image)

    urls = []
    urls << build.url if Configuration.dashboard_url
    urls << trac_url_with_query(revisions) if trac_url

    client_room.speak(image) if image
    client_room.speak(title_parts.join(' '))
    client_room.paste(build.changeset)
    client_room.speak(urls.join(" | ")) if urls.any?
  end
end

Project.plugin :campfire_notifier if ENV["ENV"] != "test"
