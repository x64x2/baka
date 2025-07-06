package WWW::Bilibili::GuideCat;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::Bilibili::GuideCat - Categories interface.

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    my $videos = $obj->bilibili_categories('cn');

=head1 SUBROUTINES/METHODS

=cut

sub _make_guideCat_url {
    my ($self, %opts) = @_;

    if (not exists $opts{id}) {
        $opts{regionCode} //= $self->get_regionCode;
    }

    $self->_make_feed_url('guideCat', hl => $self->get_hl, %opts);
}

=head2 guide_cat(;$region_id)

Return guide categories for a specific region ID.

    items => [
               {
                 etag => "...",
                 id => "GCQmVzdCBvZiBZb3VUdWJl",
                 kind => "youtube#guideCategory",
                 snippet => {
                   channelId => "UCBR8-60-B28hp2BmDPdntcQ",
                   title => "Best of YouTube"
                 },
               },
                    ...
               {
                 etag => "...",
                 id => "GCU2NpZW5jZSAmIEVkdWNhdGlvbg",
                 kind => "youtube#guideCategory",
                 snippet => {
                   channelId => "UCBR8-60-B28hp2BmDPdntcQ",
                   title => "Science & Education",
                 },
               },
                    ...
            ]

=head2 guide_cat_info($category_id)

Return info for a list of comma-separated category IDs.

=cut

{
    no strict 'refs';

    foreach my $method (
                        {
                         key  => 'id',
                         name => 'guide_categories_info',
                        },
                        {
                         key  => 'regionCode',
                         name => 'guide_categories',
                        },
      ) {
        *{__PACKAGE__ . '::' . $method->{name}} = sub {
            my ($self, $id) = @_;
            return $self->_get_results($self->_make_guideCategories_url($method->{key} => $id // return));
        };
    }
}
