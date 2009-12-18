require 'broach'

class CampfireNotifier
  attr_accessor :subdomain, :username, :password, :room, :trac_url, :broken_image, :fixed_image, :ssl, :only_failed_builds

  def initialize(project = nil)
    @username = nil
    @password = nil
    @room = nil
    @ssl = false
    @only_failed_builds = false
  end

  def enabled?
    subdomain && username && password && room
  end

  def connect
    
    return unless enabled?
             
    CruiseControl::Log.debug("Campfire notifier: connecting to campfire")
    
    Broach.settings {:account => @username, 
                               :token => @password, 
                               :use_ssl => @ssl}
    @client_room = Broach::Room.find_by_name(@room) 
  end

  def disconnect
    
    return unless enabled?
    
    CruiseControl::Log.debug("Campfire notifier: disconnecting from campfire")
  end

  def reconnect
    disconnect
    connect
  end

  def connected?
    @client.respond_to?(:logged_in?) && @client.logged_in?
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
    last_rev  = revisions.last.number    
    "#{trac_url}?new=#{first_rev}&old=#{last_rev}"
  end
  
  def notify_of_build_outcome(build)
    
    return unless enabled?
    
    connect
    begin
      
      CruiseControl::Log.debug("Campfire notifier: sending notices")      
      
      log_parser      = eval("#{build.project.source_control.class}::LogParser").new
      revisions       = log_parser.parse( build.changeset.split("\n") ) rescue []

      committers      = revisions.collect { |rev| rev.committed_by }.uniq
      
      title_parts = []
      title_parts << "#{committers.to_sentence}:" if committers
      title_parts << "#{build.project.name}/#{build.label} is"

      if build.failed?
        title_parts << "BROKEN"
        image = broken_image
      end
      
      unless @only_failed_builds
        title_parts << "FIXED"
        image = fixed_image
      end
          
      urls  =  "#{build.url}"                         if Configuration.dashboard_url
      urls +=  " | #{trac_url_with_query(revisions)}" if trac_url
    
      @client_room.speak image if image
      @client_room.speak title_parts.join(' ')
      @client_room.paste( build.changeset )  
      @client_room.speak urls
    
    ensure
      disconnect rescue nil
    end
    
  end

end

Project.plugin :campfire_notifier
