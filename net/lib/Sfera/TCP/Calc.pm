package Sfera::TCP::Calc;
use strict;
use DDP;
use feature "switch";
no warnings 'experimental::smartmatch';

sub TYPE_CALC         {1}
sub TYPE_NOTATION     {2}
sub TYPE_BRACKETCHECK {3}

sub pack_header {
	my $pkg = shift;
	my $type = shift;
	my $size = shift;
	return pack("C S", $type, $size);
}

sub unpack_header {
	my $pkg = shift;
	my $header = shift;
        print "header == $header\n";
	return unpack("C S", $header);
}

sub pack_message {
	my $pkg = shift;
	my $message = shift;
	return pack("A*", $message);
}

sub unpack_message {
	my $pkg = shift;
	my $message = shift;
        return unpack("A*", $message);
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
	
sub IsCorrectBrackets {
	my $expr = shift;
        $expr =~ s/[^()]//g;
        my $count = 0;
        for my $c (split //, $expr) { 
            if( $c eq '(' ) { $count++; }
            elsif( $c eq ')' ) { $count--; }        
            if ($count < 0) { return -1; }
       }
    $count == 0 ? 1 : 0;
}

sub ChangeExpr {
	my $expr = shift;	
	$expr =~ s/\*\*/^/g; #substitute potential
	$expr =~ s/([\+\-\*\/\^\(\)])/ $1 /g; #insert spaces around each operator
	$expr =~ s/^\s+|\s+$//g; #trim string
	$expr =~ s/ +/ /g;
	$expr =~ s/[eE]\s*(\+|\-)\s*/e$1/g;#substitute unary operation
	$expr =~ s/^([\+\-]) ([0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/$1$2/g;
	$expr =~ s/(\(|\+|\-|\*|\/|\^) ([\+\-]) ([0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/$1 $2$3/g;
	return $expr;
}

sub PolishNotation {
	my $brackets = IsCorrectBrackets(@_);
	#print "br  ", $brackets, $/;
	if ($brackets) {
		my @ops_stack;
   		my @output;
    		my @tokens = split(' ', ChangeExpr(@_));
   		foreach my $token (@tokens) {
        		given ($token) {
            			when (/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) {
               				push @output, $token;
            			}
            			when ( ")" ) {
                			ProcessBracket(\@output, \@ops_stack);
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
	return @output;
	}
	else {
		return "error";
	}
}

sub ProcessBracket {
    my $output = $_[0];
    my $ops_stack = $_[1];
    my $head = pop @$ops_stack;
    while( $head ne "(" ) {
       push @$output, $head;
       $head = pop @$ops_stack;
    }
}

sub Counting {
	my $output = $_[0];
	my @result;
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

sub GetPolishNotation {
	return join(' ', PolishNotation(shift));
}

sub Calculation {
	my @polishnot = PolishNotation(shift);
	return Counting(\@polishnot);
}


sub request {
    my $type = shift;
    my $expr = shift;
    given ($type) {
        when (1) { Calculation($expr); }
        when (2) { IsCorrectBrackets($expr); }
        when (3) { GetPolishNotation($expr); }
        default { return 'Unknown type'; }
    }
}

1;
