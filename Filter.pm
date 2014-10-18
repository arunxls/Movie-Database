package Filter;

use strict;
use warnings FATAL => qw(all);

use Exporter 'import';
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw(filter);

use constant REMOVE_DATE_BRACKETS           => [ '\(\d*\)'          => '',    ];
use constant REMOVE_DATE_SQUARE_BRACKETS    => [ '\[\s*\d*\s*\]'    => '',    ];
use constant REMOVE_LEADING_SPACES          => [ '^\s*'             => '',    ];
use constant REMOVE_TRAILING_SPACES         => [ '\s*$'             => '',    ];
use constant REPLACE_PERIODS_WITH_SPACE     => [ '\.'               => ' ',   ];
use constant REMOVE_1080p_BRACKETS          => [ '\(*1080p\)*'      => '',    ];
use constant REMOVE_1080p_SQUARE_BRACKETS   => [ '\[*1080p\]*'      => '',    ];
use constant REMOVE_720p_BRACKETS           => [ '\(*720p\)*'       => '',    ];
use constant REMOVE_720p_SQUARE_BRACKETS    => [ '\[*720p\]*'       => '',    ];

my $FILTER_ORDER = [ 
    REMOVE_DATE_BRACKETS,
    REMOVE_DATE_SQUARE_BRACKETS,
    REMOVE_LEADING_SPACES,
    REMOVE_TRAILING_SPACES,
    REPLACE_PERIODS_WITH_SPACE,
    REMOVE_1080p_BRACKETS,
    REMOVE_1080p_SQUARE_BRACKETS,
    REMOVE_720p_BRACKETS,
    REMOVE_720p_SQUARE_BRACKETS,
    ];

sub filter {
    my $string = shift;
    my $logger = get_logger();

    foreach my $regex ( @{$FILTER_ORDER} ) {
        $logger->debug("Input String '$string'");
        $string = _filter( $string, $regex );
        $logger->debug("Returning String '$string");
    }
    return $string;
}

sub _filter {
    my ( $string, $regex ) = @_;
    my $logger = get_logger();

    my $r = ${$regex}[0];
    my $s = ${$regex}[1];

    $logger->debug("Filtering on Regex $r and replacing with $s");

    if ( $string =~ m/$r/ ) {
        $string =~ s/$r/$s/;
    }
    return $string;
}

