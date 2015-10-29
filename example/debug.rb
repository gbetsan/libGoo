require 'libGoo'
u = LibGoo::User.new('p@p.c', 'ptn')
v = LibGoo::Victim.new('user_id' => 1001)
puts u.VictimInfo(v)
puts LibGoo::LibGooHelper.no_error(u.http, HackEx::Request.VictimInfo(u.auth_token, 1001))