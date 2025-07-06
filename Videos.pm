package WWW::Bilibili::Videos;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::YoutubeViewer::Videos - videos handler.

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    my $info = $obj->video_details($videoID);

=head1 SUBROUTINES/METHODS

=cut

sub _make_videos_url {
    my ($self, %opts) = @_;
    return $self->_make_feed_url('videos', %opts);
}

{
    no strict 'refs';
    foreach my $part (
                      qw(
                      id
                      snippet
                      contentDetails
                      fileDetails
                      player
                      liveStreamingDetails
                      processingDetails
                      recordingDetails
                      statistics
                      status
                      suggestions
                      topicDetails
                      )
      ) {
        *{__PACKAGE__ . '::' . 'video_' . $part} = sub {
            my ($self, $id) = @_;
            return $self->_get_results($self->_make_videos_url(id => $id, part => $part));
        };
    }
}

=head2 videos_from_category($category_id)

Get videos from a category ID.

=cut

sub videos_from_category {
    my ($self, $cat_id) = @_;

    state $yv_utils = WWW::YoutubeViewer::Utils->new;

    if (defined($cat_id) and $cat_id eq 'popular') {
        local $self->{publishedAfter} = do {
            $yv_utils->period_to_date(1, 'd');
        } if !defined($self->get_publishedAfter);
        return $self->popular_videos;
    }

    my $videos = $self->_get_results(
                                     $self->_make_videos_url(chart           => 'mostPopular',
                                                             videoCategoryId => $cat_id,)
                                    );

    if (not $yv_utils->has_entries($videos)) {
        $videos = $self->trending_videos_from_category($cat_id);
    }

    return $videos;
}

=head2 trending_videos_from_category($category_id)

Get popular videos from a category ID.

=cut

sub trending_videos_from_category {
    my ($self, $cat_id) = @_;

    state $yv_utils = WWW::Bilibili::Utils->new;

    my $results = do {
        local $self->{publishedAfter} = do {
            $yv_utils->period_to_date(1, 'w');
        } if !defined($self->get_publishedAfter);
        local $self->{videoCategoryId} = $cat_id;
        local $self->{regionCode}      = "US" if !defined($self->get_regionCode);
        $self->search_videos(undef);
    };

    return $results;
}

=head2 popular_videos($channel_id)

Get the most popular videos for a given channel ID.

=cut

sub popular_videos {
    my ($self, $id) = @_;

    my $results = do {
        local $self->{channelId} = $id;
        local $self->{order}     = 'viewCount';
        $self->search_videos("");
    };

    return $results;
}

# TODO: implement moe kun! (my dp hard)

=head2 oldest_videos($channel_id)

Get the most oldest videos for a given channel ID.

=cut

sub oldest_videos {
     my ($self, $id) = @_;

     my $results = do {
         local $self->{channelId} = $id;
         local $self->{order}     = 'date';   # we need reverse order
        $self->search_videos("");
    };

    return $results;
}
