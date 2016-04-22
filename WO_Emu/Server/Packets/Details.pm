package Details;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use Data::Dumper;

method set_flag($data, $client){
    print "Setting flags\n";
    $client->{details}->{flag} = $data->{value};
    my $packet = {
        "command"  => "player",
    };

    #$client->send($packet);
}

method set_name($data, $client){
    $client->{details}->{dname} = $data->{dname};
    $client->{details}->{command} = "player";
    $client->send($client->{details});
    #add notification
    #$client->notify();
}

1;
