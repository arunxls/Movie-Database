package Video::AbstractVideo;
{
    use strict;
    use warnings FATAL => qw(all);

    use namespace::autoclean;
    use feature qw(say);

    use Moose;
    use MooseX::StrictConstructor;
    use LWP;
    use URI;
    use JSON;
    use Data::Dumper;


    with 'MooseX::Log::Log4perl';

    has 'name' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 1,
    );

    has 'url' => (
        is          => 'ro',
        isa         => 'URI',
        default     => 'http://www.omdbapi.com/',
    );

    has 'video_data' => (
        is          => 'rw',
        isa         => 'HashRef',
        default     => sub { {} },
        init_arg    => undef,
    );

    has 'db' => (
        is          => 'ro',
        isa         => 'DBI::db',
        required    => 1,
    );

    no Moose;

    __PACKAGE__->meta->make_immutable;

    sub get_info{
        my $self = shift;
        my $browser = LWP::UserAgent->new;
        my $url = URI->new($self->url);
        $url->query_form('t' => $self->name,'tomatoes' => 'true');
  
        return from_json($browser->get($url)->content());
    }

}

1;
