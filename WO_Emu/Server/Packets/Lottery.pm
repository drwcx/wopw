package Lottery;

use strict;
use warnings;
use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;


method spin_wheel($data, $client){

    my $msg = {"command" => "chance_wheel_return", "value" => $self->get_reward($client), "special" => "true"};
    #add to inventory
    #{"command" => "chance_wheel_return",  "value" => {"reward" => {"grenade" => 1 }} , "special" => "true"}
    $client->send($msg);
}

method get_reward($client){
    #substract biscuits add reward

    if($client->{details}->{treats} >= 2){
        $client->charge_treats(2);
    }else{
        return {"reward" => undef};
    }

    my $val =  int(rand() * 100);
    my $type; my $amount; my $special = 0;

    if   ( 0 <= $val && $val <=  7) { $type = "teleport"; $amount = 2; $special = 0; }
    elsif( 8 <= $val && $val <= 15) { $type = "teleport"; $amount = 3; $special = 0; }
    elsif(16 <= $val && $val <= 24) { $type = "teleport"; $amount  = 4; $special = 0; }
    elsif(25 <= $val && $val <= 49) { $type = "grappling"; $amount = 2; $special = 0; }
    elsif(50 <= $val && $val <= 58) { $type = "grenade"; $amount = 2; $special = 0; }
    elsif(              $val == 59) { $type = "grenade"; $amount = 50; $special = 1; }
    elsif(60 <= $val && $val <= 68) { $type = "flamethrower"; $amount = 1; $special = 0; }
    elsif(              $val == 69) { $type = "flamethrower"; $amount = 3; $special = 0; }
    elsif(70 <= $val && $val <= 78) { $type = "goo"; $amount = 1; $special = 0; }
    elsif(              $val == 79) { $type = "goo"; $amount = 3; $special = 0; }
    elsif(80 <= $val && $val <= 89) { $type = "mirv"; $amount = 1; $special = 0; }
    elsif(90 <= $val && $val <= 94) { $type = "drill"; $amount = 1; $special = 0; }
    elsif(95 <= $val && $val <= 100){ $type = "lasercannon"; $amount = 1; $special = 1; }

    $client->add_weapon($type, $amount);

    return {"reward" => {$type => $amount}, "special" => ($special ? "true" : "false")};
    #{"reward":{"grenade":2},"special":"false"}}

}

return 1;
