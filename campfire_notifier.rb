class CampfireNotifier
  attr_accessor :subdomain, :username, :password, :room, :trac_url, :broken_image, :fixed_image

  def initialize(project = nil)
    @subdomain = nil
    @username = nil
    @password = nil
    @room = nil
  end

  def enabled?
    subdomain && username && password && room
  end

  def connect
    
    return unless enabled?
             
    CruiseControl::Log.debug("Campfire notifier: connecting to #{@subdomain}.campfirenow.com")
    
    @client = Tinder::Campfire.new @subdomain
    @client.login @username, @password
    
    @client_room = @client.find_room_by_name(@room)
    @client_room.join  
  end

  def disconnect
    
    return unless enabled?
    
    CruiseControl::Log.debug("Campfire notifier: disconnecting from #{@subdomain}.campfirenow.com")
    @client.logout if @client.respond_to?(:logged_in?) && @client.logged_in?
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
    notify_of_build_outcome(fixed_build)
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
      
      revisions       = ChangesetLogParser.new.parse_log( build.changeset.split("\n") )    
      committed_by    = revisions.collect { |rev| rev.committed_by }.uniq.to_sentence
    
      if build.failed?
        title = "#{committed_by.capitalize} BROKE #{build.project.name}/#{build.label}. Bad #{committed_by}!!"
        image = broken_image
      else
        title = "#{committed_by.capitalize} FIXED #{build.project.name}/#{build.label}. All hail #{committed_by}!!"
        image = fixed_image
      end
          
      urls  =  "#{build.url}"                         if Configuration.dashboard_url
      urls +=  " | #{trac_url_with_query(revisions)}" if trac_url
    
      @client_room.speak image if image
      @client_room.speak title
      @client_room.paste( build.changeset )  
      @client_room.speak urls
    
    ensure
      disconnect rescue nil
    end
    
  end

end
