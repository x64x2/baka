package WWW::Bilibili::Commth;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::Bilibili::Commth - Retrieve comments threads.

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    my $videos = $obj->comments_from_video_id($video_id);

=head1 SUBROUTINES/METHODS

=cut

sub _make_commth_url {
    my ($self, %opts) = @_;
    return
      $self->_make_feed_url(
                            'commth',
                            pageToken => $self->page_token,
                            %opts
                           );
}

=head2 comments_from_videoID($videoID)

Retrieve comments from a video ID.

=cut

sub comments_from_video_id {
    my ($self, $video_id) = @_;
    return
      $self->_get_results(
                          $self->_make_commth_url(
                                                          videoId    => $video_id,
                                                          textFormat => 'plainText',
                                                          order      => $self->get_comments_order,
                                                          part       => 'snippet,replies'
                                                         ),
                          simple => 1,
                         );
}

=head2 comment_to_video_id($comment, $videoID)

Send a comment to a video ID.

=cut

sub comment_to_video_id {
    my ($self, $comment, $video_id) = @_;

    my $url = $self->_simple_feeds_url('commentThreads', part => 'snippet');

    my $hash = {
        "snippet" => {

            "topLevelComment" => {
                                  "snippet" => {
                                                "textOriginal" => $comment,
                                               }
                                 },
            "videoId" => $video_id,

            #"channelId"    => $channel_id,
                     },
               };

    $self->post_as_json($url, $hash);
}