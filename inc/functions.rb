# define global vars

$bands = ["Rush", "Cinderella", "Boston", "Saga", "Led Zeppelin", "Skid Row", "Styx", "Asia", "Genesis",
"Scorpions", "Yes", "Rainbow", "Outlaws", "Bad Company", "Kansas" , "Eagles", "Chicago",
"Cake","America","Jambros", "War", "Krokus","The Power Station","Yazoo", "Squeeze", "Traffic", "Queen", 
"Rare Earth", "Santana", "The Crusaders", "Bread", "Jethro Tull", "Uriah Heep", "Kiss", "Cream",
"Midnight star", "Steppenwolf", "Morphine" ]

def getActiveListers()
  url               = 'http://hawkwynd.com:8000/admin.cgi?sid=1&mode=viewjson&pass=scootre1'
  response          = HTTParty.get(url)
  parsedJson        = JSON.parse( response.body )
  output            = Array.new
  logger            = Logger.new(STDOUT, Logger::DEBUG)


  listeners = parsedJson["listeners"]

  # logger.debug( listeners )

  listeners.each do |listener|
      arr = Hash.new
          l = listener["useragent"].split('/')

          res = Geocoder.search( listener['hostname'] )

          arr[:ip] = res.first.ip 
          arr[:city] = res.first.city 
          arr[:region] = res.first.region 
          arr[:country] = res.first.country
          arr[:useragent] = l.first

          output.push(arr)
  end


return output

end


# Wikipedia API call to get an artist
def getArtistWiki( artist )

  logger          = Logger.new(STDOUT, Logger::DEBUG)
  output          = { "wiki_url" => nil, "title" => artist,  "excerpt" => nil }

  wp = "https://en.wikipedia.org/w/api.php?"
  aq = "action=query" 
  t = "&titles="
  p = "&prop=extracts&exintro&explaintext&exsentences=2"
  r = "&redirects&converttitles"
  f = "&format=json"
  
  # build querystring escape non-ascii characters
  # URI must be ascii only "https://en.wikipedia.org/w/api.php?action=query&titles=Bachman\u2013Turner+Overdrive&prop=extracts&exintro&explaintext&exsentences=2&redirects&converttitles&format=json" (URI::InvalidURIError)

  u  = URI::Parser.new
  url = "#{wp}#{aq}#{t}#{artist}#{p}#{r}#{f}"
  url = u.escape(url)

  output['wiki_url'] = url 

  response        = HTTParty.get( url )
  parsed_response = JSON.parse( response.body )
  
  if parsed_response.key?("query")
    
    pages = parsed_response['query']["pages"]
    key, value = pages.first

    # Validate we have a good result
    if key > "-1"
      output["title"]   = value["title"]
      output["excerpt"] = value["extract"]
    end 
  
  end
  
  return output

end


def delimit_num( num )
  return num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse 
end 


def is_num?(str)
  !!Integer(str)
rescue ArgumentError, TypeError
  false
end


# top10CountryListeners 
def top10CountryListeners() 
  payload         = Hash.new 

  # Keep stats Nerdly
  url = 'http://stream.hawkwynd.com/keep/index.php'

  options = { :body => 
                  {
                    :action => "top10CountryListeners",
                  }
          }

  top10CountryListeners = HTTParty.post(url, options)
  top10CountryListenersResults = JSON.parse( top10CountryListeners.body )

  return top10CountryListenersResults

end 

# Check how many requests made in last hour by userid
def doCheckRequests( userid )
  url = "http://stream.hawkwynd.com/keep/index.php"
  options = { :body => 
              {
                :action => "requestCheck",
                :userid  => userid
            }
  }
  
  telegramRequest = HTTParty.post(url, options)
  telegramResults = JSON.parse( telegramRequest.body )

  return telegramResults

end



# Caputure telegram requests/submissions for songs
def doTelegramRequest( payload )

  # puts payload
  url = 'http://stream.hawkwynd.com/keep/index.php'
  options = { :body => 
              {
                :action => payload['action'],
                :command => payload['command'],
                :request => payload['request'],
                :user    => payload['user'],
                :userid  => payload['userid']
            }
  }

  telegramRequest = HTTParty.post(url, options)
  telegramResults = JSON.parse( telegramRequest.body )

  return telegramResults
end



