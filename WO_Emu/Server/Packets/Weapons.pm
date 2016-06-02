package Weapons;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use Data::Dumper;

method set_weapons($data, $client){
    print "Setting weapons\n";
    $client->{details}->{userWeaponsEquipped} = $data->{value};
    $client->update();
}

1;
