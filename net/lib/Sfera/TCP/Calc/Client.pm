package Sfera::TCP::Calc::Client;

use 5.010;
use warnings;
use strict;
use IO::Socket::INET;
use Sfera::TCP::Calc;

use DDP;



sub set_connect {
	my $pkg = shift;
	my $ip = shift;
	my $port = shift;
        my $socket = new IO::Socket::INET (
            PeerHost => $ip,
            PeerPort => $port,
            Proto => 'tcp',
            Type => SOCK_STREAM,
            );
        die "Cannot connect to the server $!\n" unless $socket;
    $socket->autoflush();
	return $socket;
}

sub do_request {
	my $pkg = shift;
	my $server = shift;
	my $req_type = shift;
        my $req_message = shift;
	
        my $req_message_packed = Sfera::TCP::Calc->pack_message($req_message);
        my $req_header_packed = Sfera::TCP::Calc->pack_header($req_type, length($req_message_packed));
        say $req_header_packed, length($req_header_packed);

        my $bytes_sent = syswrite($server, $req_header_packed.$req_message_packed);
        warn "Client send_all ", $bytes_sent, $server->connected();

        return unless defined $bytes_sent;
           # $bytes_sent = syswrite($server, $req_message_packed);
           # warn "client send 2";
           # return unless defined $bytes_sent;
        my $resp_header_packed, my $resp_message_packed;
        my $bytes_read = sysread($server, $resp_header_packed, 3);

        warn "Client read_header ",  $bytes_read;
        return unless defined $bytes_read;
        my ($resp_type, $size) = Sfera::TCP::Calc->unpack_header($resp_header_packed);
        $bytes_read = sysread($server, $resp_message_packed, $size);
        warn "Client read_message ";
        return unless defined $bytes_read;

        return Sfera::TCP::Calc->unpack_message($resp_message_packed);
}

1;

