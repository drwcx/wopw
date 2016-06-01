package Match;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use List::Util 'max';

method join_game($data, $client){
    #find a game with the details or create one

    my $gid = $client->{parent}->find_game($data->{mapName}, $data->{playerCount}, $data->{gameDuration}, $data->{turnDuration});
    $client->{guid} = $gid;
    #make sure these run properly
    #$client->{gpos} = $client->{parent}->get_game_load($gid);
    $client->{parent}->{games}->{$gid}->{players}->{$client->{details}->{id}} = { "guid" => $client->{details}->{id}, "status" => $client->{details}->{status} };
    #end of uncertainty

    print "GAME LOAD BY ID IS " . $client->{parent}->get_game_load($gid) . " \n\n";

    my $msg = {"command" => "join", "status" => "idle", "playerCount" => 1, "min" => $data->{playerCount}, "id" => $gid, "players" => [],
    "map" => $data->{mapName}, "name" => $data->{mapName}, "cl" => 0, "skip"=> [], "sumOfLevels" => 10, "turnDuration" => 60000,
    "gameDuration" => 600000, "time" => $data->{time}};

    $client->send($msg);
}

#start_server_connect

method prepare_game($data, $client){
    print "data on prepare game is $data\n\n";
    #authenticate here
    my $db_data = $client->{parent}->{db}->get_player_by_name($data->{userId});
    $client->setup($db_data);

    my $hr = $client->{parent}->{games}->{$client->{guid}}->{players};
    my @list_data = map { s/^test(\d+)/part${1}_0/; $_ } values %$hr;

    foreach my $pl (@list_data){
        $client->send_player($pl->{guid});
    }

    $client->{parent}->update_game_player($client);
    $client->{parent}->send_game($client->{guid});
}

method load_game($data, $client){
    #$client->{parent}->send_to_game($client->{guid}, {"command" => "request_synch"}, 0);
    my @avatars = ();
    my @player_list = ();
    #$client->{parent}->{games}->{$client->{guid}}->{players}
    my $hr = $client->{parent}->{games}->{$client->{guid}}->{players};
    my @list_data = map { s/^test(\d+)/part${1}_0/; $_ } values %$hr;

    foreach my $pl (@list_data){
        my $p = $client->{parent}->get_player_by_id($pl->{guid});
        push @avatars, $p->construct_player_profile();
        push @player_list, $p->{details};
    }

    $client->{parent}->send_to_game($client->{guid},
        {
            "command" => "set_synch",
            "gameRecord" => {
                "randomSeed" => "abc",
                "connected" => 1,
                "currentPlayer" => 1,
                "tick" => 0,
                "playerlist" => \@player_list
            },
            "gameMode" => "multiPlayerMode",
            "avatarList" => \@avatars,
            "timeLoop" =>{},
            "gameDuration" => 60,
            "turnDuration" => 10,
            "lightningDelay" => 10,
            "field" => {"explosions"},
            "waterLevel" => 0,
            "crateDispensation" => [],
            "playOrder" => 1,
            "randomSeed" => "abc"
        }, 0);
}

method send_message($data, $client){
    $client->{parent}->send_to_game($client->{guid}, $data, $client->{details}->{id});
}

method set_ready($data, $client){

}

return 1;
