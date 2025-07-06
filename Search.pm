package WWW::Bilibili::Search;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::Bilibili::Search - Search functions for Youtube API v3

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    $obj->search_videos(@keywords);

=head1 SUBROUTINES/METHODS

=cut

sub make_search_url {
    my ($self, %opts) = @_;

    return $self->_make_feed_url(
        'search',

        topicId    => $self->get_topicId,
        regionCode => $self->get_regionCode,

        maxResults        => $self->get_maxResults,
        order             => $self->get_order,
        publishedAfter    => $self->get_publishedAfter,
        publishedBefore   => $self->get_publishedBefore,
        regionCode        => $self->get_regionCode,
        relevanceLanguage => $self->get_relevanceLanguage,
        safeSearch        => $self->get_safeSearch,
        channelId         => $self->get_channelId,
        channelType       => $self->get_channelType,
        pageToken         => $self->page_token,

        (
         $opts{type} eq 'video'
         ? (
            videoCaption    => $self->get_videoCaption,
            videoCategoryId => $self->get_videoCategoryId,
            videoDefinition => $self->get_videoDefinition,
            videoDimension  => $self->get_videoDimension,
            videoDuration   => $self->get_videoDuration,
            videoEmbeddable => $self->get_videoEmbeddable,
            videoLicense    => $self->get_videoLicense,
            videoSyndicated => $self->get_videoSyndicated,
            videoType       => $self->get_videoType,
            eventType       => $self->get_eventType,
           )
         : ()
        ),

        %opts,
    );

}

=head2 search_for($types,$keywords;\%args)

Search for a list of types (comma-separated).

=cut

sub search_for {
    my ($self, $type, $keywords, $args) = @_;

    if (ref($args) ne 'HASH') {
        $args = {part => 'snippet'};
    }

    if (defined($keywords)) {

        if (ref($keywords) ne 'ARRAY') {
            $keywords = [split ' ', $keywords];
        }

        $keywords = $self->escape_string(join(' ', @{$keywords}));
    }

    my $url = $self->_make_search_url(
                                      type => $type,
                                      q    => $keywords,
                                      %$args,
                                     );

    return $self->_get_results($url);
}

{
    no strict 'refs';

    foreach my $pair (
                      {
                       name => 'videos',
                       type => 'video',
                      },
                      {
                       name => 'playlists',
                       type => 'playlist',
                      },
                      {
                       name => 'channels',
                       type => 'channel',
                      },
                      {
                       name => 'all',
                       type => 'video,channel,playlist',
                      }
      ) {
        *{__PACKAGE__ . '::' . "search_$pair->{name}"} = sub {
            my $self = shift;
            $self->search_for($pair->{type}, @_);
        };
    }
}

=head2 related_to_videoID($id)

Retrieves a list of videos that are related to the video
that the parameter value identifies. The parameter value must
be set to a YouTube video ID.

=cut

sub related_to_videoID {
    my ($self, $videoID) = @_;

    # Feature deprecated and removed in August 2023
    # return $self->search_for('video', undef, {relatedToVideoId => $id});

    my $watch_next_response = $self->parse_json_string($self->_get_video_next_info($videoID) // return {results => {}});
    my $related             = eval { $watch_next_response->{contents}{singleColumnWatchNextResults}{results}{results}{contents} } // return {results => {}};

    my @results;

    foreach my $entry (map { @{$_->{itemSectionRenderer}{contents} // []} } @$related) {

        my $info  = $entry->{videoWithContextRenderer} // next;
        my $title = $info->{headline}{runs}[0]{text}   // next;

        if (($info->{shortViewCountText}{runs}[0]{text} // '') =~ /Recommended for you/i) {
            next;    # filter out recommended videos from related videos
        }

        my $lengthSeconds = 0;

        if (($info->{lengthText}{runs}[0]{text} // '') =~ /([\d:]+)/) {
            my $time   = $1;
            my @fields = split(/:/, $time);

            my $seconds = pop(@fields) // 0;
            my $minutes = pop(@fields) // 0;
            my $hours   = pop(@fields) // 0;

            $lengthSeconds = 3600 * $hours + 60 * $minutes + $seconds;
        }
        