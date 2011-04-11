class MQ
  class Queue
    # Asks the broker to redeliver all unacknowledged messages on a
    # specifieid channel. Zero or more messages may be redelivered.
    #
    # * requeue (default false)
    # If this parameter is false, the message will be redelivered to the original recipient.
    # If this flag is true, the server will attempt to requeue the message, potentially then
    # delivering it to an alternative subscriber.
    #
    def recover(requeue = false)
      @mq.callback{
        @mq.send Protocol::Basic::Recover.new({ :requeue => requeue })
      }
      self
    end
  end
  
  def close_connection
    @connection.close
  end
end

module Nanite
  module AMQPHelper
    def start_amqp(options)
      connection = AMQP.connect({
        :user => options[:user],
        :pass => options[:pass],
        :vhost => options[:vhost],
        :host => options[:host],
        :port => (options[:port] || ::AMQP::PORT).to_i,
        :insist => options[:insist] || false,
        :retry => options[:retry] || 5,
        :connection_status => options[:connection_callback] || proc {|event| 
          Nanite::Log.debug("Connected to MQ") if event == :connected
          Nanite::Log.debug("Disconnected from MQ") if event == :disconnected
        }
      })
      MQ.new(connection)
    end
  end

  module FragileHelper
    # Helper to declare conforming queues (in classes with AMQPHelper included)
    # amq.queue(identity, durab.merge :a=>b)...
    def durab
      @fragile_nodes ? {:auto_delete => true} : {:durable => true}
    end
  end
end
