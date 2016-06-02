package Market;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use Data::Dumper;

method buy_accessory($data, $client){
    #push type to userAccessories
    #TO FIX
    print "buying accessory\n";
    my $accessories = $client->{details}->{userAccessories};
    $client->{details}->{userAccessories}[(scalar @$accessories)] = $data->{type};
    $client->{details}->{xp} = 15000;
    $client->update();
}

method buy_pet($data, $client){
    #check wallet and level and charge

    my $pet_id = scalar (keys %{$client->{details}->{ownedPets}}) + 1;
    $client->{details}->{ownedPets}->{$pet_id} = {
        "id" => $pet_id,
        "gender" => "M",
        "name" => $data->{name},
        "color1" => $data->{color1},
        "color2" => $data->{color2},
        "kills" => 0,
        "deaths" => 0,
        "type" => $data->{type},
        "pers" => "clever",
        "accessories" => []
    };
    $client->update();
}

method buy_weapon($data, $client){
    #check wallet, level, existence and also charge
    my $pack = 1; #get this from crumbs
    $client->{details}->{userWeaponsOwned}->{$data->{ammoType}} += $data->{ammoCount} * $pack;
    $client->update();
}

1;
