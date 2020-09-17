# Class: supervisord
#
# This class installs supervisord via pip
#
class supervisord(
  $package_ensure                                     = $supervisord::params::package_ensure,
  $package_name                                       = $supervisord::params::package_name,
  $package_provider                                   = $supervisord::params::package_provider,
  $package_install_options                            = $supervisord::params::package_install_options,
  $service_manage                                     = $supervisord::params::service_manage,
  $service_ensure                                     = $supervisord::params::service_ensure,
  $service_enable                                     = $supervisord::params::service_enable,
  $service_name                                       = $supervisord::params::service_name,
  $service_restart                                    = $supervisord::params::service_restart,
  Boolean $install_pip                                = false,
  Optional[Pattern[/^https?:\/\/.*$/]] $pip_proxy     = undef,
  Boolean $install_init                               = $supervisord::params::install_init,
  $init_type                                          = $supervisord::params::init_type,
  $init_mode                                          = $supervisord::params::init_mode,
  $init_script                                        = $supervisord::params::init_script,
  $init_script_template                               = $supervisord::params::init_script_template,
  $init_defaults                                      = $supervisord::params::init_defaults,
  $init_defaults_template                             = $supervisord::params::init_defaults_template,
  $setuptools_url                                     = $supervisord::params::setuptools_url,
  $executable                                         = $supervisord::params::executable,
  $executable_ctl                                     = $supervisord::params::executable_ctl,

  $scl_enabled                                        = $supervisord::params::scl_enabled,
  $scl_script                                         = $supervisord::params::scl_script,

  Stdlib::Absolutepath $log_path                      = $supervisord::params::log_path,
  $log_file                                           = $supervisord::params::log_file,
  Enum['critical', 'error', 'warn', 'info', 'debug', 'trace', 'blather'] $log_level = $supervisord::params::log_level,
  Pattern[/^[0-9]*(?:KB|MB|GB)?/] $logfile_maxbytes   = $supervisord::params::logfile_maxbytes,
  Integer $logfile_backups                            = $supervisord::params::logfile_backups,

  $cfgreload_program                                  = $supervisord::params::cfgreload_program,
  $cfgreload_fcgi_program                             = $supervisord::params::cfgreload_fcgi_program,
  $cfgreload_eventlistener                            = $supervisord::params::cfgreload_eventlistener,
  $cfgreload_rpcinterface                             = $supervisord::params::cfgreload_rpcinterface,

  Stdlib::Absolutepath $run_path                      = $supervisord::params::run_path,
  $pid_file                                           = $supervisord::params::pid_file,
  Boolean $nodaemon                                   = $supervisord::params::nodaemon,
  Integer $minfds                                     = $supervisord::params::minfds,
  Integer $minprocs                                   = $supervisord::params::minprocs,
  $manage_config                                      = $supervisord::params::manage_config,
  Stdlib::Absolutepath $config_include                = $supervisord::params::config_include,
  $config_include_purge                               = false,
  $config_file                                        = $supervisord::params::config_file,
  Pattern[/^0[0-7][0-7][0-7]$/] $config_file_mode     = $supervisord::params::config_file_mode,
  Optional[Array] $config_dirs                        = undef,
  Pattern[/^0[0-7][0-7]$/] $umask                     = $supervisord::params::umask,

  Enum['unix', 'inet'] $ctl_socket                    = $supervisord::params::ctl_socket,

  Boolean $unix_socket                                = $supervisord::params::unix_socket,
  $unix_socket_file                                   = $supervisord::params::unix_socket_file,
  Pattern[/^[0-7][0-7][0-7][0-7]$/] $unix_socket_mode = $supervisord::params::unix_socket_mode,
  $unix_socket_owner                                  = $supervisord::params::unix_socket_owner,
  $unix_socket_group                                  = $supervisord::params::unix_socket_group,
  Boolean $unix_auth                                  = $supervisord::params::unix_auth,
  Optional[String] $unix_username                     = $supervisord::params::unix_username,
  Optional[String] $unix_password                     = $supervisord::params::unix_password,

  Boolean $inet_server                                = $supervisord::params::inet_server,
  $inet_server_hostname                               = $supervisord::params::inet_server_hostname,
  Integer[0, 65535] $inet_server_port                 = $supervisord::params::inet_server_port,
  Boolean $inet_auth                                  = $supervisord::params::inet_auth,
  Optional[String] $inet_username                     = $supervisord::params::inet_username,
  Optional[String] $inet_password                     = $supervisord::params::inet_password,

  $user                                               = $supervisord::params::user,
  $group                                              = $supervisord::params::group,
  $identifier                                         = undef,
  Optional[Stdlib::Absolutepath] $childlogdir         = undef,
  Optional[Hash] $environment                         = undef,
  Optional[Hash] $global_environment                  = undef,
  Optional[Hash] $env_var                             = undef,
  Optional[Stdlib::Absolutepath] $directory           = undef,
  Boolean $strip_ansi                                 = false,
  Boolean $nocleanup                                  = false,

  Hash $eventlisteners                                = {},
  Hash $fcgi_programs                                 = {},
  Hash $groups                                        = {},
  Hash $programs                                      = {}

) inherits supervisord::params {

  if $unix_socket and $inet_server {
    $use_ctl_socket = $ctl_socket
  }
  elsif $unix_socket {
    $use_ctl_socket = 'unix'
  }
  elsif $inet_server {
    $use_ctl_socket = 'inet'
  }

  if $use_ctl_socket == 'unix' {
    $ctl_serverurl = "unix://${supervisord::run_path}/${supervisord::unix_socket_file}"
    $ctl_auth      = $supervisord::unix_auth
    $ctl_username  = $supervisord::unix_username
    $ctl_password  = $supervisord::unix_password
  }
  elsif $use_ctl_socket == 'inet' {
    $ctl_serverurl = "http://${supervisord::inet_server_hostname}:${supervisord::inet_server_port}"
    $ctl_auth      = $supervisord::inet_auth
    $ctl_username  = $supervisord::inet_username
    $ctl_password  = $supervisord::inet_password
  }

  if $unix_auth and (!$unix_username or !$unix_password) {
    fail('[supervisord] unix_username and unix_password must be defined')
  }

  if $inet_auth and (!$inet_username or !$inet_password) {
    fail('[supervisord] inet_username and inet_password must be defined')
  }

  # Handle deprecated $environment variable
  if $environment { notify {'[supervisord] *** DEPRECATED WARNING ***: $global_environment has replaced $environment':}}
  $_global_environment = $global_environment ? {
    undef   => $environment,
    default => $global_environment
  }

  if $env_var {
    $env_hash = lookup($env_var)
    $env_string = hash2csv($env_hash)
  }
  elsif $_global_environment {
    $env_string = hash2csv($_global_environment)
  }

  if $config_dirs {
    $config_include_string = join($config_dirs, ' ')
  }
  else {
    $config_include_string = "${config_include}/*.conf"
  }

  create_resources('supervisord::eventlistener', $eventlisteners)
  create_resources('supervisord::fcgi_program', $fcgi_programs)
  create_resources('supervisord::group', $groups)
  create_resources('supervisord::program', $programs)

  if $install_pip {
    include supervisord::pip
    Class['supervisord::pip'] -> Class['supervisord::install']
  }

  include supervisord::install, supervisord::config, supervisord::service, supervisord::reload

  anchor { 'supervisord::begin': }
  anchor { 'supervisord::end': }

  Anchor['supervisord::begin']
  -> Class['supervisord::install']
  -> Class['supervisord::config']
  -> Class['supervisord::service']
  -> Anchor['supervisord::end']

  Class['supervisord::service'] -> Supervisord::Program <| |>
  Class['supervisord::service'] -> Supervisord::Fcgi_program <| |>
  Class['supervisord::service'] -> Supervisord::Eventlistener <| |>
  Class['supervisord::service'] -> Supervisord::Group <| |>
  Class['supervisord::service'] -> Supervisord::Rpcinterface <| |>
  Class['supervisord::reload']  -> Supervisord::Supervisorctl <| |>

}
