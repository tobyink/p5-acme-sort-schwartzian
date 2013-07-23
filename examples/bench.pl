use v5.14;
use Benchmark qw(cmpthese);
use List::Util qw(shuffle);
use Digest::MD5 qw();
use Test::Deep::NoTest qw(eq_deeply);

our @unsorted = shuffle( 1..10000 );

# NonSchwartzian needs to assign to a temp array to prevent Perl from doing
# an in-place sort. In the interest of fairness, we do the same for the others.
#
my %routines  = (
	# Naive sorting
	NonSchwartzian => q{
		my @tmp = sort { Digest::MD5::md5_hex($b) cmp Digest::MD5::md5_hex($a) } @::unsorted;
	},
	# The traditional Schwartzian transform
	TradSchwartz => q{
		my @tmp = map { $_->[0] } sort { $b->[1] cmp $a->[1] } map { [ $_ => Digest::MD5::md5_hex($_) ] } @::unsorted;
	},
	# Optimized version avoiding unnecessary lexical scopes
	TradSchwartzNB => q{
		my @tmp = map $_->[0], sort { $b->[1] cmp $a->[1] } map [ $_ => Digest::MD5::md5_hex($_) ], @::unsorted;
	},
	# Using Acme::Sort::Schwartzian
	ASS => q{
		use Acme::Sort::Schwartzian;
		my @tmp = sort_schwartz { Digest::MD5::md5_hex($_) } -cmp @::unsorted;
	},
	# Using Sort::Key (XS-based)
	SortKey => q{
		use Sort::Key 'rkeysort';
		my @tmp = rkeysort { Digest::MD5::md5_hex($_) } @::unsorted;
	},
);

for my $r (sort keys %routines)
{
	eq_deeply [ eval $routines{$r} ], [ eval $routines{'NonSchwartzian'} ]
		or die "Routine '$r' broken!";
}

cmpthese(20, \%routines);

__END__
                 Rate NonSchwartzian TradSchwartz     ASS TradSchwartzNB SortKey
NonSchwartzian 1.66/s             --         -66%    -66%           -67%    -88%
TradSchwartz   4.91/s           196%           --     -0%            -1%    -64%
ASS            4.94/s           198%           0%      --            -0%    -64%
TradSchwartzNB 4.96/s           199%           1%      0%             --    -64%
SortKey        13.7/s           725%         179%    177%           176%      --
