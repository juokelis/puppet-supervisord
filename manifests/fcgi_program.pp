# Define: supervisord::fcgi_program
#
# This define creates an eventlistener configuration file
#
# Documentation on parameters available at:
# http://supervisord.org/configuration.html#fcgi-program-x-section-settings
#
define supervisord::fcgi_program(
  String $command,
  Pattern[/^tcp:\/\/.*:\d+$/, /^unix:\/\/\//] $socket,
      $ensure                                                                       = present,
  Optional[Enum['running', 'stopped', 'removed', 'unmanaged']] $ensure_process      = 'running',
  Optional[Boolean] $cfgreload                                                      = undef,
  $socket_owner                                                                     = undef,
  $socket_mode                                                                      = undef,
  $env_var                                                                          = undef,
  Optional[String] $process_name                                                    = undef,
  Optional[Integer] $numprocs                                                       = undef,
  Optional[Integer] $numprocs_start                                                 = undef,
  Optional[Integer] $priority                                                       = undef,
  Optional[Boolean] $autostart                                                      = undef,
  Optional[Variant[Boolean, Enum['true', 'false', 'unexpected']]] $autorestart      = undef,
  Optional[Integer] $startsecs                                                      = undef,
  Optional[Integer] $startretries                                                   = undef,
  Optional[String] $exitcodes                                                       = undef,
  Optional[Enum['TERM', 'HUP', 'INT', 'QUIT', 'KILL', 'USR1', 'USR2']] $stopsignal  = undef,
  Optional[Integer] $stopwaitsecs                                                   = undef,
  Optional[Boolean] $stopasgroup                                                    = undef,
  Optional[Boolean] $killasgroup                                                    = undef,
  Optional[String] $user                                                            = undef,
  Optional[Boolean] $redirect_stderr                                                = undef,
  String $stdout_logfile                                                            = "fcgi-program_${name}.log",
  Optional[String] $stdout_logfile_maxbytes                                         = undef,
  Optional[Integer] $stdout_logfile_backups                                         = undef,
  Optional[String] $stdout_capture_maxbytes                                         = undef,
  Optional[Boolean] $stdout_events_enabled                                          = undef,
  String $stderr_logfile                                                            = "fcgi-program_${name}.error",
  Optional[String] $stderr_logfile_maxbytes                                         = undef,
  Optional[Integer] $stderr_logfile_backups                                         = undef,
  Optional[String] $stderr_capture_maxbytes                                         = undef,
  Optional[Boolean] $stderr_events_enabled                                          = undef,
  Optional[Hash] $environment                                                       = undef,
  Optional[Hash] $program_environment                                               = undef,
  Optional[Stdlib::Absolutepath] $directory                                         = undef,
  Optional[Pattern[/^[0-7][0-7][0-7]$/]] $umask                                     = undef,
  $serverurl                                                                        = undef,
  Pattern[/^0[0-7][0-7][0-7]$/] $config_file_mode                                   = '0644'
) {

  include supervisord

  # create the correct log variables
  $stdout_logfile_path = $stdout_logfile ? {
        /(NONE|AUTO|syslog)/ => $stdout_logfile,
        /^\//                => $stdout_logfile,
        default              => "${supervisord::log_path}/${stdout_logfile}",
  }

  $stderr_logfile_path = $stderr_logfile ? {
        /(NONE|AUTO|syslog)/ => $stderr_logfile,
        /^\//                => $stderr_logfile,
        default              => "${supervisord::log_path}/${stderr_logfile}",
  }

  # Handle deprecated $environment variable
  if $environment { notify {'[supervisord] *** DEPRECATED WARNING ***: $program_environment has replaced $environment':}}
  $_program_environment = $program_environment ? {
    undef   => $environment,
    default => $program_environment
  }

  # convert environment data into a csv
  if $env_var {
    $env_hash = lookup($env_var, Hash, 'hash')
    $env_string = supervisord::hash2csv($env_hash)
  }
  elsif $_program_environment {
    $env_string = supervisord::hash2csv($_program_environment)
  }

  # Reload default with override
  $_cfgreload = $cfgreload ? {
    undef   => $supervisord::cfgreload_fcgi_program,
    default => $cfgreload
  }

  $conf = "${supervisord::config_include}/fcgi-program_${name}.conf"

  file { $conf:
    ensure  => $ensure,
    owner   => 'root',
    mode    => $config_file_mode,
    content => template('supervisord/conf/fcgi_program.erb'),
  }

  if $_cfgreload {
    File[$conf] {
      notify => Class['supervisord::reload'],
    }
  }

  case $ensure_process {
    'stopped': {
      supervisord::supervisorctl { "stop_${name}":
        command => 'stop',
        process => $name
      }
    }
    'removed': {
      supervisord::supervisorctl { "remove_${name}":
        command => 'remove',
        process => $name
      }
    }
    'running': {
      supervisord::supervisorctl { "start_${name}":
        command => 'start',
        process => $name,
        unless  => 'running'
      }
    }
    default: { }
  }
}
