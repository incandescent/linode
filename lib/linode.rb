require 'rubygems'
require 'ostruct'
require 'httparty'

class Linode
  BOOT_FAILED   = -2,          # Boot Failed
  BUILDING      = -1,          # Being Created
  PENDING       = 0,           # Brand New
  RUNNING       = 1,           # Running
  TERMINATED    = 2,           # Powered Off
  SHUTTING_DOWN = 3,           # Shutting Down
  RESERVED      = 4            # Reserved

  attr_reader :api_key
  
  def self.has_method(*actions)
    actions.each do |action|
      define_method(action.to_sym) do |*data|
        data = data.shift if data
        data ||= {}
        send_request(self.class.name.downcase.sub(/^linode::/, '').gsub(/::/, '.') + ".#{action}", data)
      end
    end
  end
  
  def self.has_unauthenticated_method(*actions)
    actions.each do |action|
      define_method(action.to_sym) do |*data|
        data = data.shift if data
        data ||= {}
        send_unauthenticated_request(self.class.name.downcase.sub(/^linode::/, '').gsub(/::/, '.') + ".#{action}", data)
      end
    end
  end
  
  def self.has_namespace(*namespaces)
    namespaces.each do |namespace|
      define_method(namespace.to_sym) do ||
        lookup = instance_variable_get("@#{namespace}")
        return lookup if lookup
        subclass = self.class.const_get(namespace.to_s.capitalize).new(:api_key => api_key, :api_url => api_url)
        instance_variable_set("@#{namespace}", subclass)
        subclass
      end
    end
  end
  
  has_namespace :test, :avail, :user, :domain, :linode
  
  def initialize(args)
    if args.include?(:api_key)
      @api_key = args[:api_key]
      @api_url = args[:api_url] if args[:api_url]
    elsif args.include?(:username) and args.include?(:password)
      @api_url = args[:api_url] if args[:api_url]
      result = send_unauthenticated_request("user.getapikey", { :username => args[:username], :password => args[:password] })
      @api_key = result.api_key
    else
      raise ArgumentError, "Either :api_key, or both :username and :password, are required"
    end
  end

  def api_url
    @api_url || 'https://api.linode.com/'
  end

  def send_request(action, data)
    data.delete_if {|k,v| [:api_key ].include?(k) }
    send_unauthenticated_request(action, { :api_key => api_key }.merge(data))
  end

  def send_unauthenticated_request(action, data)
    data.delete_if {|k,v| [ :api_action, :api_responseFormat].include?(k) }
    http_response = HTTParty.get(api_url, :query => { :api_action => action, :api_responseFormat => 'json' }.merge(data))
    begin
      result = Crack::JSON.parse(http_response)
    rescue Crack::ParseError => e
      raise RuntimeError, "Error parsing response:\n" + http_response.inspect
    end
    raise "Errors completing request [#{action}] @ [#{api_url}] with data [#{data.inspect}]:\n#{error_message(result, action)}" if error?(result)
    reformat_response(result)
  end

 
  protected
  
  def error?(response)
    response and response["ERRORARRAY"] and ! response["ERRORARRAY"].empty?
  end
  
  def error_message(response, action)
    response["ERRORARRAY"].collect { |err|
      "  - Error \##{err["ERRORCODE"]} - #{err["ERRORMESSAGE"]}.  (Please consult http://www.linode.com/api/autodoc.cfm?method=#{action})"
    }.join("\n")
  end
  
  def reformat_response(response)
    result = response['DATA']
    return result.collect {|item| convert_item(item) } if result.class == Array
    return result unless result.respond_to?(:keys)
    convert_item(result)
  end
  
  def convert_item(item)
    item.keys.each do |k| 
      item[k.downcase] = item[k]
      item.delete(k) if k != k.downcase
    end
    ::OpenStruct.new(item)
  end
end

# include all Linode API namespace classes
Dir[File.expand_path(File.dirname(__FILE__) + '/linode/*.rb')].each {|f| require f }
Dir[File.expand_path(File.dirname(__FILE__) + '/linode/**/*.rb')].each {|f| require f }
