use 5.010;
use warnings;
use strict;
use DDP;
use Calc;
use Sfera::TCP::Calc::Server;

Sfera::TCP::Calc::Server::start_server(1, 8081);

# $SIG{'USR2'} = 'inc_requests_count';
# my $requests_count = 0;

# sub inc_requests_count {
#     $requests_count++;
#     print $requests_count."\n";
# }





__END__
use 5.10.0;
use warnings;
use strict;
use DDP;
use Calc;

use IO::Socket;
use IO::Socket qw/getnameinfo/;



my $requests_count = 0;
sub inc_requests_count {
    $requests_count++;
    print $requests_count."\n";
}
$SIG{'USR2'} = 'inc_requests_count';

my $server = IO::Socket::INET->new(
    LocalPort => 8081,
    Type => SOCK_STREAM,
    ReuseAddr => 1,
    Listen => 10);

my $max_children_count = 2;

my $children_count = 0;

my $parent_pid = $$;

while(1) {
    say "loop";
    sleep(1);
    my $client = $server->accept();
    p $client;
    next unless defined $client;
    say "childcount $children_count";
    if($children_count >=  $max_children_count){
        wait();
        $children_count--;
    };
    
    my $child = fork();
    if($child){
        $children_count++;
        print("child $child\n");
        close ($client); next;
    }

    if(defined $child){
        close($server);
        my $other = getpeername($client);
        my ($err, $host, $service)= getnameinfo($other);
        print "Client $host:$service $/";
        $client->autoflush(1);
        my $message;
        while(1){
            say "recv 1";
            my $req_header = read_data($client, 3);
            
            last unless defined $req_header;
            my ($type, $req_size) = Sfera::TCP::Calc::unpack_header(1, $req_header);
            p $type;
            p $req_size;
            my $req_message = read_data($client, $req_size);
            say "recv 2";
            last unless defined $req_message;
            my $expr = Sfera::TCP::Calc::unpack_message(1, $req_message);
            my $result = Sfera::TCP::Calc::request($type, $expr);
            say "expr = $expr, result = $result";
            my $resp_message = Sfera::TCP::Calc::pack_message(1, $result);
            my $resp_header = Sfera::TCP::Calc::pack_header(1, $type, length($resp_message));

            $client->send($resp_header);
            $client->send($resp_message);
        }
        close ($client);
        exit();
    } else { die "Can't fork: $!"; }
}

print "not accepted";

sub read_data {
    my $socket = shift;
    my $size = shift;
    my $data;
    my $bytes_read = $socket->sysread($data, $size);

    if (not defined $bytes_read)
    {
        die "ack!  error on the socket\n";
    }
    
    elsif ($bytes_read == 0)
    {
        print "the socket was closed\n";
        return undef;
    }
    print "woo hoo!  I read $bytes_read bytes from the socket... $data\n";
    return $data;
}



# Sfera::TCP::Calc::pack_header(1,2,3);

# my $d = Sfera::TCP::Calc::request(3, "()(()");
# p $d;

