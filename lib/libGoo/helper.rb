module LibGoo
  class LibGooHelper

    class << self

      def AnonymousTransfer(auth_token, amount, user_id, display = true) #Adds contact, then transfers BTC to him and removes him, or just transfers BTC if contact already exists. Supports values up to 1B
        HackEx.NetworkDo do |http|
          added = ForceAdd(auth_token, user_id)
          if amount <= 100_000_000
            HackEx::Request.Do(http, HackEx::Request.TransferBankFundsToContact(auth_token, user_id, amount))
            puts "Transfering #{amount}" if display
          elsif amount > 1_000_000_000
            raise LibGooError, "Too much money to transfer #{amount}"
          elsif amount < 100_000_000
            i = amount / 100_000_000
            ii = amount % 100_000_000
            i.times {HackEx::Request.Do(http, HackEx::Request.TransferBankFundsToContact(auth_token, user_id, 100_000_000))}
            i.times {puts 'Transfering 100M'} if display
            HackEx::Request.Do(http, HackEx::Request.TransferBankFundsToContact(auth_token, user_id, ii)) if ii > 0
            puts "Transfering #{ii}" if ii > 0 && display
          end
          HackEx::Request.Do(http, HackEx::Request.RemoveContact(auth_token, user_id)) if added
        end
      end

      def ForceAdd(auth_token, user_id) #Force add contact and returns true if success, and false if not.
        HackEx.NetworkDo do |http|
          HackEx::Request.Do(http, HackEx::Request.AddContact(auth_token, user_id))
          HackEx::Request.Do(http, HackEx::Request.AcceptContact(auth_token, user_id))
          true
        end
      rescue
        false
      end

      def SafeVictimInfo(http, auth_token, id) #Doesnt stopping your script in case SLL handshake or other errors
        return HackEx::Request.Do(http, HackEx::Request.VictimInfo(auth_token, id))
      rescue
        false
      end

      def MassScanner(auth_token, array, display = false) #Array is array of scanned IDs like [minimum, maximum] ([1001, 1100])
        errors = []
        cur_id, max = array
        HackEx.NetworkDo do |http|
          while cur_id < max
            victim = SafeVictimInfo(http, auth_token, cur_id)
            if victim
              yield victim
              errors = [] if errors.count > 0
              puts "[#{Time.now}] Scanned id #{cur_id}" if display
              cur_id += 1
            else
              errors << 'error, yopta'
              puts "Failed to scan victim ID:#{cur_id}, count of errors: #{errors.count}"
              raise LibGooError, 'Too much errors in same victim: ' + errors.count.to_s if errors.count > 10
            end
          end
        end
      end

      def params(*objs) #Parameters processor, accepts  Array, String, Integer, LibGoo::Processes
        result = []
        objs.each do |obj|
          if obj.is_a?(Fixnum) || obj.is_a?(String) || obj.is_a?(Array)
            result << obj
          elsif LibGoo::ObjectProcessor.descendants.include?(obj.class)
            return obj.get_var(obj.class.class_variable_get(:@@important))
          else
            raise LibGooError, 'Undefined class object given as one of params: ' + obj.class.to_s
          end
        end
        result
      end
    end
  end
end