# statistical reporting
def statistical()

  lan = listenersActiveNow()
  lan_list = ""

  lan.each do |row|
    lan_list += "   #{row["country"]}: #{row['listener_count']}\n"
  end

  payload         = Hash.new 

  # Keep stats Nerdly
  url = 'http://stream.hawkwynd.com/keep/index.php'

  options = { :body => 
                  {
                    :action => "nerdly",
                  }
          }

  nerdlyResult = HTTParty.post(url, options)
  nerdlyJson = JSON.parse( nerdlyResult.body )
  
  statsUrl        = 'http://hawkwynd.com:8000/statistics?json=1'
  response        = HTTParty.get(statsUrl)
  parsedStatsJson      = JSON.parse( response.body )

  parsedStatsJson['streams'].each do |stream|
  
    if stream['id'] == 1

      # prepare formatting
      seconds = stream['averagetime'] % 60
      minutes = (stream['averagetime'] / 60) % 60
      hours = stream['averagetime'] / (60 * 60)

      payload['station'] = stream['servertitle']
      payload['Active_Listeners'] = "\n#{lan_list}"
      payload['Songs_Played_All_Time'] = delimit_num(nerdlyJson['recording']['track_count'])
      payload['Server_Uptime_Hours'] = stream['streamuptime']/3600
      payload['Peak_Listeners'] = stream['peaklisteners']
      
      payload['Known_Artists'] = delimit_num(nerdlyJson['artist']['artist_count'])
      payload['Known_Albums']  = delimit_num(nerdlyJson['releases']['releases_count'])
      payload['Known_Songs']   = delimit_num(nerdlyJson['known_tracks']['tracks_count'])
      payload['FlAC_Albums']   = delimit_num(nerdlyJson['flac']['flac_count'])
      payload['MP3_Albums']    = delimit_num(nerdlyJson['mp3']['mp3_count'])
      payload['First_Listener'] = nerdlyJson['listeners_total_count']['firstConnect']
      payload['Last_Listener'] = nerdlyJson['listeners_total_count']['lastConnect']
      payload['Total_Listeners_All_Time'] = delimit_num(nerdlyJson['listeners_total_count']['totalListeners'])
      
      payload['Avg_Listen_Time'] = format("%02d:%02d:%02d", hours, minutes, seconds) #=> "01:00:00"
      payload['Steam_Sample_Rate'] = stream['samplerate']
      payload['Stream_Bitrate'] = stream['bitrate']

    end

  end 
  
  return payload

end

def listenersActiveNow( )
  payload         = Hash.new 

  # Keep stats Nerdly
  url = 'http://stream.hawkwynd.com/keep/index.php'

  options = { :body => 
                  {
                    :action => "listenersActiveNow",
                  }
          }

  lResult     = HTTParty.post(url, options)
  lResultJSON = JSON.parse( lResult.body )

  return lResultJSON

end 


def getNowPlaying( payload = nil, excerpt = nil )
    
    require 'open-uri'

    limit           = 30 # except word limit 
    logger          = Logger.new(STDOUT, Logger::DEBUG)
    statsUrl        = 'http://hawkwynd.com:8000/statistics?json=1'
    response        = HTTParty.get(statsUrl)
    coverImg        = [nil]
    parsedJson      = JSON.parse( response.body )
    listenercount   = parsedJson['streams'][0]['currentlisteners']
    nowplaying      = parsedJson['streams'][0]['songtitle']
    artistTitle     = nowplaying.split(/ - /, 2)
    payload         = Hash.new 
    request         = false
    reqLabel        = ""
    
    # get artist-title info
    artist = artistTitle[0]
    title  = artistTitle[1]

    # strip [By Request] from title, 
    # only to add it back after we do lookupAT
    if title["[By Request]"] 
      title.slice! "[By Request]"
      reqLabel = "** By Request! **" 
    end 

    # Lookup our artist and title
    rel   = lookupAT( artist, title )
    
    # If we got nuthin' just return phoyo type message with default logo, artist, title and excerpt if available
    if rel['release'].nil?
      
      payload['type'] = "photo"
      payload['photo'] = "http://stream.hawkwynd.com/img/no_image.png"
      payload['text'] = "<b>Now playing on Hawkwynd Radio #{reqLabel}</b>:\n\n<b>#{artist} - #{title}</b>\n\n"
      
      if !rel['excerpt'].nil?
        payload['text'] += rel['excerpt'] 
      end 

      payload['text'] += "\n\n" + "www.hawkwynd.com"
      
      return payload 

    end 


    releaseInfo = rel['release']
    artistInfo  = rel['artist']
    excerpt     = rel['excerpt']

    # make sure lookupAT is not nil, because sometimes, it is.

        if !releaseInfo['id'].nil?
  
          # get the file format (mp3, flac, etc )
          coverinfo     = browseCovers( releaseInfo['id'] )
          attribute     = coverinfo['attribute']
          # get release_id
          # release_id = releaseInfo['id'] 
          
          # get release title
          release_title = releaseInfo['title']
          # get release year/label
          release_label = "#{releaseInfo['year']} on #{releaseInfo['label']}"

          if !coverinfo['coverImg'].nil?
            
            # build send_photo object add to payload
            payload['type']       = 'photo'
            payload['discogs_id'] = coverinfo['discogs_id']
            payload['photo']      = coverinfo['coverImg']
            payload['text'] = "<b>Now playing on Hawkwynd Radio #{reqLabel}</b>:\n\n#{artist} - #{title}\n" +
            "from <i>#{release_title}</i>\n#{release_label} - #{attribute}\n\n#{excerpt}\n\n" + "www.hawkwynd.com"
            
            return payload
          
          end # !coverinfo['coverImg'].nil?
          
          
        end #!releaseInfo['id'].nil?
        
        # message only, no photo (default)
        # puts "Default photo message line 142 because releaseInfo[id] is nil"

        # If all else fails, return default logo with artist, title  and shit. 

        payload['type'] = "photo"
        payload['photo'] = "http://stream.hawkwynd.com/img/no_image.png"
        payload['text'] = "\n<b>Now playing on Hawkwynd Radio #{reqLabel}</b>:\n\n<b>#{artist} - #{title}</b>\n" +
        "<i>#{release_title}</i>\n#{release_label} - #{attribute}" 
        
        if !excerpt.nil?
          payload['text'] +="\n\n#{excerpt}\n\n" + "www.hawkwynd.com"
        end 

       
        return payload 

