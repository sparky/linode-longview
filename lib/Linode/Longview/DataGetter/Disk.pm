package Linode::Longview::DataGetter::Disk;

=head1 COPYRIGHT/LICENSE

Copyright 2013 Linode, LLC.  Longview is made available under the terms
of the Perl Artistic License, or GPLv2 at the recipients discretion.

=head2 Perl Artistic License

Read it at L<http://dev.perl.org/licenses/artistic.html>.

=head2 GNU General Public License (GPL) Version 2

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

See the full license at L<http://www.gnu.org/licenses/>.

=cut

use strict;
use warnings;

use Linode::Longview::Util qw(:BASIC);
use Cwd 'abs_path';
use Filesys::Df;

our $DEPENDENCIES = [];

my %sector_size_cache;
my sub get_sector_size
{
	my ( $device ) = @_;
	do
	{
		my $sector_size = slurp_file( "/sys/block/$device/queue/hw_sector_size" );
		return $sector_size if $sector_size;
		chop $device;
	} while ( length $device );

	my $default = 512;
	$logger->warn( "No sector size for device $_[0]. Defaulting to $default" );
	return $default;
}

sub get
{
	my ( undef, $dataref ) = @_;
	$logger->trace( 'Collecting Disk info' );

	my $mapping = _get_mounted_info($dataref);

	# get the information from /proc/diskstats
	my @diskstats = slurp_file( $PROCFS . 'diskstats' )or do {
		$logger->info( "Couldn't read ${PROCFS}diststats: $!" );
		return $dataref;
	};

	my %dev_mapper;
	foreach my $line ( @diskstats )
	{
		#  202 0 xvda 3125353 13998 4980 2974 366 591 760 87320 15 366 9029
		my ( undef, $major, $minor, $device,
			$reads, $reads_merged, $read_sectors, $read_time,
			$writes, $writes_merged, $write_sectors, $write_time ) = split /\s+/, $line;

		my $name = $mapping->{ '/dev/' . $device }
			or next;

		my $sector_size = $sector_size_cache{ $device } //= get_sector_size( $device );

		my $read_bytes = $read_sectors * $sector_size;
		my $write_bytes = $write_sectors * $sector_size;

		$dataref->{LONGTERM}->{"Disk.$name.reads"}  = $reads + 0;
		$dataref->{LONGTERM}->{"Disk.$name.writes"} = $writes + 0;
		$dataref->{LONGTERM}->{"Disk.$name.read_bytes"}  = $read_bytes + 0;
		$dataref->{LONGTERM}->{"Disk.$name.write_bytes"} = $write_bytes + 0;
	}

	return $dataref;
}

sub _get_mounted_info
{
	my $dataref = shift;

	my @mtab = slurp_file('/etc/mtab') or do {
		$logger->info("Couldn't read /etc/mtab: $!");
		return $dataref;
	};
	my %mapping;
	foreach my $line ( grep m#^/#, @mtab )
	{
		my ( $device, $mountpoint ) = split /\s+/, $line;
		next unless $device and $mountpoint;

		if ( $device eq '/dev/root' )
		{
			my $root_dev = slurp_file($PROCFS . 'cmdline');
			($device) = ($root_dev =~ m|root=(\S+)|);
			$device = "/dev/disk/by-uuid/$1"
				if $device =~ /UUID=([0-9a-f-]*)/;
		}

		# This will resolve the symlinks
		$device = abs_path( $device );

		# Gather the FS usage data
		my $df = df( $mountpoint, 1 );

		# Escape all the dots
		my $name = $mountpoint =~ s/\./\\\./gr;
		$mapping{ $device } = $name;

		$dataref->{LONGTERM}->{"Disk.$name.fs.free"}   = $df->{bfree}
			if defined $df->{bfree};
		$dataref->{LONGTERM}->{"Disk.$name.fs.total"}  = $df->{blocks}
			if defined $df->{blocks};
		$dataref->{LONGTERM}->{"Disk.$name.fs.ifree"}  = $df->{ffree}
			if defined $df->{ffree};
		$dataref->{LONGTERM}->{"Disk.$name.fs.itotal"} = $df->{files}
			if defined $df->{files};
		$dataref->{INSTANT}->{"Disk.$name.fs.path"}    = $mountpoint;
		$dataref->{INSTANT}->{"Disk.$name.mounted"}    = 1;
	}

	return \%mapping;
}

1;
