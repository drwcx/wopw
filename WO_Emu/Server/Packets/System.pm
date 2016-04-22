package System;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;


method pong($data, $client){
    my $msg = {"command" => "ping_ack"};
    $client->send($msg);
}

return 1;
