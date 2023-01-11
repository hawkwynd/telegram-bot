
require 'telegram/bot'
require 'logger'
require 'httparty'
require 'json'
require 'base64'
require './inc/request.rb'
require './inc/functions.rb'
require 'resolv-replace'
require "geocoder"

logger      = Logger.new(STDOUT, Logger::DEBUG)
token       = '2003421830:AAGaixiVXuk1UNLsjwLS0QllM13jUFUv7N8'
groupID     = '2003421830'

# 2003421830:AAGaixiVXuk1UNLsjwLS0QllM13jUFUv7N8
# use the link below to force updates if bot crashes... 
# resetBoturl = "https://api.telegram.org/bot2003421830:AAGaixiVXuk1UNLsjwLS0QllM13jUFUv7N8/getUpdates?offset=-1"

# Disable ipv6 in net config to prevent errors on timeout
# /etc/sysctl.conf 
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1


Telegram::Bot::Client.run(token) do |bot|


  # get updates to clear issues
  bot.api.getUpdates(limit: 1,timeout: 80 )
  
  bot.listen do |message|
    
    
    # check is_bot - true next 
    next if message.from.is_bot.nil?

    case message
    
    when Telegram::Bot::Types::Message

    case message.text 

    # active listener list
    when /\A\/listeners/i 
      
      listeners = getActiveListers()
      content = "<b>Hawkwynd Radio #{listeners.count} Active Listeners</b>\n[City, Region, Country - Agent]\n\n"

      listeners.each do |l| 
          content += "#{l[:city]}, #{l[:region]}, #{l[:country]} - #{l[:useragent]}\n"
      end

      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
      
      bot.api.send_message(
        chat_id: message.chat.id,
        parse_mode: "HTML",
        text: content += "\nwww.hawkwynd.com"
      )


    #top10 listners by country
    when /\A\/top10/i 
      payload = top10CountryListeners()
      content = "<b>Hawkwynd Radio Top 10 Listeners By Country</b>\n\n"

      payload.each do |row |
        count = delimit_num(row['listeners'])
        content += "#{row['name']}: #{count}\n"
      end 

      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
      
      bot.api.send_message(
        chat_id: message.chat.id,
        parse_mode: "HTML",
        text: content += "\nwww.hawkwynd.com"
      )

      # Statisical
    when /\A\/stats/i

      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
      
      payload = statistical()
      content = "#{payload['station']} Stats: \n\n"

      payload.each do |k,v|
        next if k == 'station'

        pretty = k.gsub("_"," ")

        content += "#{pretty} : #{v}\n"

      end

      bot.api.send_message(
                chat_id: message.chat.id,
                parse_mode: "HTML",
                text: content += "\n\nwww.hawkwynd.com"
      )

    # Show the current playing song
    when /\A\/playing/i

      # show we're busy in status...
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      playResult = getNowPlaying()
      
      # Keep going, there's no one home playResult came back nil
      next if playResult.nil?
      
      if playResult['type'] == "message" || playResult['type'].nil?

        bot.api.send_message(
                chat_id: message.chat.id,
                parse_mode: "HTML",
                text: playResult['text']
              )
      # exit
      end 

      if playResult['type'] == "photo"


        # logger.info ( playResult )
        bot.api.send_photo(
          chat_id: message.chat.id,
          parse_mode: 'HTML',
          photo: playResult['photo'],
          caption: playResult['text']
        )
      # exit 

      end
      
      # Display Jarvis' queue of coming songs 
      when /\A\/queue/i
      # show we're busy in status...
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      queue = getQueue() 
      bot.api.send_message(
        chat_id: message.chat.id,
        parse_mode: "HTML",
        disable_web_page_preview: true,
        text: queue
      )

      # Display history of songs played last hour 
      when /\A\/history/i
      # show we're busy in status...
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
      
      history = getHistory()
      bot.api.send_message(
        chat_id: message.chat.id,
        parse_mode: "HTML",
        disable_web_page_preview: true,
        text: history
      )

      # Display list of requests in requested.queue 

      when /\A\/requests/i
      
      # show we're busy in status...
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
      
      requests = requestedQueue() 
      
      if requests['message']
        requests = "I <i>think</i> it's an empty queue, but if you ask again I can double-check on that, #{message.from.first_name}.\n"
      end 
      
      bot.api.send_message(
        chat_id: message.chat.id,
        parse_mode: "HTML",
        text: requests
      )

      # Display instructions for listening to HR 
      when /\A\/listen/i 

      # show we're busy in status...
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      bot.api.send_message(
        chat_id: message.chat.id, 
        disable_web_page_preview: true,
        parse_mode: "markdown",
        text: "There's many ways to listen to Hawkwynd Radio!\n\n" + 
        "1. [Visit Our Website](https://www.hawkwynd.com)\n"+ 
        "2. Streaming clients (VLC, Winamp, Kodi)\n" +
        "Stream source: http://hawkwynd.com:8000/listen.pls?sid=1\n\n"+
        "Jarvis is your virtual DJ, 24/7/365 so you're welcome to tune in and listen anytime!"
      )


      when /\A\/help/i 
      
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      bot.api.send_message(chat_id:message.chat.id, parse_mode:"HTML", 
      text: "Yeah, there's nothing here yet. You're on your own #{message.from.first_name}."
      )


      when /\A\/start/i 
      
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      bot.api.send_message(chat_id:message.chat.id, parse_mode:"HTML", disable_web_page_preview: true, 
      text: "<b>Welcome #{message.from.first_name}</b>\nI'm JarBot, your virtual assistant for interacting with Jarvis on Hawkwynd Radio.\n\n" +
      "Please report any strangeness to the <a href='https://t.me/hawkwyndRadio'>Hawkwynd Radio Group</a>. "
      )

    
      # user entered /search {text options}
      when /\A\/search/i

      # change bot status "typing..."
      bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

      # remove /search from messaage.text
      message.text["/search"] = ""
      message.text.strip!
      
      
      # user only entered /search and hit {return}
      if message.text.length == 0 
        kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
        bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: "<b>Please provide a <i>title</i> with your search,</b>.\n\nExample \/search <i>Stairway to heaven</i>\n")
        next
      end
      
      payload             = Hash.new 
      payload['action']   = "telegram"
      payload['command']  = "search"
      payload['user']     = message.from.first_name 
      payload['userid']   = message.from.id 
      payload['request']  = message.text 
      
      # capture event in telegram table
      requestResult     = doTelegramRequest( payload )

      requestLimit      = 3 # number of requests per hour allowed
      requestsResponse  = doCheckRequests( message.from.id )
      requestsMade      = requestsResponse['requests']
      requestsRemaining = requestLimit.to_i - requestsMade.to_i

      logger.info( "#{message.from.first_name} (#{message.from.id}) searched for `#{message.text} and has #{requestsRemaining} requests remaining." )

      # perform search result
      result = searchRequest( message.text ) 

      if result.empty? 
          bot.api.send_message(
            chat_id: message.chat.id,
            parse_mode: "HTML", 
            text: "<b>#{randomReaction} My search for</b> '<i>#{message.text}</i>' <b>returned #{randomResult()}.</b>\n\n<i>Hint</i>: I can do partial matches, try using just the <b>first two or three</b> words of the title.\n")
        next
      end 

      jsonResponse = JSON.parse(result)
      
        if jsonResponse["count"].to_i > 0
            
            # iterate data and log it
            # jsonResponse["data"].each do |row| 
            
            replyCount =  "<b>I have #{jsonResponse["count"]} matches for </b><i>#{message.text}</i>.\nYou have #{requestsRemaining} requests remaining for this hour.\nSelect the link in the results below to issue your request."
            bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: replyCount )

            # logger.info "query: #{message.text} - #{jsonResponse["count"]} matches."

            search_query = message.text 
            choose       = []
            
            jsonResponse["data"].each do |row|
              
              # [12345] The Speed of Love by Rush
              genre     = row['genre'].nil? ? "NA" : row['genre']
              playtime  = row['playtime'].nil? ? "NA" : row['playtime']
              year      = row['year'].nil? ? "NA" : row['year']
              audio     = row['audio'].nil? ? "NA" : row['audio']
              album     = row['album'].nil? ? "NA" : row['album']
              track     = row['track'].nil? ? "NA" : row['track']

               choice =  row["id"] + "\n<b>Title:</b> " + row['title'] + "\n<b>Artist:</b> " + row['artist'] + "\n<b>Release:</b> " + 
               album + "\n" + "<b>Track:</b> " + track + "\n" +
               "<b>Year:</b> " + year + "\n<b>Genre:</b> " + genre + "\n<b>Format:</b> " + audio + "\n<b>Time:</b> " +  playtime
            
              #  fire the weapon!
               bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: "/req_#{choice}")

            end 
            
            
          else 
            
            # kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            bot.api.send_message(chat_id: message.chat.id,parse_mode: "HTML", text: "<b>My search for</b> '<i>#{message.text}</i>' <b>returned #{randomResult()}.</b>\n\n<i>Hint</i>: I can do partial matches, try using just the <b>first two or three</b> words of the title.\n")
            
            
          end # if count > 0 
        # end

   

      when /\A\/req_/i

      requestLimit      = 3 # number of requests per hour allowed
      requestsResponse  = doCheckRequests( message.from.id )
      requestsMade      = requestsResponse['requests']

      # if requestsMade is greater than 3 
      if requestsMade.to_i >= requestLimit.to_i 
        
        bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )
        bot.api.send_message( chat_id:message.chat.id, parse_mode:"HTML", 
        
        text: "#{randomReaction} Sorry #{message.from.first_name}, You've made #{requestsMade} requests this hour.\nIn fairness to our listeners, JarBot limits requests per user to 3 per hour. <b>Please try again in an hour</b>.\n")

        logger.info( "#{message.from.first_name} was denied a request, because of #{requestsMade} requests already made." )

        next

      end


      # -----------------------FIRE THE REQUEST TO JARVIS ------------------------------
      # get the request_id from message.text 
      # check to make sure it's not already requested in the last hour
      # only allow a number after the slash for request submissions 
      
      unless message.text.nil?
        
        bot.api.sendChatAction( chat_id:message.chat.id, action: 'typing' )

        # if there is any text after the slash, get it
        logger.info "#{message.from.first_name} issued #{message.text}"

        # pull out numbers only
        request_id = message.text.split(/[^\d]/).join
        request_id.to_i 
      
        # a blank message with no request id, like "Hello? or other shit"
        if request_id.empty?
          logger.info "**#{request_id} no request_id after validation - next!!! **"
          bot.api.send_message( chat_id:message.chat.id, parse_mode:"HTML", text: "<b>Invalid command</b>, #{randomInsult}. Don't do that again. Got it?" )
          next 
        end 
        
        if !!is_num?(message.text) 
          logger.debug "#{message.text} is not a number!"
          next
        else
          
            # Build payload to update keep db
            # Soon, we'll build a throttle function 
            # So users can't make a shitload of requests and ruin it for everyone.

            payload             = Hash.new 
            payload['action']   = "telegram"
            payload['command']  = "request"
            payload['user']     = message.from.first_name 
            payload['userid']   = message.from.id 
            payload['request']  = message.text 
      
            # capture event in telegram table
            requestResult = doTelegramRequest( payload )

            # fire the request to soapbox
            submit_id = submitRequest( request_id, message.from.id )
            # submit_id.to_i 

            # logger.info "submitRequest response"
            logger.info "submit_id #{submit_id.to_i} issued by #{message.from.first_name} (#{message.from.id}) [#{requestResult}]"

          end
       
          # If we got a valid submit_id returned, announce it.
          if !submit_id.nil?
            submit_id.to_i 

            contentMsg = "<b>Request ID #{request_id} accepted!</b>\nYour queue ID is #{submit_id.to_i}.\n" + 
            "Thanks #{message.from.first_name}, and enjoy the awesome music!";
            
            # Send acknowlegement of request with queue list
            bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: contentMsg.concat("\n\n").concat( requestedQueue() ) )
          
          else
            # Drop the mic and run. What if the user entered /1230928283923 and it's invalid?

            failMsg = "<b>Bad Command!!!  ( #{request_id} ) is #{randomResult}.</b>\nSorry, #{randomInsult()}, somethings just aren't meant to be."
            bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: failMsg ) 

          end

        else 
        
        # Do nothing here, just send a slapnut.
        bot.api.send_message(chat_id: message.chat.id, parse_mode: "HTML", text: "<b>Use <i>/search</i> song title   </b>")
      
      end #if request_id 

    end #when loop

  end #bot message loop

  end #bot do loop

end # end case message

