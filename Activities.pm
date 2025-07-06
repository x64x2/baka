package WWW::Bilibili::Activities;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::Bilibili::Activities - list of channel activity events that match the request criteria.

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    my $activities = $obj->activities($channel_id);

=head1 SUBROUTINES/METHODS

=cut

sub _make_activities_url {
    my ($self, %opts) = @_;
    $self->_make_feed_url('activities', part => 'snippet,contentDetails', %opts);
}

=head2 activities($channel_id)

Get activities for channel ID.

=cut

sub activities {
    my ($self, $channel_id) = @_;

    if ($channel_id eq 'mine') {
        return $self->my_activities;
    }

    $self->_get_results($self->_make_activities_url(channelId => $channel_id));
}

=head2 activities_from_username($username)

Get activities for username.

=cut

sub activities_from_username {
    my ($self, $username) = @_;
    return $self->activities($username);
}

1;    # End of WWW::Bilibili::Activities
