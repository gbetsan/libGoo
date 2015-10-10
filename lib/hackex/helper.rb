module HackEx
  class Helper
    class << self
      SOFTWARE_ID_TO_NAME = {
        1 => 'Firewall',
        2 => 'Bypasser',
        3 => 'Password Cracker',
        4 => 'Password Encryptor',
        5 => 'Antivirus',
        6 => 'Spam',
        7 => 'Spyware',
        8 => 'Notepad'
      }

      SOFTWARE_NAME_TO_ID = SOFTWARE_ID_TO_NAME.invert

      def SoftwareIdToName id
        raise HackExError, "SoftwareIdToName - incorrect id #{id}" unless SOFTWARE_ID_TO_NAME.has_key?(id.to_i)
        SOFTWARE_ID_TO_NAME[id.to_i]
      end

      def SoftwareNameToId name
        raise HackExError, "SoftwareNameToId - incorrect name #{name}" unless SOFTWARE_NAME_TO_ID.has_key?(name)
        SOFTWARE_NAME_TO_ID[name]
      end

      def SoftwareId param
        return SOFTWARE_NAME_TO_ID[param] if SOFTWARE_NAME_TO_ID.has_key?(param)
        return param.to_i
      end

      PROCESS_TYPE_ID_TO_NAME = {
        1 => 'bypass',
        2 => 'crack',
        3 => 'download',
        4 => 'upload'
      }

      PROCESS_TYPE_NAME_TO_ID = PROCESS_TYPE_ID_TO_NAME.invert

      def ProcessTypeIdToName id
        raise HackExError, "ProcessTypeIdToName - incorrect id #{id}" unless PROCESS_TYPE_ID_TO_NAME.has_key?(id.to_i)
        PROCESS_TYPE_ID_TO_NAME[id.to_i]
      end

      def ProcessTypeNameToId name
        raise HackExError, "ProcessTypeNameToId - incorrect name #{name}" unless PROCESS_TYPE_NAME_TO_ID.has_key?(name)
        PROCESS_TYPE_NAME_TO_ID[name]
      end

      def ProcessTypeId param
        return PROCESS_TYPE_NAME_TO_ID[param] if PROCESS_TYPE_NAME_TO_ID.has_key?(param)
        return param.to_i
      end

      PROCESS_STATUS_ID_TO_NAME = {
        1 => 'progress',
        2 => 'ready',
        3 => 'failed'
      }

      PROCESS_STATUS_NAME_TO_ID = PROCESS_STATUS_ID_TO_NAME.invert

      def ProcessStatusId param
        return PROCESS_STATUS_NAME_TO_ID[param] if PROCESS_STATUS_NAME_TO_ID.has_key?(param)
        return param.to_i
      end

      # filter out array of hashes by filter
      # filter item => [a, b]
      def FilterHashArray array, filter = {}, include = true, &proc
        out = []
        array.each do |item|
          #puts "item #{item.inspect}"
          ok = true
          filter.each_pair do |k, v|
            #puts "#{k} = #{v.inspect}"
            if !item.has_key?(k) || 
                v.is_a?(Array) && !v.map(&:to_s).include?(item[k].to_s) || 
                !v.is_a?(Array) && v.to_s != item[k].to_s
              ok = false
              #puts "False"
              break
            end
          end
          if ok && include || !ok && !include
            #puts "Ok"
            out << item
            proc.call(item) unless proc.nil?
          end
        end
        out
      end
    end
  end
end
