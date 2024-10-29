package Linode::Longview::Logger;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw($levels);

use File::Path;
use POSIX 'strftime';

our $levels = {
    trace  => 6,
    debug  => 5,
    info   => 4,
    warn   => 3,
    error  => 2,
    fatal  => 1,
    logdie => 0,
};
# emerg   0 # red
# alert   1 # red
# crit    2 # red
# err     3 # red
# warning 4 # yellow
# notice  5 # highlighted
# info    6 # plain
# debug   7 # grey
my %syslog = (
	trace => 7,
	debug => 7,
	info  => 6,
	warn  => 5,
	error => 4,
	fatal => 3,
	logdie => 2,
);

foreach my $type ( keys %$levels )
{
	no strict 'refs';
	my $level = $levels->{ $type };
	my $syslog_level = $syslog{ $type };
	*{$type} = sub {
		my ( $self, $message ) = @_;

		chomp $message;
		printf( "<%d>%s\n", $syslog_level, $message )
			if $level <= $self->{level};
		die "$message" if $type eq 'logdie';
	};
}

sub new {
    my ( $class, $level ) = @_;
    my $self = {
	    level => $level,
    };

    return bless $self, $class;
}

sub level {
	my ( $self, $level ) = @_;
	$self->{level} = $level;
}

1;
