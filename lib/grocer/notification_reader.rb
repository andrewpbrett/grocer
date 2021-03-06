require 'json'
require 'grocer/notification'

module Grocer
  class NotificationReader
    include Enumerable

    def initialize(io)
      @io = io
    end

    def each
      while notification = read_notification
        yield notification
      end
    end

    private

    def read_notification
      @io.read(1) # version (not used for now)

      payload = { }
      payload[:identifier] = @io.read(4).unpack("N").first
      payload[:expiry] = Time.at(@io.read(4).unpack("N").first)

      @io.read(2) # device token length (always 32, so not used)
      payload[:device_token] = @io.read(32).unpack("H*").first

      payload_length = @io.read(2).unpack("n").first
      payload_hash = JSON.parse(@io.read(payload_length), :symbolize_names => true)

      payload.merge!(payload_hash.delete(:aps) || { })
      payload[:custom] = payload_hash

      Grocer::Notification.new(payload)
    end
  end
end
