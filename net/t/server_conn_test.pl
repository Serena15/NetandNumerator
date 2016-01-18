use 5.010;
use warnings;
use strict;
use DDP;
#use Calc;
use Sfera::TCP::Calc::Server;

Sfera::TCP::Calc::Server::start_server(1, 8081);
