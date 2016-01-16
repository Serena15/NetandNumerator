package Sfera::TCP::Calc::Server;
use 5.010;
use strict;
use warnings;
use Sfera::TCP::Calc;
use DDP;
use POSIX ":sys_wait_h";

use IO::Socket;
use IO::Socket qw/getnameinfo/;

our $max_children_count = 5;
our $requests_count = 0;
our $children_count = 0;
our $terminate = 0;

BEGIN { our $start_time = time(); }

$SIG{CHLD} = \&dec_children_count;

$SIG{USR1} = \&print_stats;

$SIG{USR2} = sub { $requests_count++; };

$SIG{INT} = sub { $terminate = 1; };

END {
    while ($children_count) {
        wait();
        $children_count--;
    }
}

sub print_stats {
    say "$children_count connected client(s)";
    say "$requests_count request(s) processed";
    my $run_time = time() - our $start_time;
    print "Job took $run_time seconds\n";
}

sub dec_children_count {
    while ((waitpid(-1, WNOHANG)) > 0) {
        $children_count--;
    }
}



sub start_server {
    my $pkg = shift;
    my $port = shift;

    my $server = IO::Socket::INET->new(
        LocalPort => $port,
        Type => SOCK_STREAM,
        ReuseAddr => 1,
        Listen => 5,
        );


    my $parent_pid = $$;

    while( !$terminate ) {
        say "loop";
        my $client = $server->accept();

        next unless defined $client;

        say "childcount $children_count";

        if($children_count > $max_children_count){
            close($client);
            next;
        };
        
        my $child = fork();
        if($child){
            $children_count++;
            close ($client);
            next;
        }

        if(defined $child){
            close($server);
            my $other = getpeername($client);
            my ($err, $host, $service)= getnameinfo($other);
            print "Client $host:$service $/";
            $client->autoflush(1);
            my $message;
            while(1){
                my $req_header = read_data($client, 3);
                last unless defined $req_header;
                warn("server read1");
                my ($type, $req_size) = Sfera::TCP::Calc::unpack_header(1, $req_header);
                
                my $req_message = read_data($client, $req_size);
                last unless defined $req_message;
                warn("server read2");
                my $expr = Sfera::TCP::Calc::unpack_message(1, $req_message);

                my $result = Sfera::TCP::Calc::request($type, $expr);

                my $resp_message = Sfera::TCP::Calc::pack_message(1, $result);
                my $resp_header = Sfera::TCP::Calc::pack_header(1, $type, length($resp_message));
                warn("server send1");
                
                my $bytes_sent = $client->syswrite($resp_header);
                return unless defined $bytes_sent;
                $bytes_sent = $client->syswrite($resp_message);
                return unless defined $bytes_sent;
                warn("server send2");

                kill USR2 => $parent_pid;
            }
            close ($client);
            exit(1);
        } else { die "Can't fork: $!"; }
    }
}

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



1;

