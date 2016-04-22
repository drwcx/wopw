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
                    $self->{logger}->out("Client disconnected", Logger::LEVELS->{inf});
                    $select->remove($client->{stream});
                    close($client->{stream});
                    delete($self->{clients}->{$client->{fileno}});
                }else{
                    $client->handle();
                }
            };
        }
        select(undef, undef, undef, 0.05);
    }
}

method get_client_by_sock($sock){
    foreach(values %{$self->{clients}}){
        next unless defined($_);
        if($_->{stream} eq $sock){
            return $_;
        }
    }
    return undef;
}

method get_load(){
    return (scalar keys %{$self->{clients}});
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
