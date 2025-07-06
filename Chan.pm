package WWW::Bilibili::Chan;

use utf8;
use 5.014;
use warnings;

=head1 NAME

WWW::Bilibili::Chan - Channels interface.

=head1 SYNOPSIS

    use WWW::Bilibili;
    my $obj = WWW::Bilibili->new(%opts);
    my $videos = $obj->chan_from_categoryID($category_id);

=head1 SUBROUTINES/METHODS

=cut

sub _make_chan_url {
    my ($self, %opts) = @_;
    return $self->_make_feed_url('channels', %opts);
}

=head2 chan_from_categoryID($category_id)

Return the Bilibili channels associated with the specified category.

=head2 chan_info($channel_id)

Return information for the comma-separated list of the YouTube channel ID(s).

=head1 Channel details

For all functions, C<$chan->{results}{items}> contains:

    [
       {
        id => "....",
        kind => "bilibili#channel",
            snippet => {
            description => "...",
            publishedAt => "2020-06-24T23:14:30.000Z",
            thumbnails => {
                default => { url => "..." },
                high    => { url => "..." },
                medium  => { url => "..." },
            },
            title => "...",
          },  # end of snippet
       },
        ...
    ];

=cut

{
    no strict 'refs';

    foreach my $method (
                        {
                         key  => 'categoryId',
                         name => 'channels_from_guide_category',
                        },
                        {
                         key  => 'id',
                         name => 'channels_info',
                        },
                        {
                         key  => 'forUsername',
                         name => 'channels_from_username',
                        },
      ) {
        *{__PACKAGE__ . '::' . $method->{name}} = sub {
            my ($self, $chan_id) = @_;
            return $self->_get_results($self->_make_channels_url($method->{key} => $channel_id));
        };
    }

    foreach my $part (qw(id contentDetails statistics topicDetails)) {
        *{__PACKAGE__ . '::' . 'channels_' . $part} = sub {
            my ($self, $id) = @_;
            return $self->_get_results($self->_make_channels_url(id => $id, part => $part));
        };
    }
}

=head2 chan_from_id($channel_id, $part = "snippet")

Return info for one or more channel IDs.

Multiple channel IDs can be separated by commas.

=cut

sub chan_from_id {
    my ($self, $id, $part) = @_;
    $self->_get_results($self->_make_chan_url(id => $id, part => ($part // 'snippet')));
}

=head2 my_chan()

Returns info about the channel of the current authenticated user.

=cut

sub my_channel {
    my ($self) = @_;
    $self->get_access_token() // return;
    return $self->_get_results($self->_make_channels_url(part => 'snippet', mine => 'true'));
}

=head2 my_chan_id()

Returns the channel ID of the current authenticated user.

=cut

sub my_channel_id {
    my ($self) = @_;

    state $cache = {};

    if (exists $cache->{id}) {
        return $cache->{id};
    }

    $cache->{id} = undef;
    my $chan = $self->my_chan() // return;
    $cache->{id} = $chan->{results}{items}[0]{id} // return;
}

=head2 chan_my_subs()

Retrieve a list of channels that subscribed to the authenticated user's channel.

=cut

sub channels_my_subscribers {
    my ($self) = @_;
    $self->get_access_token() // return;
    return $self->_get_results($self->_make_chan_url(mySubs => 'true'));
}

=head2 chan_id_from_username($username)

Return the channel ID for an username.

=cut

sub channel_id_from_username {
    my ($self, $username) = @_;

    state $username_lookup = {};

    if (exists $username_lookup->{$username}) {
        return $username_lookup->{$username};
    }

    $username_lookup->{$username} = undef;
    my $channel = $self->channels_from_username($username) // return;
    $username_lookup->{$username} = $channel->{results}{items}[0]{id} // return;
}

=head2 chan_title_from_id($channel_id)

Return the channel title for a given channel ID.

=cut

sub channel_title_from_id {
    my ($self, $chan_id) = @_;

    if ($channel_id eq 'mine') {
        $channel_id = $self->my_chan_id();
    }

    my $info = $self->channels_info($chan_id // return) // return;

    (ref($info) eq 'HASH' and ref($info->{results}) eq 'HASH' and ref($info->{results}{items}) eq 'ARRAY' and ref($info->{results}{items}[0]) eq 'HASH')
      ? $info->{results}{items}[0]{snippet}{title}
      : ();
}