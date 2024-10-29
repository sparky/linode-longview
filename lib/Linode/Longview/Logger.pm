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
my %colour = (
	trace  => [ "[trace] ", "<7>", "\033[90m", ], # grey
	debug  => [ "[debug] ", "<7>", "\033[90m", ], # grey
	info   => [ "[info]  ", "<6>", "",         ], # normal
	warn   => [ "[warn]  ", "<5>", "\033[1m",  ], # bold
	error  => [ "[error] ", "<4>", "\033[93m", ], # yellow
	fatal  => [ "[fatal] ", "<3>", "\033[31m", ], # red
	logdie => [ "[DIE]   ", "<2>", "\033[31m", ], # red
	end    => [ "\n",       "\n",  "\033[0m\n", ],
);

{
	my $colour_mode = 0;
	if ( -t STDOUT )
	{
		# If this is a TTY use ANSI codes. Ideally, we should also check
		# terminal capabilities, but it is unlikely one will not know
		# those simple codes.
		$colour_mode = 2;
	}
	elsif ( length $ENV{JOURNAL_STREAM} )
	{
		# Not a tty? systemd will set the JOURNAL_STREAM environment
		# variable. Ideally we should check weather there is something
		# at the other end of the stream listening. That env variable
		# might be a "ghost".
		$colour_mode = 1;
	}

	my $suffix = $colour{end}[ $colour_mode ];
	foreach my $type ( keys %$levels )
	{
		no strict 'refs';
		my $level = $levels->{ $type };
		my $prefix = $colour{ $type }[ $colour_mode ];
		my $fmt = "$prefix%s$suffix";
		*{$type} = sub {
			my ( $self, $message ) = @_;

			chomp $message;
			STDOUT->printf( $fmt, $message )
				if $level <= $self->{level};
			STDOUT->flush();
			die "$message" if $type eq 'logdie';
		};
	}
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
