class icecast
(
	$sourcePass = hiera('icecast::authentication::source-password'),
	$relayUser = hiera('icecast::authentication::relay-user'),
	$relayPass = hiera('icecast::authentication::relay-password'),
	$adminUser = hiera('icecast::authentication::admin-user'),
	$adminPass = hiera('icecast::authentication::admin-password'),

	$limitClients = hiera('icecast::limit::clients',undef),
	$limitSources = hiera('icecast::limit::sources',undef),
	$limitQueueSize = hiera('icecast::limit::queue-size',undef),
	$limitClientTimeout = hiera('icecast::limit::client-timeout',undef),
	$limitHeaderTimeout = hiera('icecast::limit::header-timeout',undef),
	$limitSourceTimeout = hiera('icecast::limit::source-timeout',undef),
	$limitBurstOnConnect = hiera('icecast::limit::burst-on-connect',undef),
	$limitBurstSize = hiera('icecast::limit::burst-size',undef),

	$loggingAccessLog = hiera('icecast::logging::accesslog','access.log'),
	$loggingErrorLog = hiera('icecast::logging::errorlog','error.log'),
	$loggingPlaylistLog = hiera('icecast::logging::playlistlog','playlist.log'),
	$loggingLogSize = hiera('icecast::logging::logsize',10000),
	$loggingLogArchive = hiera('icecast::logging::logarchive',false),
	$loggingLogLevel = hiera('icecast::logging::loglevel',3),

	$ypDir = hiera_hash('icecast::directory',{}),
	$miscFileServe = hiera('icecast::misc::file-serve',1),
	$miscHostname = hiera('icecast::misc::hostname',$fqdn),
	$miscListenSocket = hiera_array('icecast::listen-socket',[]),

#$masterServer = hiera('icecast::relay::master',undef),
	$relays = hiera('icecast::relays',[]),
	$mounts = hiera('icecast::mounts',[]),

	$allowIp = hiera('icecast::address::allow',undef), #fixme
	$denyIp = hiera('icecast::address::deny',undef), #fixme

	$aliases = hiera_hash('icecast::path::aliases',{}),

	$pathConfig = hiera('icecast::path::config','/etc/icecast2/icecast.xml'),
	$uid = hiera('icecast::uid', 'icecast2'),
	$gid = hiera('icecast:gid', 'icecast'),

	$securityChroot = hiera('icecast::security::chroot',0),

	$pathsBaseDir = hiera('icecast::paths::basedir','/usr/share/icecast2'),
	$confLogDir = hiera('icecast::paths::logdir',undef),
	$confWebRoot = hiera('icecast::paths::webroot',undef),
	$confAdminRoot = hiera('icecast::paths::adminroot',undef),
	$confPidFile = hiera('icecast::paths::pidfile',undef),
)
{
	if $securityChroot {
		$startUid = "root"
		$startGid = "root"
		$endUid = $uid
		$endGid = $gid
		$pathsLogDir = $confLogDir ? { undef => "/log", default => $confLogDir }
		$pathsWebRoot = $confWebRoot ? { undef => "/web", default => $confWebRoot }
		$pathsAdminRoot = $confAdminRoot ? { undef => "/admin", default => $confAdminRoot }
		$pathsPidFile = $confPidFile ? { undef => "/icecast.pid", default => $confPidFile }
		$realLogDir = "${pathsBaseDir}/${pathsLogDir}"
		$realWebRoot = "${pathsBaseDir}/${pathsWebRoot}"
		$realAdminRoot = "${pathsBaseDir}/${pathsAdminRoot}"
		$realPidFile = "${pathsBaseDir}/${pathsPidFile}"
	} else {
		$startUid = $uid
		$startGid = $gid
		$endUid = $uid
		$endGid = $gid
		$pathsLogDir = $confLogDir ? { undef => "${pathsBaseDir}/log", default => $confLogDir }
		$pathsWebRoot = $confWebRoot ? { undef => "${pathsBaseDir}/web", default => $confWebRoot }
		$pathsAdminRoot = $confAdminRoot ? { undef => "${pathsBaseDir}/admin", default => $confAdminRoot }
		$pathsPidFile = $confPidFile ? { undef => "${pathsBaseDir}/icecast.pid", default => $confPidFile }
		$realLogDir = $pathsLogDir
		$realWebRoot = $pathsWebRoot
		$realAdminRoot = $pathsAdminRoot
		$realPidFile = $pathsPidFile
	}

	case $operatingsystem {
		debian: { include icecast::debian }
		default: { fail("This module wasn't tested under your OS.") }
	}

	package { 'icecast2':
		ensure => latest,
	}

	user { $startUid:
		require => Package['icecast2'],

		ensure => present,
		gid => $endGid,
		name => $endUid,
		provider => useradd,
		system => true,
		shell => '/bin/false',
	}

	if $allowIp {
		file { $allowIp:
			require => User[$startUid],
			notify => Service['icecast2'],

			ensure => file,
			mode => 660
		}
	}

	if $denyIp {
		file { $denyIp:
			require => User[$startUid],
			notify => Service['icecast2'],

			ensure => file,
			mode => 660
		}
	}



	file { $pathConfig:
		require => User[$startUid],

		ensure => file,
		mode => 660,
		owner => $startUid,
		group => $startGid,
		content => template("icecast/icecast.xml.erb"),
	}

	file { $pathsBaseDir:
		require => User[$endUid],

		ensure => directory,
		owner => $endUid,
		group => $endGid,
		mode => 750
	}

	file { $realLogDir:
		require => User[$endUid],

		ensure => directory,
		owner => $endUid,
		group => $endGid,
		mode => 750
	}

	file { $realWebRoot:
		require => User[$endUid],

		ensure => directory,
		owner => $endUid,
		group => $endGid,
		mode => 750
	}

	file { $realAdminRoot:
		require => User[$endUid],

		ensure => directory,
		owner => $endUid,
		group => $endGid,
		mode => 750
	}

	file { $realPidFile:
		require => User[$endUid],

		ensure => file,
		owner => $startUid,
		group => $startGid,
		mode => 640
	}

	file { "${realWebRoot}/listen.pls":
		require => User[$endUid],

		ensure => file,
		owner => $endUid,
		group => $endGid,
		mode => 744,
		content => template("icecast/listen.pls.erb"),
	}


	if $operatingsystem == 'debian' {
		file { '/etc/default/icecast2':
			require => Package['icecast2'],
			notify  => Service['icecast2'],

			ensure => file,
			mode => 644,
			content => template("icecast/icecast2.erb"),
		}
	}

	service { 'icecast2':
		require => File[$pathConfig],

		ensure    => running,
		enable    => true,
		hasrestart=> true,
		hasstatus => false,
		subscribe => File[$pathConfig],
	}
}
