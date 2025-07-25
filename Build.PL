
use utf8;
use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

    module_name       => 'WWW::Bilibili',
    license           => 'perl',
    dist_author       => q{x64x2},
    dist_version_from => 'lib/pkg/Bilibili.pm',
    release_status    => 'stable',

    build_requires => {
                       'Test::More' => 0,
                      },

    extra_manify_args => {utf8 => 1},

    configure_requires => {
                           'Module::Build' => 0,
                          },

    get_options => {
                    'gtk3' => {
                               type  => '!',
                               store => \$gtk3,
                              },
                   },

    requires => {
        'perl'                  => 5.016,
        'Data::Dump'            => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'File::Path'            => 0,
        'Getopt::Long'          => 0,
        'HTTP::Request'         => 0,
        'JSON'                  => 0,
        'Encode'                => 0,
        'Memoize'               => 0,
        'MIME::Base64'          => 0,
        'List::Util'            => 0,
        'LWP::UserAgent'        => 0,
        'LWP::Protocol::https'  => 0,
        'Term::ANSIColor'       => 0,
        'Term::ReadLine'        => 0,
        'Text::ParseWords'      => 0,
        'Text::Wrap'            => 0,
        'URI::Escape'           => 0,
        'Time::Piece'           => 0,

        $gtk3
        ? (
           'Gtk3'           => 0,
           'File::ShareDir' => 0,
           'Storable'       => 0,
           'Digest::MD5'    => 0,
          )
        : (),
    },

    recommends => {
        'LWP::UserAgent::Cached' => 0,    # cache support
        'Term::ReadLine::Gnu'    => 0,    # for better STDIN support (+history)
        'JSON::XS'               => 0,    # faster JSON to HASH conversion
        'Unicode::GCString'      => 0,    # fixed-width format
        'Text::Unidecode'        => 0,    # for the `fat32safe` option
                  },

    add_to_cleanup     => ['WWW-Bilibili-*'],
    create_makefile_pl => 'traditional',
);

$builder->script_files(['bin/bilibili', ($gtk3 ? ('bin/gtk-bilibili') : ())]);

$builder->share_dir('share') if $gtk3;
$builder->create_build_script();
