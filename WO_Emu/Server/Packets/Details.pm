package Details;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use List::Util qw(any);

use Data::Dumper;


method set_outfit($data, $client){
    #check if every element of the load is within the userAccessories container
    my @load = @{$client->{details}->{userAccessories}};
    my @accessories = @{$client->{details}->{userAccessories}};

    my $ok = 1;

    foreach my $el_a (@load) {
        $ok = 0;
        foreach my $el_b (@accessories){
            if($el_a eq $el_b){
                $ok = 1;
                last;
            }
        }

        if($ok eq 0){
            last;
        }
    }

    if($ok != 0){
        $client->{details}->{ownedPets}->{$client->{details}->{currentPet}}->{accessories} = $data->{load};
        $client->update();
    }else{
        print "\x1b[33m" . {$client->{details}->{dname}} . " is feeling 1337 today.\x1b[00m\n";
    }
}

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

method change_pet($data, $client){
    $client->{details}->{currentPet} = $data->{name};
    $client->update();
}

method set_ready($data, $client){
    $client->{details}->{status} = "ready";
    $client->{parent}->{games}->{$client->{guid}}->{players}->{$client->{details}->{id}}->{status} = "ready";
    $client->{parent}->update_game_player($client);
    #check if more than 1 player is ready
    if($client->{parent}->check_if_game_ready($client->{guid})){
        $client->{parent}->{games}->{$client->{guid}}->{status} = "starting";
        $client->{parent}->{games}->{$client->{guid}}->{start_time} = time + 5;
        $client->{parent}->{games}->{$client->{guid}}->{started} = 0;

        print "set start time : " . $client->{parent}->{games}->{$client->{guid}}->{start_time} . " where time is " . time() . "\n\n";
    }

    $client->{parent}->send_game($client->{guid});
}

method set_not_ready($data, $client){
    $client->{details}->{status} = "-1";
    $client->{parent}->{games}->{$client->{guid}}->{players}->{$client->{details}->{id}}->{status} = "-1";
    $client->{parent}->{games}->{$client->{guid}}->{start_time} = -1;
    $client->{parent}->{games}->{$client->{guid}}->{status} = "idle";
    $client->{parent}->update_game_player($client);
    $client->{parent}->send_game($client->{guid});
}

1;
