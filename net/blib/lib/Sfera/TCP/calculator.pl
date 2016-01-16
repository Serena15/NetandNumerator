#!/usr/bin/perl

use strict;
use warnings;
use DDP;
use feature "switch";
no warnings 'experimental::smartmatch';

sub process_bracket {
    my $output = $_[0];
    my $ops_stack = $_[1];

    my $head = pop @$ops_stack;

    while( $head ne "(" ) {
       push @$output, $head;
       $head = pop @$ops_stack;
    }
}

sub calc {
    my $output = $_[0];
    my @result;
    # p $output;
    foreach my $token (@$output) {
        my $c = $token;
        if ($token =~ /^[\+\*\^\/\-]$/) {
            my $r = pop @result;
            my $l = pop @result;

            given ($token) {
                when ("+") { $c = $l + $r;  }
                when ("-") { $c = $l - $r;  }
                when ("*") { $c = $l * $r;  }
                when ("/") { $c = $l / $r;  }
                when ("^") { $c = $l ** $r; }
            }

        }
        push @result, $c;
    }
    return $result[0];
}

my %PRIORITY = (
    "("  => 5,
    ")"  => 5,
    "**" => 2,
    "^"  => 2,
    "*"  => 3,
    "/"  => 3,
    "+"  => 4,
    "-"  => 4
);

my @ops_stack;
my @output;
#my $expr = "-16+(2)*0.3e+2-.5**(2-3)";
my $expr = <>;

$expr =~ s/\*\*/^/g; #substitute potential

$expr =~ s/([\+\-\*\/\^\(\)])/ $1 /g; #insert spaces around each operator

$expr =~ s/^\s+|\s+$//g; #trim string
$expr =~ s/ +/ /g;

$expr =~ s/[eE]\s*(\+|\-)\s*/e$1/g; #deal with scientific notation

#substitute unary op at the beginning
$expr =~ s/^([\+\-]) ([0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/$1$2/g;

#substitute unary op
$expr =~ s/(\(|\+|\-|\*|\/|\^) ([\+\-]) ([0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/$1 $2$3/g;


my @tokens = split(/ /, $expr);

foreach my $token (@tokens) {
    given ($token){
        when (/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) {
            push @output, $token;
        }
        when ( ")" ) {
            process_bracket(\@output, \@ops_stack);
        }
        when ( "(" ) {
            push @ops_stack, $token;
        }
        default {
            my $cur_priority = $PRIORITY{$token};
            while ( @ops_stack and $PRIORITY{ $ops_stack[-1] } <= $cur_priority ) {
                if ( $token eq '^' and $PRIORITY{ $ops_stack[-1] } == $cur_priority ) {
                    last;
                }
                push @output, pop @ops_stack;
            }
            push @ops_stack, $token;
        }

    }

}


while(@ops_stack){
    push @output, pop @ops_stack;
}

my $rev_polish_notation = join(' ', @output);
my $result = calc(\@output);

print "Expression: $expr\n";
print "Reverse polish notation: $rev_polish_notation\n";
print "Result = $result\n";

