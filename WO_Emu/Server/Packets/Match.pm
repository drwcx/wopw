package Match;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;


method join_game($data, $client){
    my $msg = {"command" => "join", "players" => [], "map" => "Critter Falls", "name" => "team.wildones.pw", "id" => 97};
    $client->send($msg);
}

#start_server_connect

method prepare_game($data, $client){
  #my $msg = {"command" => "startGame"};
  $client->{details}->{command} = "player";
  $client->{details}->{id} = 0;
  $client->send($client->{details});

  #my $msg = {"command" => "game", "id" => 97};
  #$client->send($msg);
  #$client->send($msg);
}

method set_ready($data, $client){

}

return 1;
