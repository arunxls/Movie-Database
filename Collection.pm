package Collection;
{
    use strict;
    use warnings FATAL => qw(all);

    use namespace::autoclean;

    use Video;
    use AK::Utils qw(table);
    use Moose;
    use MooseX::StrictConstructor;
    use File::Slurp qw(read_dir);
    use DBI;
    use Cwd qw(realpath);
    use Data::Dumper;

    with 'MooseX::Log::Log4perl';

    has 'path' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 1,
        trigger     => sub{
            my ($self,$path) = @_;
            $self->log->logdie("Path '$path' does not exist") unless (-e $path);
        },
    );

    has 'type' => (
        is          => 'ro',
        isa         => 'Str',
        default     => 1,
    );

    has 'videos' => (
        is          => 'ro',
        isa         => 'ArrayRef[Str]',
        default     => sub { [] },
        init_arg    => undef,
    );

    has 'db_file' => (
        is          => 'ro',
        isa         => 'Str',
        default     => '.collection.db',
    );

    has '_db_handle' => (
        is          => 'ro',
        isa         => 'Object',
        lazy        => 1,
        default     => sub {
            my $self = shift;
            my $dbfile = File::Spec->catfile(realpath($self->path), $self->db_file);
            return DBI->connect("dbi:SQLite:dbname=$dbfile","","",{ RaiseError => 1, AutoCommit => 1 });
        },
    );

    has '_schema' => (
        is          => 'ro',
        isa         => 'HashRef',
        lazy        => 1,
        init_arg    => undef,
        default     => sub {
            my $self = shift;

            return {
                collection => [
                    table
                    (
                        [ 'name',           'type',             'primary_key',  'not_null',     'unique',  'alias'          ],
    
                        [ 'ID',             'VARCHAR(20)',      1,              1,              1,         'imdbID'         ],
                        [ 'Title',          'VARCHAR(50)',      0,              1,              1,         'Title'          ],
                        [ 'Actors',         'VARCHAR(500)',     0,              0,              0,         'Actors'         ],
                        [ 'ImdbRating',     'FLOAT',            0,              0,              0,         'imdbRating'     ],
                        [ 'Awards',         'VARCHAR(500)',     0,              0,              0,         'Awards'         ],
                        [ 'Plot',           'VARCHAR(2000)',    0,              0,              0,         'Plot'           ],
                        [ 'Year',           'DATE',             0,              0,              0,         'Year'           ],
                        [ 'Rated',          'VARCHAR(10)',      0,              0,              0,         'Rated'          ],
                        [ 'Type',           'VARCHAR(50)',      0,              0,              0,         'Type'           ],
                        [ 'Website',        'VARCHAR(100)',     0,              0,              0,         'Website'        ],
                        [ 'TomatoRating',   'FLOAT',            0,              0,              0,         'tomatoRating'   ],
                        [ 'Director',       'VARCHAR(100)',     0,              0,              0,         'Director'       ],
                        [ 'Poster',         'VARCHAR(100)',     0,              0,              0,         'Poster'         ],
                        [ 'Production',     'VARCHAR(100)',     0,              0,              0,         'Production'     ],
                        [ 'TomatoReview',   'VARCHAR(500)',     0,              0,              0,         'tomatoConsensus'],
                        [ 'Language',       'VARCHAR(100)',     0,              0,              0,         'Language'       ],
                        [ 'Genre',          'VARCHAR(100)',     0,              0,              0,         'Genre'          ],
                        [ 'RunTime',        'VARCHAR(50)',      0,              0,              0,         'Runtime'        ],

                    )
                ]
            };
        },
    );


    sub BUILD {
        my $self = shift;

        my $dbh = $self->_get_db();

        foreach my $name (read_dir($self->path)){
            next if($name eq $self->db_file);
            my $obj = Video->create($self->type,{'name' => $name, 'db' => $dbh});
            push(@{$self->videos},$obj);
        }

    }

    no Moose;

    __PACKAGE__->meta->make_immutable;

    sub _get_db{
        my $self = shift;

        
        my $dbh = $self->_db_handle;
        $dbh->do($self->_create_table('collection'));

        return $dbh;
    }

    sub _create_table{
        my ($self,$table) = @_;

        my $hash = $self->_schema;
        my $sql = "CREATE TABLE IF NOT EXISTS [$table]";

        $sql = _concat($sql,"(\n");

        my $size = scalar @{$hash->{$table}};

        foreach my $col (@{$hash->{$table}}){
            $sql = _concat($sql,"[$col->{name}]");
            $sql = _concat($sql, $col->{type});
            $sql = _concat($sql, "UNIQUE") if ($col->{unique});
            $sql = _concat($sql, "NOT NULL") if ($col->{not_null});
            $sql = _concat($sql, "NULL") if (!$col->{not_null});
            $sql = _concat($sql, "PRIMARY KEY") if ($col->{primary_key});
            
            $sql = _concat($sql, ",") unless($size le 1);
            $sql = _concat($sql, "\n");
            $size--;
        }
        $sql = _concat($sql,")\n");
        return $sql; 
    }

    sub _concat {
        my ($str1,$str2) = @_;

        return "$str1 $str2";
    }

    sub update_video_info{
        my $self = shift;

        my $dbh = $self->_db_handle;
        my $select_statement = $dbh->prepare("SELECT * FROM collection WHERE Title = ?");
        my @insert_values = map{ " ?," } (1..$#{$self->_schema->{collection}}) ;
        my $insert_statement = $dbh->prepare("INSERT INTO collection VALUES (@insert_values ?)");

        foreach my $vid (@{$self->videos}){
            my $name = $vid->name;
            $select_statement->execute($name);
            my $data = {};
            $data = $select_statement->fetchrow_hashref;
            if(defined $data){
                $self->log->info("Data for video '$name' already stored in DB");
                $vid->video_data($data);
            } else {
                $self->log->info("Data for video '$name' not stored in DB, fetching from Web");
                my $db_data = $self->_translate_json_to_db($vid->get_info());
                eval {$insert_statement->execute(map{ $db_data->{$_->{name}} } @{$self->_schema->{collection}})};
            }
        }
    }

    sub _translate_json_to_db {
        my ($self,$json) = @_;

        my $ret_hash = {};
        my $table = 'collection';
        my $hash = $self->_schema;

        foreach my $col (@{$hash->{$table}}){
            $ret_hash->{$col->{name}} = $json->{$col->{alias}} 
        }
        return $ret_hash;
    }
}

1;
