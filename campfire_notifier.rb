require 'broach'

class CampfireNotifier
  attr_accessor :account, :token, :room, :trac_url, :broken_image, :fixed_image, :ssl, :only_failed_builds

  def initialize(project = nil)
    @account = nil
    @token = nil
    @room = nil
    @ssl = false
    @only_failed_builds = false
  end

  alias_method :password=, :token=

  def enabled?
    @account && @token && @room
  end

  def connected?
    @client_room
  end

  def connect
    return unless enabled?
             
    CruiseControl::Log.debug("Campfire notifier: connecting to campfire")
    Broach.settings = {'account' => @account, 
                               'token' => @token, 
                               'use_ssl' => @ssl}
    @client_room = Broach::Room.find_by_name(@room) 
  end

  def build_finished(build)
    return if !build.successful?
    notify_of_build_outcome(build, "SUCCESS") unless @only_failed_builds
  end

  def build_failed(broken_build, previous_build)
    notify_of_build_outcome(broken_build, "BROKEN")
  end

  def build_fixed(fixed_build, previous_build)
    notify_of_build_outcome(fixed_build, "FIXED") unless @only_failed_builds
  end
  
  def trac_url_with_query revisions
    first_rev = revisions.first.number
    last_rev = revisions.last.number    
    "#{trac_url}?new=#{first_rev}&old=#{last_rev}"
  end

  def get_changest_committers(build)
    log_parser = eval("#{build.project.source_control.class}::LogParser").new
    revisions = log_parser.parse( build.changeset.split("\n") ) rescue []
    committers = revisions.collect { |rev| rev.committed_by }.uniq
    committers
  end
  
  def notify_of_build_outcome(build, message)
    return unless enabled?
    
    connect
      
    CruiseControl::Log.debug("Campfire notifier: sending notices")      
    
    committers = get_changeset_committers(build)

    title_parts = []
    title_parts << "#{committers.to_sentence}:" if committers and committers.length > 0
    title_parts << "Build #{build.label} of #{build.project.name} is"

    title_parts << message
    image = (message == "BROKEN" ? @broken_image : @fixed_image)
    
    urls = "#{build.url}" if Configuration.dashboard_url
    urls += " | #{trac_url_with_query(revisions)}" if trac_url
  
    @client_room.speak image if image
    @client_room.speak title_parts.join(' ')
    @client_room.paste( build.changeset )  
    @client_room.speak urls
  end
end

Project.plugin :campfire_notifier if ENV["ENV"] != "test"
