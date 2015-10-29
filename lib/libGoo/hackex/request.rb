require 'digest/sha1'
require 'json'

module HackEx
  module Request
    URI_BASE = 'https://api.hackex.net/v5/'
    USER_AGENT = 'Mozilla/5.0 (Linux; U; Android 4.1.1; en-us; Nexus 5) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1'

    class << self
      include Network

      private
      def Signature params
        out_params = {}
        ts = (Time.now.utc.to_f * 1000).to_i.to_s
        params['sig2'] = ts
        keys = params.keys.sort_by { |w| 
          w#.downcase 
        }
        keys.reverse!
        s = '1101101101'
        keys.each do |k|
          s += k.to_s + params[k].to_s
          out_params[k] = params[k]
        end

        keys.each do |k|
          params.delete(k)
        end
        keys.each do |k|
          params[k] = out_params[k]
        end

        sa = 'WqZnwjpaVZNvWDpJhqHCHhWtNfu86CkmtCAVErbQO'
        hash = Digest::SHA1.hexdigest(s + sa)
        params['sig'] = hash
        #puts "#{s + sa}: #{hash}"
        "#{hash}&sig2=#{ts}"
      end

      public
      def CreateUser username, email, password, facebook_id = nil
        params = { 'username' => username, 'email' => email, 'os_type_id' => '1' }
        params['password'] = password unless password.nil?
        params['facebook_id'] = facebook_id unless facebook_id.nil?
        Post 'user', params
      end

      def Login email, password
        Post 'auth', 'email' => email, 'password' => password
      end

      def RandomUsers auth_token, count = 5
        Get 'users_random', 'count' => count, :auth_token => auth_token
      end

      def VictimInfo auth_token, user_id
        Get 'user_victim', 'victim_user_id' => user_id, :auth_token => auth_token
      end

      def VictimBank auth_token, user_id
        Get 'victim_user_bank', 'victim_user_id' => user_id, :auth_token => auth_token
      end

      def StoreInfo auth_token
        Get 'store', :auth_token => auth_token
      end

      def UpdateVictimLog auth_token, user_id, text
        Post 'victim_user_log', 'victim_user_id' => user_id, 'text' => text, :auth_token => auth_token
      end

      def UpdateUserLog auth_token, text
        Post 'user_log', 'text' => text, :auth_token => auth_token
      end

      def UpdateUserNotepad auth_token, text
        Post 'user_notepad', 'text' => text, :auth_token => auth_token
      end

      def TransferBankFundsToSavings auth_token, amount
        Post 'bank_transfer_savings', 'amount' => amount, :auth_token => auth_token
      end

      def TransferBankFundsFromVictim auth_token, user_id, amount
        Post 'bank_transfer_from_victim', 'victim_user_id' => user_id, 'amount' => amount, :auth_token => auth_token
      end

      def TransferBankFundsToContact auth_token, user_id, amount
        Post 'bank_transfer_to_contact', 'contact_user_id' => user_id, 'amount' => amount, :auth_token => auth_token
      end

      def AddContact auth_token, user_id
        Post 'contact_add', 'contact_user_id' => user_id, :auth_token => auth_token
      end

      def AcceptContact auth_token, user_id
        Post 'contact_accept', 'contact_user_id' => user_id, :auth_token => auth_token
      end

      def RemoveContact auth_token, user_id
        Post 'contact_remove', 'contact_user_id' => user_id, :auth_token => auth_token
      end

      def StorePurchase auth_token, type, type_id
        params = {}
        case type
        when 'software'
          params['software_type_id'] = type_id
        when 'device'
          params['device_type_id'] = type_id
        when 'network'
          params['network_type_id'] = type_id
        else
          raise "Unknown type #{type}"
        end
        params[:auth_token] = auth_token
        Post 'store_purchase', params
      end

      def UserByIp auth_token, ip
        Get 'user', 'user_ip' => ip, 'process_type_id' => 1, :auth_token => auth_token
      end

      def UserInfo auth_token
        Get 'user', 'extras' => 'true', :auth_token => auth_token
      end

      def UserBank auth_token
        Get 'user_bank', :auth_token => auth_token
      end

      def UserViruses auth_token
        Get 'user_viruses', :auth_token => auth_token
      end

      def UserSoftware auth_token
        Get 'user_software', :auth_token => auth_token
      end

      def UserProcesses auth_token
        Get 'user_processes', :auth_token => auth_token
      end

      def UserSpam auth_token
        Get 'user_spam', :auth_token => auth_token
      end

      def UserSpyware auth_token
        Get 'user_spyware', :auth_token => auth_token
      end

      def UserRemoveUploadedVirus auth_token, virus_id, software_type_id
        Post 'user_virus_uploaded_remove', 'virus_id' => virus_id, 'software_type_id' => software_type_id, :auth_token => auth_token
      end

      def UserAddProcess auth_token, user_id, process_type, software_id, software_level = nil
        params = { 'victim_user_id' => user_id, 'software_id' => software_id }
        case process_type
        when 'scan', 'bypass'
          params['process_type_id'] = '1'
        when 'crack'
          params['process_type_id'] = '2'
        when 'download'
          params['process_type_id'] = '3'
        when 'upload'
          params['process_type_id'] = '4'
        else
          raise "Unknown type: #{process_type}"
        end
        params['software_level'] = software_level unless software_level.nil?
        params[:auth_token] = auth_token
        Post 'process', params
      end

      def ProcessInfo auth_token, process_id
        Get 'process', 'process_id' => process_id, :auth_token => auth_token
      end

      def ProcessRetry auth_token, process_id
        Post 'process_retry', 'process_id' => process_id, :auth_token => auth_token
      end

      def ProcessOverclock auth_token, process_id
        Post 'process_overclock', 'process_id' => process_id, :auth_token => auth_token
      end

      def ProcessDelete auth_token, process_id
        Post 'process_delete', 'process_id' => process_id, :auth_token => auth_token
      end

      def ProcessesDelete auth_token, process_ids
        Post 'processes_delete', 'process_ids' => process_ids.join('|'), :auth_token => auth_token
      end

      def Leaderboard auth_token, offset = 0
        Get 'leaderboards', 'offset' => offset, :auth_token => auth_token
      end
    end
  end
end
