module LibGoo
  OLD_TO_NEW = {getUser: 'get_user', getUserProcesses: 'UserProcesses', getUserAntivirus: 'UserViruses', addProcess: 'UserAddProcess', getRandomUsers: 'RandomUsers', getVictimInfo: 'VictimInfo', getVictimBank: 'VictimBank', getStore: 'StoreInfo', updateVictimLog: 'UpdateVictimLog', updateUserLog: 'UpdateUserLog', updateUserNotepad: 'UpdateUserNotepad', transferToSavings: 'TransferBankFundsToSavings', transferToVictim: 'TransferBankFundsToVictim', transferToContact: 'TransferBankFundsToContact', addContact: 'AddContact', acceptContact: 'AcceptContact', removeContact: 'RemoveContact', storePurchase: 'StorePurchase', getUserByIp: 'UserByIp', getUserBank: 'UserBank', getUserViruses: 'UserViruses', getUserSoftware: 'UserSoftware', getUserSpam: 'UserSpam', getUserSpyware: 'UserSpyware', removeUploadedVirus: 'UserRemoveUploadedVirus', processInfo: 'ProcessInfo', processOverclock: 'ProcessOverclock', processRetry: 'ProcessRetry', processDelete: 'ProcessDelete', processesDelete: 'ProcessesDelete', getLeaderboard: 'Leaderboard'}
  NEW_TO_OLD = OLD_TO_NEW.invert
class User
  attr_accessor :auth_token, :http, :user
  def initialize(email, password, auth_token = nil)
    if auth_token
      HackEx.NetworkDo { |http| @http = http; @user = HackEx::Request.Do(http, HackEx::Request.UserInfo(auth_token))['user']}
      @auth_token = auth_token
    else
      HackEx.LoginDo(email, password) {|http, auth, user| @auth_token , @http, @user = auth, http, user}
    end
  end


  def get_user
    @user = HackEx::Request.Do(@http, HackEx::Request.UserInfo(@auth_token))['user']
  end


  def method_missing(m, *args)
    m = m.to_s.gsub(m.to_s, OLD_TO_NEW[m]).to_sym if OLD_TO_NEW.has_key?(m)
    if HackEx::Request.respond_to?(m)
      HackEx::Request.Do(@http, HackEx::Request.method(m).call(@auth_token, *LibGooHelper.params(*args)))
    else
      raise LibGooError, "Undefined method '#{m}' for class LibGoo::User or class HackEx::Request"
    end
  end

  class << self
    public

    def Do(email, password, auth_token = nil)
     obj =  User.new(email, password, auth_token)
     yield obj.http, obj.auth_token, obj.user, obj
    end

  end
end
end