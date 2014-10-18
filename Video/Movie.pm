package Video::Movie;
{
    use strict;
    use warnings FATAL => qw(all);

    use namespace::autoclean;

    use Moose;
    use MooseX::StrictConstructor;
    use Params::Validate qw(:all);
	use LWP::Simple;

    with 'MooseX::Log::Log4perl';
    extends 'Video::AbstractVideo';

    has 'url' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'http://www.omdbapi.com/'
    );

    sub BUILD {
        my $self = shift;

        $self->log->info( "Movie name: ",$self->name );            
    }

    no Moose;

    __PACKAGE__->meta->make_immutable;

}

1;
