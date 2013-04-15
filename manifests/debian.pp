class icecast::debian {
define install($file = $title) {
	$installdir = '/etc/icecast2'
	$basedir = '/usr/share/icecast2'

	file{ "${basedir}/${file}":
		ensure => file,
		source => "${installdir}/${file}",
		owner => $endUid,
		group => $endGid,
		mode => 0550,
		replace => true
	}

	file{ "${installdir}/${file}":
		require => File["${basedir}/${file}"],

		ensure => absent,
	}
	file { '/etc/default/icecast2':
		require => Package['icecast2'],
		notify  => Service['icecast2'],

		ensure => file,
		mode => 644,
		content => template("icecast/etc/default/icecast2"),
	}
}

/*
install { [
	"admin/manageauth.xsl",
	"admin/stats.xsl",
	"admin/updatemetadata.xsl",
	"admin/xspf.xsl",
	"admin/moveclients.xsl",
	"admin/listmounts.xsl",
	"admin/listclients.xsl",
	"admin/response.xsl",
	"web/auth.xsl",
	"web/server_version.xsl",
	"web/status2.xsl",
	"web/status.xsl",
	"web/style.css",
]: }
*/
}
