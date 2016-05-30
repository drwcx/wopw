package Login;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;

use Data::Dumper;

method login_player($data, $client){
    print "logging in player!\n";
    print "client version: " . $data->{v} . "\n";

    if($client->{parent}->{db}->exists({"usr" => $data->{dname}, "lkey" => $data->{snum}}) > 0){
        my $db_data = $client->{parent}->{db}->get_player_by_name($data->{dname});
        $client->setup($db_data);
        $client->{details}->{command} = "setPlayer";
        $client->send($client->{details});
        #print "Data from db : " . $client->{parent}->{db}->get_player_by_name($data->{dname})->{level} . "\n";
    }else{
        print "\x1b[33m" . "Oh no! The client has gotten into trouble.\x1b[00m\n";
    }

    $client->send_update_player();
    #if($client->{connection_type} eq "game"){
    #    print "connection is game\n";
    #    my $msg = {"command" => "join", "players" => [$client->{details}], "map" => "Critter Falls", "name" => "team.wildones.pw", "id" => 97};
    #    $client->send($msg);
    #}
}

method create_account($data, $client){

}

return 1;
