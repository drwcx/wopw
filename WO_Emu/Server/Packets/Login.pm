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

    #if($client->{parent}->{db}->exists({"usr" => $data->{dname}, "lkey" => $data->{snum}}) > 0){
        $client->{details}->{command} = "setPlayer";
        $client->send($client->{details});
    #}else{
    #    print "\x1b[33m" . "Oh no! The client has gotten into trouble.\x1b[00m\n";
    #}

    $client->send_update_player();
}

method create_account($data, $client){

}

return 1;
