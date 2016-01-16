use 5.010;
use warnings;
use strict;
use DDP;
use Calc;
use Sfera::TCP::Calc::Client;

use IO::Socket::INET;

my $socket = Sfera::TCP::Calc::Client::set_connect(1, 'localhost', 8081);

my $res = Sfera::TCP::Calc::Client::do_request(1, $socket, 1,  "2 + 2 * 2");
p $res;
$res = Sfera::TCP::Calc::Client::do_request(1, $socket, 1,  "2 + 2 * 3");
p $res;

    
close($socket);