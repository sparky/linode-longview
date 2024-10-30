package Linode::Longview::DataGetter::Packages::Pacman;

=head1 COPYRIGHT/LICENSE

Copyright 2024, Iskra.  Longview is made available under the terms
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

use Linode::Longview::Util;

our $DEPENDENCIES = [];

{
	my $ver = `pacman -V 2>/dev/null`;
	die "pacman not present" if $?;
}

my $next_run = 0;
my $last_db_update = 0;

sub get
{
	my ( undef, $dataref ) = @_;

	$logger->trace( 'Collecting pacman updates' );

	my $now = time();
	if ( $now > $next_run )
	{
		$next_run = $now + 60;
		$logger->trace( 'Pacman: pulling new package list' );
		system "pacman -Sy >/dev/null 2>&1";
	}

	my $this_db_update = 0;
	foreach my $file ( glob "/var/lib/pacman/sync/*.db" )
	{
		my $mtime = (stat $file)[9];
		$this_db_update = $mtime if $mtime > $this_db_update;
	}

	return $dataref
		unless $this_db_update > $last_db_update;
	$last_db_update = $this_db_update;

	$logger->trace( 'Pacman: checking packages to update' );

	open my $pacman, "-|", "pacman", "-Qu"
		or return $dataref;

	my $packages = $dataref->{INSTANT}->{Packages} = [];
	while ( my $line = <$pacman> )
	{
		chomp $line;
		my ( $name, $current, $arrow, $new, $comment ) = split /\s+/, $line;
		my %update = (
			name => $name,
			current => $current,
			new => $new,
		);
		$update{name} .= " " . $comment
			if length $comment;
		push @$packages, \%update;
	}
	close $pacman;
	return $dataref;
}

1;
