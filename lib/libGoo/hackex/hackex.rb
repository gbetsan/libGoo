module HackEx
  class << self
    public
    def NetworkDo &proc
      HackEx::Request::NetworkDo &proc
    end

    def LoginDo email, password, &proc
      NetworkDo do |http|
        user = HackEx::Action.Login http, email, password
        token = user['auth_token']
        proc.call(http, token, user)
      end
    end

    def VictimProcesses user_processes, victim_user_id, process_type_id = 0
      out = []
      user_processes = [] if user_processes.nil?
      user_processes.each do |p|
        next if (process_type_id.to_i != 0 && process_type_id.to_i != p['process_type_id'].to_i)
        out << p if p['victim_user_id'].to_i == victim_user_id.to_i
      end
      out
    end

    def SpamUpload http, auth_token, user_id, level
      scan = Request.Do(http, HackEx::Request.UserAddProcess(auth_token, user_id, 'scan', '1264694', '100'))
      begin
        Request.Do(http, Request.UserAddProcess(auth_token, user_id, 'upload', '1264818', level.to_i.to_s))
      rescue
        puts "Rescued: #{$!}"
      end
      Request.Do(http, HackEx::Request.ProcessDelete(auth_token, scan['user_processes'][0]['id']))
      puts "Uploading spam #{level} to user #{user_id}"#, scan process #{scan['user_processes'][0]['id']}"
    end

    def VictimProcessClean http, auth_token, user_id
      HackEx::Request.Do(http, HackEx::Request.UserProcesses(auth_token))['user_processes'].each do |p|
        if p['victim_user_id'].to_i == user_id.to_i
          puts "Delete process #{p['id']}"
          HackEx::Request.Do(http, HackEx::Request.ProcessDelete(auth_token, p['id']))
        end
      end
    end

    def VictimProcessWait http, auth_token, user_id, process_id = nil
      finish = false
      chars = 'abcdefghijklmnopqrstuvwxyz'
      total_msg = 0
      while !finish do
        finish = true
        long_wait = false
        if process_id.nil?
          processes = HackEx::Request.Do(http, HackEx::Request.UserProcesses(auth_token))['user_processes']
        else
          processes = [ HackEx::Request.Do(http, HackEx::Request.ProcessInfo(auth_token, process_id))['process'] ]
        end
        processes.each do |p|
          if p['victim_user_id'].to_i == user_id.to_i
            c = chars[total_msg % chars.length]
            if (p['process_type_id'].to_i == 3 || p['process_type_id'].to_i == 4) && p['status'].to_i == 2
              puts "Delete ready process #{p['id']} #{c}"
              total_msg += 1
              HackEx::Request.Do(http, HackEx::Request.ProcessDelete(auth_token, p['id']))
            elsif p['status'].to_i == 3
              puts "Retry process #{p['id']} #{c}"
              total_msg += 1
              HackEx::Request.Do(http, HackEx::Request.ProcessRetry(auth_token, p['id']))
              finish = false
            elsif p['status'].to_i == 1
              puts "Waiting process #{p['id']}, overclocks #{p['overclocks_needed']} #{c}"
              long_wait = true if p['overclocks_needed'].to_i > 1
              total_msg += 1
              finish = false
            end
          end
        end
        sleep (long_wait ? 20 : 5) unless finish
        print '.' unless finish
      end
    end

    def ProcessClean email, password
      LoginDo(email, password) do |http, auth_token|
        json = Request.Do(http, Request.UserProcesses(auth_token))
        json['user_processes'].each do |p|
          if p['status'].to_i == 2 && (p['process_type_id'].to_i == 4 || p['process_type_id'].to_i == 3)
            puts p.inspect
            Request.Do(http, Request.ProcessDelete(auth_token, p['id']))
          end
        end
      end
  
    end

    def ParseSoftware software
      out = {}
      software = [] if software.nil?
      software.each do |s|
        #puts s
        out[s['name']] = s['software_level']
      end
      out
    end

    # clean user hash from non-needed keys
    def CleanUser user
      out = user.dup
      ['reputation', 'pts_to_next_level', 'pts_level_progress', 'overclocks', 'wallpaper', 'created_at'].each do |v|
        out.delete(v)
      end
      out
    end

    def CleanBank bank
      out = bank.dup
      ['id'].each do |v|
        out.delete(v)
      end
      out
    end

    def SingleBot http, auth_token, params = {}
      puts "#{auth_token}"
      victims = params.fetch(:victims, [])
      max_victims = params.fetch(:max_victims, 50)

      # 
      user = HackEx::Request.Do(http, HackEx::Request.UserInfo(auth_token))
      user_processes = user['user_processes']
      user_software = user['user_software']

      #
      HackEx::Action.PrepareToCrackAndSpam http, auth_token, :user_software => user_software

      #
      bypass_processes = Helper.FilterHashArray user_processes, {'process_type_id' => Helper.ProcessTypeId('bypass')}
      failed_processes = Helper.FilterHashArray bypass_processes, {'status' => Helper.ProcessStatusId('failed')}
      ready_processes = Helper.FilterHashArray bypass_processes, {'status' => Helper.ProcessStatusId('ready')}
      progress_processes = Helper.FilterHashArray bypass_processes, {'status' => Helper.ProcessStatusId('progress')}
      puts "Bypass processes: #{bypass_processes.size} = #{progress_processes.size} progress + #{ready_processes.size} ready + #{failed_processes.size} failed"
      failed_processes.each do |p|
        puts "Retry bypass process #{p['id']}"
        HackEx::Request.Do(http, HackEx::Request.ProcessRetry(auth_token, p['id']))
      end

      if progress_processes.size == 0 && failed_processes.size == 0
        if bypass_processes.size >= max_victims.to_i
          # cracks
          begin
            HackEx::Action.StartCrack http, auth_token, v['id'], :user_processes => user_processes
          rescue
            puts "Rescued StartCrack: #{$!}"
          end
        else
          # get victim list
          victims = HackEx::Request.Do(http, HackEx::Request.RandomUsers(auth_token))['users'] if victims.empty?
          victims.each do |v|
            v = { 'id' => v } unless v.is_a?(Hash)
            #next if (v.has_key?('software_level') && v['software_level'].to_i > 1)
            begin
              HackEx::Action.StartBypass http, auth_token, v['id'], :user_processes => user_processes, :software_level => v['software_level'], :software_id => v['software_id']
            rescue
              puts "Rescued StartBypass: #{$!}"
            end
          end
        end

        # spam
        user_spam = HackEx::Action.UserSpam http, auth_token
        users_spam = []
        user_spam.each do |us|
          users_spam << us['victim_user_id'].to_i
        end

        ready_processes.each do |p|
          next if users_spam.include?(p['victim_user_id'].to_i)
          begin
            HackEx::Action.StartSpam http, auth_token, p['victim_user_id'], :user_software => user_software, :user_processes => user_processes, :level => 1
          rescue
            puts "Rescued StartSpam: #{$!}"
            raise
          end
        end
      end

      # 
      user_bank = HackEx::Action.UserBank http, auth_token
      if user_bank['checking'].to_i > 0
        puts "Bank: #{user_bank['checking'].to_i}"
        #zzzzz
      end

    end
  end

end