end


def getQueue()
    logger = Logger.new(STDOUT, Logger::DEBUG)
    options = { :body => 
                  {
                    :source => "telegram_bot",
                    :command => "main.next"
                  }
          }
    
    begin
  
      response = HTTParty.post( "http://74.123.47.237/command.php", options )        
      response.parsed_response
      res = JSON.parse( response.body )
  
      rescue ArgumentError
        
        payload =  "Oh Snap!\n\nThere was some kind of anomoly that prevented me from getting the queue.\n\nTry again later.\n\nwww.hawkwynd.com"
        logger.debug response 
  
      else
        
        # turn me off after launch
        payload = res["response"].join("\n")
        
      ensure
  
        return "<b>Jarvis's Play queue:</b>\n\n#{payload}\n\n<a href='http://www.hawkwywnd.com'>www.hawkwynd.com</a>"
  
      end
  
  end


  # Get the current playing song information and display it

def lookupAT( a, t)
  
  logger              = Logger.new(STDOUT, Logger::DEBUG)
  payload             = Hash.new
  payload['artist']   = a
  payload['title']    = t
  watch               = ['+', "&"]
  
  # Remove non-alphabetical chrs
  # a.gsub(/[^0-9a-z ]/i, '')

  if a == "Hawkwynd Radio" 
    return payload
  end 

  # array of bands that have to have (band) added to Wikipedia query in order to get the right results:
  # @TODO: Move this to a key => pair table for quick loading. 


  # swap certain characters for wiki search url so it works on WikiPedia (Florence + The Machine -> Florence and The Machine)
  watch.each do |letter|
    a.gsub( letter , "and")
  end 
  
  # urlencode multi-word artist names
  artist = a.split(" ").join("+") # Lynrd Skynryd becomes Lynrd+Skynrd 
  
  # If we have a band match in the array of bands, add (band) to the query
  if !$bands.grep(/^#{a}/).empty? 
    artist = a.split(" ").join("+") + " (band)"
  end
  
  # call our wiki for the artist
  if !artist.nil?
    aWiki = getArtistWiki( artist )
  end 


  payload['excerpt']  = aWiki['excerpt'] if !aWiki['excerpt'].nil?

  # build options array for lookup
  options = { :body => 
                {
                  :action => "lookupAT",
                  :artist => a,
                  :title  => t
                }
            }
    
  response = HTTParty.post( "http://stream.hawkwynd.com/keep/index.php", options )
  res      = JSON.parse( response.body )


 if !res['release']['id'].nil? 
  payload['release']  = res['release']
 end

 return payload

end


# Get release info from discogs_id release 
def discogsRelease( discogs_id )

  secret        = "MGSKueXgidqwXOxbmmtSOGfUoFHtXdfC"
  key           = "jaRkJhfCzjSmakRoGyjP"
  dUrl          = "https://api.discogs.com/releases/#{discogs_id}?secret=#{secret}&key=#{key}"
  logger        = Logger.new(STDOUT, Logger::DEBUG)
  response      = HTTParty.get( dUrl )
  jsonResponse  = JSON.parse( response.body ) if response.body 

  jsonResponse['images'].each do |row|
    # Get the primary image type 
    case row['type']
      when '/primary/i'
        photo_url = row['resource_url']
    end 
  end

  # Return the first images element url 
  return jsonResponse['images'][0]['resource_url']

end 

# BrowseCovers 

def browseCovers(release_id)
    logger = Logger.new(STDOUT, Logger::DEBUG)
    options = { :body => 
              { 
                :action => 'browseCovers',
                :release_id => release_id 
              }
            }
  
    response = HTTParty.post( "http://stream.hawkwynd.com/keep/index.php", options )
    
    if response 
      response.parsed_response
      res = JSON.parse( response.body )
      
      release = res["release"][0]
  
      release['coverImg'] = discogsRelease( release['discogs_id'] ) if release['discogs_id']
      
      return release
      
    else 
  
      return "\nSorry, I dropped my brain, gimme a minute to find it.\n"
      
    end 
    
  end

  # History of plays on Hawkwynd Radio

  def getHistory()
        
        histUrl         = 'http://stream.hawkwynd.com/history.php'
        response        = HTTParty.get(histUrl)
        parsedJson      = JSON.parse( response.body ) 
        historyStr         = "\n<b>Last hour's played music:</b>\n\n" + parsedJson.join("\n") + 
        "\n\n<a href='http://www.hawkwynd.com'>www.hawkwynd.com</a>"
        
        return historyStr 

  end 
