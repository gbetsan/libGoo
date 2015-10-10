#require 'hackex' #Optional
require 'libGoo'
include LibGoo

user = User.new('your@e.mail', 'password')
#user = User.new(nil, nil, 'YOUR_AUTH_TOKEN_HERE') #Loggining by auth token

#Methods names as in hackex/request.rb, but you can also use old methods names or translate old ones to new ones by OLD_TO_NEW
puts LibGoo::OLD_TO_NEW['getUserProcesses'.to_sym]  #=>UserProcesses
puts LibGoo::NEW_TO_OLD[:UserProcesses]             #=>getUserProcesses
puts JSON.pretty_generate user.VictimInfo(590331)
puts JSON.pretty_generate user.user
puts user.auth_token
