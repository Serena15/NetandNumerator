use 5.010;
use warnings;
use strict;
use DDP;
use Sfera::TCP::Calc::Client;
use Test::More tests => 1;
use Test::TCP;
use Sfera::TCP::Calc::Server;

my $server = Test::TCP->new(
	code => sub {
		my $port = shift;
		Sfera::TCP::Calc::Server->start_server($port);
	},
);
my @servers;
push @servers, Sfera::TCP::Calc::Client->set_connect('127.0.0.1', $server->port) for 1..10;
#p @servers;
is(scalar(grep {eval {Sfera::TCP::Calc::Client->do_request($_, 1, '( 1 + 2 ) * 1'); 1}} @servers), 5, 'Process count');
done_testing();
