module HackEx
  class Action
    class << self
      public
      def Login http, email, password
        json = HackEx::Request.Do(http, HackEx::Request.Login(email, password))
        json['user']
      end

      def AddContact http, user_id1, auth_token1, user_id2, auth_token2
        # prevent failure
        json = HackEx::Request.Do(http, [HackEx::Request.AddContact(auth_token1, user_id2)])
        json = HackEx::Request.Do(http, [HackEx::Request.AcceptContact(auth_token2, user_id1)])
      end

      # return empty array [] in case of any error
      def UserBank http, auth_token
        json = HackEx::Request.Do(http, HackEx::Request.UserBank(auth_token))
        json['user_bank'] || {}
      rescue
        # ok
        {}
      end

      # return empty array [] in case of any error
      def UserProcesses http, auth_token
        json = HackEx::Request.Do(http, HackEx::Request.UserProcesses(auth_token))
        json['user_processes'] || []
      rescue
        # ok
        []
      end

      # return empty array [] in case of any error
      def UserSoftware http, auth_token
        json = HackEx::Request.Do(http, HackEx::Request.UserSoftware(auth_token))
        json['user_software'] || []
      rescue
        # ok
        []
      end

      # return empty array [] in case of any error
      def UserSpam http, auth_token
        json = HackEx::Request.Do(http, HackEx::Request.UserSpam(auth_token))
        json['spam'] || []
      rescue
        # ok
        []
      end

      def ProcessClean http, auth_token, params = {}
        process_types = params.fetch(:process_types, [Helper.ProcessTypeId('download'), Helper.ProcessTypeId('upload')])
        process_types = [process_types] unless process_types.is_a?(Array)
        process_statuses = params.fetch(:process_statuses, Helper.ProcessStatusId('ready'))
        process_statuses = [] unless process_statuses.is_a?(Array)
        user_processes = params.fetch(:user_processes, nil)
        user_processes ||= HackEx::Action.UserProcesses(http, auth_token)

        to_clean = []
        ready_list = Helper.FilterHashArray user_processes, {'status' => process_statuses, 'process_type_id' => process_types}
        out_list = user_processes - ready_list
        ready_list.each do |p|
          to_clean << p['id']
        end

        unless to_clean.empty?
          HackEx::Request.Do(http, HackEx::Request.ProcessesDelete(auth_token, to_clean))
        end

        out_list
      end

      def PurchaseMissingSoftware http, auth_token, items, params = {}
        items = [items] unless items.is_a? Array

        user_software = params.fetch(:user_software, nil)
        user_software ||= HackEx::Action.UserSoftware(http, auth_token)

        sw = HackEx.ParseSoftware(user_software)

        res = true
        items.each do |item|
          unless sw.has_key? item
            puts "No #{item}, try to buy it"
            json = HackEx::Request.Do(http, HackEx::Request.StorePurchase(auth_token, 'software', HackEx::Helper.SoftwareId(item)))
            #puts res.inspect
            if json['success'].to_s != 'true'
              puts 'Error in buying'
              res = false
            end
          end
        end

        res
      end

      def PrepareToSpam http, auth_token, params = {}
        PurchaseMissingSoftware http, auth_token, 'Spam', params
      end

      def PrepareToCrack http, auth_token, params = {}
        PurchaseMissingSoftware http, auth_token, 'Password Cracker', params
      end

      def PrepareToCrackAndSpam http, auth_token, params = {}
        PurchaseMissingSoftware http, auth_token, ['Spam', 'Password Cracker'], params
      end

      # start single process
      # @return Process (hash)
      def StartProcess http, auth_token, victim_user_id, mode, params = {}
        sw_victim = true
        case mode
        when 'bypass'
          action = 'bypass'
          sw_name = 'Firewall'
          add_param = params.fetch(:fw_add, 0)
        when 'crack'
          action = 'crack'
          sw_name = 'Password Encryptor'
          add_param = params.fetch(:enc_add, 0)
        when 'spam'
          action = 'upload'
          sw_name = 'Spam'
          add_param = 0
          sw_victim = false
        when 'spyware'
          action = 'upload'
          sw_name = 'Spyware'
          add_param = 0
          sw_victim = false
        else
          raise HackExError, "Incorrect mode #{mode}"
        end

        user_processes = params.fetch(:user_processes, nil)
        user_processes ||= HackEx::Action.UserProcesses(http, auth_token)
        software_id = params.fetch(:software_id, nil)
        software_level = params.fetch(:software_level, nil)

        if software_id.nil? || software_level.nil?
          if sw_victim
            victim_user = params.fetch(:victim_user, nil)
            victim_user ||= HackEx::Request.Do(http, HackEx::Request.VictimInfo(auth_token, victim_user_id))
            victim_sws = victim_user['user_software']
          else
            user_software = params.fetch(:user_software, nil)
            user_software ||= HackEx::Action.UserSoftware(http, auth_token)
            victim_sws = user_software
            #puts victim_sws.inspect
          end
          victim_sw = Helper.FilterHashArray victim_sws, {'software_type_id' => Helper.SoftwareId(sw_name)}
          #puts victim_sw.inspect if action == 'upload'
          unless victim_sw.empty?
            software_id = victim_sw.first['software_id']
            software_level = victim_sw.first['software_level']
          else
            puts "No #{sw_name} on #{sw_victim ? 'victim' : 'us'} is found"
            software_level = 1
          end
        end

        # need levels
        software_need_level = software_level.to_i + add_param.to_i
        software_need_level = params[:level].to_i if params.has_key?(:level)
        software_need_level = 1 if software_need_level.to_i < 1

        puts "Process #{mode} user #{victim_user_id}, sw level #{software_need_level} (current #{software_level.to_i})"

        scan_processes = Helper.FilterHashArray user_processes, {'process_type_id' => Helper.ProcessTypeId(action), 'victim_user_id' => victim_user_id}
        unless scan_processes.empty?
          # check is it ok or not
          if scan_processes.size > 1
            # todo: handle better more than 1 process at the same time
            # now - as incorrect situation, just remove everything
            to_clean = []
            scan_processes.each do |p|
              to_clean << p['id']
            end
            puts "More than 1 existing #{mode} processes, delete everything"
            HackEx::Request.Do(http, HackEx::Request.ProcessesDelete(auth_token, to_clean))
            scan_processes = []
          else
            scan_process = scan_processes.first
            scan_process_sw_level = scan_process['software_level']
            scan_process_sw_id = scan_process['software_id']
            if scan_process_sw_level.to_i < software_need_level.to_i || scan_process_sw_id.to_s != software_id.to_s
              puts "Existing process sw level #{scan_process_sw_level.to_i} < #{software_need_level.to_i} or sw id #{scan_process_sw_id.to_s} != #{software_id.to_s}"
              HackEx::Request.Do(http, HackEx::Request.ProcessDelete(auth_token, scan_process['id']))
              scan_processes = []
            elsif scan_process['status'].to_s == Helper.ProcessStatusId('failed').to_s
              puts "Retry process #{scan_process['id']}"
              HackEx::Request.Do(http, HackEx::Request.ProcessRetry(auth_token, scan_process['id']))
            elsif scan_process['status'].to_s == Helper.ProcessStatusId('ready').to_s
              puts "Ready process #{scan_process['id']} found"
            elsif scan_process['status'].to_s == Helper.ProcessStatusId('progress').to_s
              puts "In progress process #{scan_process['id']} found"
            end
          end
        end

        if scan_processes.empty?
          puts "Add #{mode} process user #{victim_user_id} sw id #{software_id} level #{software_need_level}"
          json = HackEx::Request.Do(http, HackEx::Request.UserAddProcess(auth_token, victim_user_id, action, software_id, software_need_level))['user_processes'][0]
          puts "Process #{json['id']} is added"
          json
        else
          scan_processes.first
        end
      end
      private :StartProcess

      # start crack process
      # @return Process (hash)
      def StartBypass http, auth_token, victim_user_id, params = {}
        StartProcess http, auth_token, victim_user_id, 'bypass', params
      end

      def StartCrack http, auth_token, victim_user_id, params = {}
        StartProcess http, auth_token, victim_user_id, 'crack', params
      end

      def StartSpam http, auth_token, victim_user_id, params = {}
        StartProcess http, auth_token, victim_user_id, 'spam', params
      end
    end
  end
end
