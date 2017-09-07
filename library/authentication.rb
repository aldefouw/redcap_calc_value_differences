class Authentication

  attr_reader :username
  attr_reader :password

  def initialize(**options)
    @base_dir = options[:base_dir]
    load_auth_config
  end

  private

  def load_auth_config
    if File.exists?(@base_dir + "/config/config.yml")
      config_file = File.read(@base_dir + "/config/config.yml")
      @config = YAML.load(config_file)

      if @config.key?("redcap_user") && !@config["redcap_user"].nil?
        if @config["redcap_user"].key?("username") && @config["redcap_user"].key?("password") &&
            !@config["redcap_user"]["username"].nil? && !@config["redcap_user"]["password"].nil?
          @username = @config["redcap_user"]["username"]
          @password = @config["redcap_user"]["password"]
        elsif @config["redcap_user"].key?("username") && !@config["redcap_user"]["username"].nil?
          throw "You are missing a password in your config.yml file."
        elsif @config["redcap_user"].key?("password") && !@config["redcap_user"]["password"].nil?
          throw "You are missing a username in your config.yml file."
        else
          throw "You are missing a username and password in your config.yml file."
        end
      else
        throw "You are missing a username and password in your config.yml file."
      end
    else
      throw "Cannot find a config.yml file."
    end
  end

end