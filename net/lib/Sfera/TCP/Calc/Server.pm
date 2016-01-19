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

$SIG{INT} = sub { $terminate = 1; 
print "This is stopped \n";
die "Close all clients \n";
};

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

    while(!$terminate) {
        say "loop";        
	my $client = $server->accept();
	if(!$client) {
		next;
	}
	#say "$terminate";	
        next unless defined $client;

        say "Childcount $children_count";

        if($children_count >= $max_children_count) {
            close($client);
            next;
        };
        
        my $child = fork();
        if($child) {
            $children_count++;
            close ($client);
            next;
        }

        if(defined $child) {    
	    close($server);        
            my $other = getpeername($client);
            my ($err, $host, $service)= getnameinfo($other);
            print "Client $host:$service $/";
            $client->autoflush(1);
            while(1) {
                my $req_header = read_data($client, 3);
                last unless defined $req_header;
                warn("Server read_header");
                my ($type, $req_size) = Sfera::TCP::Calc::unpack_header(1, $req_header);
                
                my $req_message = read_data($client, $req_size);
                last unless defined $req_message;
                warn("Server read_message");
                my $expr = Sfera::TCP::Calc::unpack_message(1, $req_message);

                my $result = Sfera::TCP::Calc::request($type, $expr);

                my $resp_message = Sfera::TCP::Calc::pack_message(1, $result);
                my $resp_header = Sfera::TCP::Calc::pack_header(1, $type, length($resp_message));
                warn("Server send_header and message");
                
                my $bytes_sent = $client->syswrite($resp_header.$resp_message);
                return unless defined $bytes_sent;
		if($bytes_sent != length($resp_header) + length($resp_message)) {
			die "Can't write from server\n";
		}

                kill USR2 => $parent_pid;
            }
            close ($client);
	    warn "Client was closed";
            exit(1);
        } else { die "Can't fork: $!"; }
    }
}

sub read_data {
    my $socket = shift;
    my $size = shift;
    my $data;
    my $bytes_read = $socket->sysread($data, $size);
    
    if (not defined $bytes_read) {
        #die "Undefined data on the socket\n";
	print "Undefined data on the socket\n";
	return undef;
    }    
    elsif( $bytes_read != $size) {
		#die "Can't read to server\n";
		print "Can't read to server\n";
		return undef;
	}
    print "Reading $bytes_read bytes from the socket... $data\n";
    return $data;
}



1;

