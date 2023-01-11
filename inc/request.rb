def searchRequest( request )
    
    logger = Logger.new(STDOUT, Logger::DEBUG)
    requestUrl  = 'http://74.123.47.237/requester/telegram.php'

    options = {:body => {
        :source     => "telegram_bot",
        :title      => request
    }}

    response = HTTParty.post( requestUrl, options )

    return response.body  

end 


def submitRequest( id, userid )
    logger = Logger.new(STDOUT, Logger::DEBUG)
    options = {
        :body => {
            :source     => "telegram_bot",
            :lid        => id,
            :userid     => userid
        }
    }

    # get the filenampath from telegram-request.php
    requestUrl = 'http://74.123.47.237/requester/telegram-request.php'
    response = HTTParty.post( requestUrl, options )

    # TODO:: Validate our response!!!

    response.parsed_response

    jsonPayload = JSON.parse( response )

    # logger.info jsonPayload

    # validate our payload, error?

    if jsonPayload["error"].nil?

        # build the URL to soap_req for submitting the request with the filenamepath
        submitUrl = "http://74.123.47.237/requester/soap_req.php?act=req&que=#{jsonPayload['filenamepath']}"
        
        # logger.info "submitUrl = #{submitUrl}"
        # get the response from soap_req.php 
        
        submitResponse = HTTParty.get( submitUrl )
        submitResponse.parsed_response

        # logger.info "submitResponse: #{submitResponse.body}"

        return submitResponse.body
           
    
    end # error checker
    
end # def

def randomReaction() 
    return ["Pitooie!", "Welp!", "Oh Snap!", "Woah!", "Oh My...", "Uh-Oh!", "Dang!", "Silly Wabbit!", "Shit.", "Fuuuu...", "Cough-puke!"].sample
end
# Return a random insult string
def randomInsult()
 return ["Slapnut", "Twerp", "Dolt", "Butthead" ,"Beavis" , "Dweeb", "Zaphod", "Bilbo","Homer","Wanker","Zipper neck", "Spanky", "Turd", "Window licker" ].sample
end

# Return a random empty result
def randomResult()
    return ["nada", "zip", "zilch", "nothing", "a donut hole", "thin air", "an empty bag", "a deflated baloon", "a sorry sack of worthless gas", "a dead stick", "a can of whoopass"].sample
end

# get requests queue

def requestedQueue()

    jsonPayload = [nil]

    logger = Logger.new(STDOUT, Logger::DEBUG)
    options = {
        :body => {
            :source     => "telegram_bot",
            :command    => "requested.queue"
            }
    }

    # get the filenampath from telegram-request.php
    requestUrl  = 'http://74.123.47.237/command.php'
    response    = HTTParty.post( requestUrl, options )
    jsonPayload = JSON.parse( response.body )

    # empty queue
    if jsonPayload.length == 0
        return "Jarvis' requests queue is empty, as in #{randomResult}.\n\nUse /search (song title) to search songs for requesting!\n\nwww.hawkwynd.com"
    end   
    
    if !jsonPayload['response'].nil?
        req_count   = jsonPayload['response'].length
        req_list    = jsonPayload['response']
        messageList = req_list.join("\n")
        holder      = req_count == 1 ? 'request' : 'requests'
  
        return "<b>Jarvis currently has #{req_count} #{holder}:</b>\n\n#{messageList}\n\nwww.hawkwynd.com"
        
    end     

    return jsonPayload


end # requestedQueue()