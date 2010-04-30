# Load the appropriate libraries, or set a class indicating they aren't available

require 'facter'
require 'puppet'

module Puppet::Rails
  TIME_DEBUG = true

  def self.connect
    # This global init does not work for testing, because we remove
    # the state dir on every test.
    return if ActiveRecord::Base.connected?

    Puppet.settings.use(:main, :rails, :puppetmasterd)

    ActiveRecord::Base.logger = Logger.new(Puppet[:railslog])
    begin
      loglevel = Logger.const_get(Puppet[:rails_loglevel].upcase)
      ActiveRecord::Base.logger.level = loglevel
    rescue => detail
      Puppet.warning "'#{Puppet[:rails_loglevel]}' is not a valid Rails log level; using debug"
      ActiveRecord::Base.logger.level = Logger::DEBUG
    end

    if (::ActiveRecord::VERSION::MAJOR == 2 and ::ActiveRecord::VERSION::MINOR <= 1)
      ActiveRecord::Base.allow_concurrency = true
    end

    ActiveRecord::Base.verify_active_connections!

    begin
      args = database_arguments
      Puppet.info "Connecting to #{args[:adapter]} database: #{args[:database]}"
      ActiveRecord::Base.establish_connection(args)
    rescue => detail
      puts detail.backtrace if Puppet[:trace]
      raise Puppet::Error, "Could not connect to database: #{detail}"
    end
  end

  # The arguments for initializing the database connection.
  def self.database_arguments
    adapter = Puppet[:dbadapter]

    args = {:adapter => adapter, :log_level => Puppet[:rails_loglevel]}

    case adapter
    when "sqlite3"
      args[:database] = Puppet[:dblocation]
    when "mysql", "postgresql"
      args[:host]     = Puppet[:dbserver] unless Puppet[:dbserver].empty?
      args[:port]     = Puppet[:dbport] unless Puppet[:dbport].empty?
      args[:username] = Puppet[:dbuser] unless Puppet[:dbuser].empty?
      args[:password] = Puppet[:dbpassword] unless Puppet[:dbpassword].empty?
      args[:database] = Puppet[:dbname]
      args[:reconnect]= true

      socket          = Puppet[:dbsocket]
      args[:socket]   = socket unless socket.empty?

      connections     = Puppet[:dbconnections].to_i
      args[:pool]     = connections if connections > 0
    when "oracle_enhanced":
      args[:database] = Puppet[:dbname] unless Puppet[:dbname].empty?
      args[:username] = Puppet[:dbuser] unless Puppet[:dbuser].empty?
      args[:password] = Puppet[:dbpassword] unless Puppet[:dbpassword].empty?

      connections     = Puppet[:dbconnections].to_i
      args[:pool]     = connections if connections > 0
    else
      raise ArgumentError, "Invalid db adapter #{adapter}"
    end
    args
  end

  # Set up our database connection.  It'd be nice to have a "use" system
  # that could make callbacks.
  def self.init
    raise Puppet::DevError, "No activerecord, cannot init Puppet::Rails" unless Puppet.features.rails?

    connect

    unless ActiveRecord::Base.connection.tables.include?("resources")
      require 'puppet/rails/database/schema'
      Puppet::Rails::Schema.init
    end

    migrate if Puppet[:dbmigrate]
  end

  # Migrate to the latest db schema.
  def self.migrate
    dbdir = nil
    $LOAD_PATH.each { |d|
      tmp = File.join(d, "puppet/rails/database")
      if FileTest.directory?(tmp)
        dbdir = tmp
        break
      end
    }

    raise Puppet::Error, "Could not find Puppet::Rails database dir" unless dbdir

    raise Puppet::Error, "Database has problems, can't migrate." unless ActiveRecord::Base.connection.tables.include?("resources")

    Puppet.notice "Migrating"

    begin
      ActiveRecord::Migrator.migrate(dbdir)
    rescue => detail
      puts detail.backtrace if Puppet[:trace]
      raise Puppet::Error, "Could not migrate database: #{detail}"
    end
  end

  # Tear down the database.  Mostly only used during testing.
  def self.teardown
    raise Puppet::DevError, "No activerecord, cannot init Puppet::Rails" unless Puppet.features.rails?

    Puppet.settings.use(:puppetmasterd, :rails)

    begin
      ActiveRecord::Base.establish_connection(database_arguments)
    rescue => detail
      puts detail.backtrace if Puppet[:trace]
      raise Puppet::Error, "Could not connect to database: #{detail}"
    end

    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.drop_table t
    end
  end
end

require 'puppet/rails/host' if Puppet.features.rails?

