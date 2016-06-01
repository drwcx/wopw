#!/usr/bin/perl

package WildOnes;

use warnings;
use strict;
use IO::Socket;
use IO::Select;
use IO::Handle;
use threads;
use threads::shared;

use File::Basename;

use Method::Signatures::Simple;
use Mo;
use Server::Plugin::Logger;
use Server::Plugin::Database;

use Server::Player;
use List::Util qw(any);

use syntax 'junction';


our @ports = (8000, 6112);
my @servers = ();

$| = 1;

has "handlers";
has "crumbs";
has "test";
has "client_config";
has "game_config";
has "server_config";
has "db_config";
has "clients";
has "games";
has "logger";
has "db";

method connect_to_database(){
    $self->{db} = Database->new();
    $self->{db}->ini;
}

method add_handlers(){
    # The naming convention established by the game designer
    # is a puzzle I am still trying to solve

    $self->{handlers} = {
        "logIn"                 => "login_player",
        "ping"                  => "pong",
        "set_weapons_equipped"  => "set_weapons", #How many weapons collections are there?
        "setNewPlayerFlag"      => "set_flag",
        "dname"                 => "set_name",
        "chance_wheel"          => "spin_wheel",
        "quick_play"            => "join_game",
        "start_server_connect"  => "prepare_game",
        "on_ready"              => "set_ready",
        "not_ready"             => "set_not_ready",
        "chat"                  => "send_message",
        "map_loaded"            => "load_game"
    };

    my @handler_files = glob('Server/Packets/*.pm');

    foreach (@handler_files) {
        my $class = basename($_, '.pm');
        require $_;
        my $handler = $class->new;
        $self->{crumbs}->{$class} = $handler;
    }

    my $crumbs_no = scalar(keys %{$self->{crumbs}});
    $self->{logger}->out("Loaded " . $crumbs_no . " handler" . ($crumbs_no > 1 ? "s" : ""), Logger::LEVELS->{inf});
}

method start(){
    $self->{clients} = {};
    $self->{crumbs} = {};
    $self->{games} = {};
    $self->{logger} = Logger->new(origin => "Server");

    $self->add_handlers();
    $self->connect_to_database();

    my $select = IO::Select->new();

    foreach my $i (0..((scalar @ports) - 1)) {
        push @servers, new IO::Socket::INET(
            Timeout     => 7200,
            Proto       => "tcp",
            LocalPort   => $ports[$i],
            Reuse       => 1,
            Listen      => SOMAXCONN
        );
        $select->add($servers[$i]);
    }

    $self->{logger}->out("Server is running", Logger::LEVELS->{inf});

    while(1){
        foreach my $s ($select->can_read(0)){
            if(any(@servers) eq $s){

                my $client = $s->accept;
                my $peerhost = $client->peerhost();
                $self->{logger}->out("Client connected " . $peerhost, Logger::LEVELS->{inf});
                $client->autoflush(1);
                my $fileno = fileno $client;
                $select->add($client);
                my $client_obj = Player->new(stream => $client, fileno => $fileno, parent => $self, logger => Logger->new(origin => $peerhost));
                $client_obj->ini;
                $self->{clients}->{$fileno} = $client_obj;

                next;
            }

            eval{
                next unless defined($s);
                my $client = $self->get_client_by_sock($s);
                my $bytes = $client->{stream}->sysread($client->{buffer}, 1024);
                if($bytes eq 0 || $client->{buffer} eq ""){
                    $client->disconnect();
                    $self->{logger}->out("Client disconnected", Logger::LEVELS->{inf});
                    $select->remove($client->{stream});
                    close($client->{stream});
                    delete($self->{clients}->{$client->{fileno}});
                }else{
                    $client->handle();
                }
            };
        }
        select(undef, undef, undef, 0.02);
        #start games
        foreach my $gkey (keys %{$self->{games}}) {
            if($self->{games}->{$gkey}->{start_time} != -1 && time() gt $self->{games}->{$gkey}->{start_time} && $self->{games}->{$gkey}->{started} == 0){
                $self->{games}->{$gkey}->{started} = 1;
                print "Started game with st" . $self->{games}->{$gkey}->{start_time} . "!\n";
                $self->send_to_game($gkey, {"command" => "game_join_confirmed"}, 0);
            }
        }
        #foreach(values %{$self->{games}}){
        #    if($_->{start_time} != -1 && time() gt $_->{start_time} && $_->{started} == 0){
        #        $_->{started} = 1;
        #        print "Started game with st" . $_->{start_time} . "!\n";
        #        $self->send_to_game($client->{guid}, {"command" => "game_join_confirmed"}, 0);
        #    }
        #}
    }
}

