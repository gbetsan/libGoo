#require 'hackex' #Optional, dont use that
require 'libGoo'  #Requiring libGoo
include LibGoo    #Including libGoo into your script
email = 'your@e.mail'
password = 'password'

user = User.new(email, password)
#user = User.new(nil, nil, 'YOUR_AUTH_TOKEN_HERE') #Loggining by auth token

#Methods names as in hackex/request.rb, but you can also use old methods names or translate old ones to new ones by OLD_TO_NEW
puts LibGoo::OLD_TO_NEW['getUserProcesses'.to_sym]  #=>UserProcesses
puts LibGoo::NEW_TO_OLD['UserProcesses']            #=>getUserProcesses
puts JSON.pretty_generate OLD_TO_NEW                #Prints out methods names
#puts JSON.pretty_generate user.VictimInfo(590331)
#puts JSON.pretty_generate user.user
puts user.auth_token                                #=>B13C1313-1313-A13D-13E1-ACB13F131B13 #example
victim = Victim.new('user_id' => 590331)
LibGooHelper.MassScanner(user.auth_token, [1001, 1005]) do |user|  #Scans users with id's 1001 to 1004 and prints out his usernames
  puts user['user']['username']  #=>Nardski
end
User.Do(email, password) do |http, auth_token, user_info, user|
  puts user.user == user_info                       #=>true
  puts JSON.pretty_generate user.VictimInfo(victim)['user']
  puts user.http == http                            #=>true
  puts auth_token == user.auth_token                #=>true
  puts LibGooHelper.AnonymousTransfer(user.auth_token, 1, 590331) #Accepts values of BTC up to 1 Billion, where 1 is value of BTC
  #Sending 1 BTC to me^^^^^                                       #You can dont care about adding this user as contact, it's cayman too
end



