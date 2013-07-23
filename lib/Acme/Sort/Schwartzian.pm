package Acme::Sort::Schwartzian;

use v5.14;

BEGIN {
	$Acme::Sort::Schwartzian::AUTHORITY = 'cpan:TOBYINK';
	$Acme::Sort::Schwartzian::VERSION   = '0.002';
}

use B::Deparse ();
use Eval::TypeTiny;
use Carp qw(croak);
use PadWalker ();

use Parse::Keyword { sort_schwartz => \&_parse_sort_schwartz };

use parent 'Exporter::TypeTiny';
our @EXPORT = 'sort_schwartz';

sub _deparse {
	my $code = shift;
	return (
		'B::Deparse'->new->coderef2text($code),
		PadWalker::closed_over($code),
	);
}

sub _parse_sort_schwartz {
	lex_read_space;
	croak "syntax error" unless lex_peek eq '{';
	my $keyblock = parse_block;
	lex_read_space;
	
	my $op = 'cmp';
	if (lex_peek(4) =~ /^(-?(cmp|<=>))/) {
		$op = $1;
		lex_read(length $op);
		lex_read_space;
	}
	
	my $list = parse_listexpr;
	
	sub { return ($keyblock, $op, $list) };
}

my %sorter = (
	'cmp'     => '$a->[1] cmp $b->[1]',
	'-cmp'    => '$b->[1] cmp $a->[1]',
	'<=>'     => '$a->[1] <=> $b->[1]',
	'-<=>'    => '$b->[1] <=> $a->[1]',
);

sub _compile_sort_schwartz {
	my ($keyblock, $op) = @_;
	my ($transform, $closed_over) = _deparse( $keyblock );
	
	eval_closure(
		environment => $closed_over,
		source      => qq{
			sub {
				return
					map  \$_->[0],
					sort { $sorter{$op} }
					map  [ \$_, do $transform ], \@_;
			}
		},
	);
}

sub sort_schwartz {
	my $list    = pop @_;
	my $closure = _compile_sort_schwartz(@_);
	
	$closure->( $list->() );
}

1;

__END__

=pod

=encoding utf-8

=for stopwords deparsing

=head1 NAME

Acme::Sort::Schwartzian - a keyword that provides sort via a Schwartzian transform

=head1 SYNOPSIS

   use Acme::Sort::Schwarz sort_schwartz => { -as => 'ssort' };
   
   my @sorted = ssort { length($_) } <=> qw(foobar baz quux xyzzy);
   
   print "$_\n" for @sorted;
   
   __END__
   baz
   quux
   xyzzy
   foobar

=head1 DESCRIPTION

This module is mostly just for me to play with L<Parse::Keyword>. In
particular, it's a study of deparsing a coderef captured by Parse::Keyword
and recompiling that into a block of a larger function (along with any
closed over variables). This is a technique that might be useful in the
future for something like L<Sub::Quote>.

It provides the keyword C<sort_schwartz>, but because that's annoying to
type out, you can rename it something else (as shown in the SYNOPSIS).

It implements the Schwartzian transform - i.e. something like this:

   my @sorted =
      map  { $_->[0] }
      sort { $a->[1] cmp $b->[1] }
      map  { [ $_ => func($_) ] }
         @unsorted;

=head2 Keyword

=over

=item C<< sort_schwartz { KEY_BLOCK } OPERATOR? LIST >>

The key block is a block of Perl code that when given a value (in C<< $_ >>)
generates a key to sort by. In other words, it's the C<< func() >> in the
bottom C<map> of the standard Schwatzian transform.

The operator is one of C<cmp> (lexicographic), C<-cmp> (reverse lexicographic),
C<< <=> >> (numeric) or C<< -<=> >> (reverse numeric). If omitted, defaults to
C<< cmp >>.

The list is the list of items to be sorted.

=back

=head1 LIMITATIONS

=over

=item *

This module's acronym is ASS.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Sort-Schwartzian>.

=head1 SEE ALSO

L<Sort::Key>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

