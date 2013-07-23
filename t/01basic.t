=pod

=encoding utf-8

=head1 PURPOSE

Test that Acme::Sort::Schwartzian works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Acme::Sort::Schwartzian sort_schwartz => { -as => 'S' };

is_deeply(
	[ S { length($_) } <=> qw/ foobar baz quux xyzzy / ],
	[ qw( baz quux xyzzy foobar ) ]
);

is_deeply(
	[ S { length($_) } -<=> qw/ foobar baz quux xyzzy / ],
	[ reverse qw( baz quux xyzzy foobar ) ]
);

my $foo = [0];

is_deeply(
	[ S { $foo->[0]++; $_ } cmp qw/ foobar baz quux xyzzy / ],
	[ qw( baz foobar quux xyzzy ) ]
);

is($foo->[0], 4);

is_deeply(
	[ S { $foo->[0]++; $_ } -cmp qw/ foobar baz quux xyzzy / ],
	[ reverse qw( baz foobar quux xyzzy ) ]
);

is($foo->[0], 8);

is_deeply(
	[ S { $foo->[0]++; $_ } qw/ foobar baz quux xyzzy / ],
	[ qw( baz foobar quux xyzzy ) ]
);

is($foo->[0], 12);

done_testing;

