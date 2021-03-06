package PerlIO::via::Numerator;
use 5.010;
use strict;
use warnings;
use Fcntl 'SEEK_CUR';
use DDP;


sub PUSHED {	
	my ($class, $mode) = @_;
	my $obj = {fh => undef, mode => undef, line => 1, seeked => undef};
	if($mode eq 'w') {
            $obj->{mode} = '>';
	}
	elsif($mode eq 'r') {
            $obj->{mode} = '<';
	}
        elsif($mode eq 'a') {
            $obj->{mode} = '>>';
        }
        elsif($mode eq 'r+') {
            $obj->{mode} = '+<';
        }
        elsif($mode eq 'w+') {
            $obj->{mode} = '+>';
        }
	else {
            die $mode." not supported in PerlIO::via::Numerator";
	}
	return bless $obj,$class;
}

sub OPEN {
	my ($obj, $path, $mode) = @_;
	$obj->{path} = $path;
	my $t = open($obj->{fh}, $obj->{mode}, $obj->{path});
        if ($obj->{mode} eq '>>') {
            my $last;
            my $fh;
            open($fh, $path);
            while (<$fh>) { $last = $_;}
            close $fh;
            $last =~ s/(\d+) .*/$1/;
            $obj->{line} = $last + 1;
        }
        return $t;
}

sub FILL {
	my ($obj) = @_;
	my $fh = $obj->{fh};
        my $line = <$fh>;
        $obj->{seeked} = 0;
        return undef unless defined $line;
        $line =~ s/\d+ (.*)/$1/;
        return $line;
}

sub SEEK {
    my ($obj, $pos, $whence) = @_;
    $obj->{seeked} = 1;
    return seek($obj->{fh}, $pos, $whence);
}

sub WRITE {
	my ($obj, $buf) = @_;
        my $length = 0;
        $obj->{buf} .= $buf;
        my $fh = $obj->{fh};
	foreach (split m#(?<=$/)#, $obj->{buf}) {
            my $last_char = substr $_, -1;
            if ($last_char eq "\n") {
                if (!$obj->{seeked}) {
                    print $fh sprintf("%d %s", $obj->{line}, $_);
                    $obj->{line}++;
                }
                $length += length;
                substr($obj->{buf}, 0, length, '')
            }
	}
        if ($obj->{seeked}) {
            print $fh $buf;
            $length = length($buf);
            substr($obj->{buf}, 0, $length, '')
        }
        elsif (!eof($fh)) {
            my $pos = tell($fh);
            my $line = <$fh>;
            $line =~ s/(\d+).*/$1/;
            seek($fh, $pos, 0);
            print $fh sprintf("%d %s", $line, $buf);
            $length = length($buf);
            substr($obj->{buf}, 0, $length, '')
        }
        $obj->{seeked} = 0;
	return length;
}

sub FLUSH {
     	my ($obj) = @_;
        print {$obj->{fh}} sprintf("%d %s", $obj->{line}, $_) if $obj->{buf} or return -1;
        $obj->{line}++;
        $obj->{buf} = "";
        return 0;
}

1;
