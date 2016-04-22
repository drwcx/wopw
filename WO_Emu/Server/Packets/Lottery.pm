package Lottery;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;


method spin_wheel($data, $client){
    my $msg = {"command" => "chance_wheel_return", "reward" => "teleport"}; #not working
    $client->send($msg);
}

return 1;
