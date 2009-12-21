require 'broach'

class CampfireNotifier
  attr_accessor :account, :password, :room, :trac_url, :broken_image, :fixed_image, :ssl, :only_failed_builds

  def initialize(project = nil)
    @account = nil
    @password = nil
    @room = nil
    @ssl = false
    @only_failed_builds = false
  end

  def enabled?
    @account && @password && @room
  end

  def connect
    return unless enabled?
             
    CruiseControl::Log.debug("Campfire notifier: connecting to campfire")
    Broach.settings = {'account' => @account, 
                               'token' => @password, 
                               'use_ssl' => @ssl}
    @client_room = Broach::Room.find_by_name(@room) 
  end

  def build_finished(build)
    if build.failed?
      notify_of_build_outcome(build)
    end
  end

  def build_fixed(fixed_build, previous_build)
    notify_of_build_outcome(fixed_build) unless @only_failed_builds
  end
  
  def trac_url_with_query revisions
    first_rev = revisions.first.number
    last_rev = revisions.last.number    
    "#{trac_url}?new=#{first_rev}&old=#{last_rev}"
  end
  
  def notify_of_build_outcome(build, previous_build = nil)
    return unless enabled?
    
    connect
      
    CruiseControl::Log.debug("Campfire notifier: sending notices")      
    
    log_parser = eval("#{build.project.source_control.class}::LogParser").new
    revisions = log_parser.parse( build.changeset.split("\n") ) rescue []
    committers = revisions.collect { |rev| rev.committed_by }.uniq
    
    title_parts = []
    title_parts << "#{committers.to_sentence}:" if committers and committers.length > 0
    title_parts << "Build #{build.label} of #{build.project.name} is"

    if build.failed?
      title_parts << "BROKEN"
      image = @broken_image
    elsif !@only_failed_builds
      title_parts << (previous_build ? "FIXED" : "SUCCESS")
      image = @fixed_image
    end
    
    urls = "#{build.url}" if Configuration.dashboard_url
    urls += " | #{trac_url_with_query(revisions)}" if trac_url
  
    @client_room.speak image if image
    @client_room.speak title_parts.join(' ')
    @client_room.paste( build.changeset )  
    @client_room.speak urls
  end
end

Project.plugin :campfire_notifier