method get_client_by_sock($sock){
    foreach(values %{$self->{clients}}){
        next unless defined($_);
        if($_->{stream} eq $sock){
            return $_;
        }
    }
    return undef;;
}

method get_load(){
    return (scalar keys %{$self->{clients}});
}

method get_game_load($id){
    return (scalar keys %{$self->{games}->{$id}->{players}});
}

method find_guest_name($name){
    my $cnt = 0;
    foreach(values %{$self->{clients}}){
        next unless defined($_->{details}->{name});
        if($_->{details}->{name} =~ /^\Q$name\E/){
            #print "found one!" . "\n";
            $cnt += 1;
        }
    }
    $self->{logger}->out("found guest name " . $name . ($cnt > 0 ? ("_" . $cnt) : ""), Logger::LEVELS->{dbg});
    return $name . ($cnt > 0 ? ("_" . $cnt) : "");
}

method send_to_game($id, $packet, $ex){
    foreach(values %{$self->{clients}}){
        next unless ($_->{connection_type} eq "game");
        next unless ($_->{guid} eq $id); #or something that makes the player valid
        next unless ($_->{details}->{id} ne $ex);
        $_->send($packet);
    }
}

method get_player_by_id($id){
    foreach(values %{$self->{clients}}){
        next unless ($_->{connection_type} eq "game"); #or something that makes the player valid
        if($_->{details}->{id} == $id){
            return $_;
        }
    }
    print "NOT FOUND GETPLAYERID!!\n\n";

    return undef;
}

#find_game($data->{mapName}, $data->{playerCount}, $data->{gameDuration}, $data->{turnDuration});

method find_game($map_name, $player_count, $game_duration, $turn_duration){
    #games->{"mapid_cnt_gd_td_cnt"}
    $self->{games}->{"Crash-Landing_4_4_20_0"}->{status} = "idle";
    $self->{games}->{"Crash-Landing_4_4_20_0"}->{start_time} = -1;

    return "Crash-Landing_4_4_20_0";
    my $i = 0;
    $map_name =~s/ /-/g;;
    my $id = $map_name . "_" . $player_count . "_" . $game_duration . "_" . $turn_duration . "_" . $i;
    for(;;){
        if($i >= 100){ last; } #too many games
        if($self->{games}->{$id} ne undef){
            my $no = scalar ($self->{games}->{$id}->{players});
            if(scalar ($self->{games}->{$id}->{players}) < $player_count){
                return $id;
            }
        }else{
            $self->{games}->{$id}->{players} = [];
            return $id;
        }
        $i++;
    }

    return "omniscience";
}

method update_game_player($client){
    $self->send_to_game($client->{guid}, $client->{details}, -1);
}

method send_game($guid){
    my $hr = $self->{games}->{$guid}->{players};
    my @list_data = map { s/^test(\d+)/part${1}_0/; $_ } values %$hr;

    $self->send_to_game($guid, {"command" => "game", "status" => $self->{games}->{$guid}->{status}, "playerCount" => 1, "id" => $guid, "min" => 2, "players" => \@list_data, "map" => "Crash Landing", "name" => "Crash Landing", "cl" => 0,
    "skip"=> [], "sumOfLevels" => 10, "turnDuration" => 60000, "gameDuration" => 600000, "time" => 1464593355058}, -1);
}

method check_if_game_ready($guid){
    return 1;
}

method check_if_user_online($name){
    my $cnt = 0;
    foreach(values %{$self->{clients}}){
        return 1 unless $cnt < 2;
        next unless defined($_->{details}->{name});
        if($_->{details}->{name} =~ /^\Q$name\E/){
            $cnt += 1;
        }
    }

    return ($cnt > 1) ? 1 : 0;
}

1;
