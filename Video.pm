package Video;
{
    use strict;
    use warnings FATAL => qw(all);

    use namespace::autoclean;

    use MooseX::StrictConstructor;
    use MooseX::AbstractFactory;

    my %implementationClass = (
        'Movies'  => 'Video::Movie',
        'TvShows' => 'Video::TvShow',
    );

    implementation_class_via sub {
        my $type = shift;
        die "'$type' is not implemented!"
            if ( !defined $implementationClass{$type} );
        $implementationClass{$type};
    };
}

1;