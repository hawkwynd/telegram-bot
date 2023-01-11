require "geocoder"
require 'logger'
require 'httparty'
require 'json'
require 'base64'

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


listeners = getActiveListers 
listeners.each do |l| 
    puts "#{l[:ip]} #{l[:city]} #{l[:region]} #{l[:country]} - #{l[:useragent]}"
end



