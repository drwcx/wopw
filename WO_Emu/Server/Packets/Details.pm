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

    #my $hr = $client->{parent}->{games}->{$client->{guid}}->{players};
    #my @list_data = map { s/^test(\d+)/part${1}_0/; $_ } values %$hr;

    #$client->{parent}->send_to_game($client->{guid}, {"command" => "startGame", "currentPlayer" => $client->{details}->{id}, "tick" => 10,
    # "playerList" => \@list_data, "connected" => 1, "randomSeed" => 12345} ,-1);
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
