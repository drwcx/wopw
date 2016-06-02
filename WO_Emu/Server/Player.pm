package Player;

use strict;
use warnings;
use Method::Signatures::Simple;  # for automatic $self using "method" instead of the "sub"
use Mo;

use JSON;
use Try::Tiny;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;
use Server::Plugin::Strings;

has "parent";
has "stream";
has "id";
has "name";
has "logger";
has "packet_position";
has "loader_information";
has "buffer";
has "fileno";
has "inspiration";
has "connection_type";
has "guid";

method ini(){
    my $sck = $self->{stream};
    $self->{inspiration} = "Change your thoughts and you change your world.\r\n\r\n";
    $self->{loader_information} = {
        posted_header => 0
    };
    $self->{details} = {
        "command" => "",
        "online" => 0,
        "time" => 1000,
        "id" => 0,
        "dname" => "",
        "nw" => 0, #-1
        "level" => 0,
        "userWeaponsEquipped" => [],
        "userWeaponsOwned" => {},
        "ownedPets" => {},
        "userAccessories" => [],
        "currentPet" => 0,
        "login_streak" => -1,
        "playerStatus" => "playing",
        "status" => "",
        "net" => "M",
        "snum" => "",
        "xp" => 0,
        "gamecount" => 0,
        "gold" => 0,
        "treats" => 0,
        "hp" => 0,
        "wins" => 0,
        "sesscount" => 0,
        "losses" => 0,
        "speed" => 0,
        "attack" => 0,
        "defence" => 0,
        "jump" => 0
    };

    $self->{avatar} = {
        "color" => "0xffffff",
        "currentTurn" => "false",
        "startFireTick" => 0,
        "gunFirePower" => 0,
        "isFacingRight" => "true",
        "isWalkingLeft" => "false",
        "isWalkingRight" => "false",
        "waitingForJump" => "false",
        "jumpDirection" => "",
        "waitingForJumpTick" => 0,
        "underwater" => "false",
        "climbing" => "false",
        "digging" => "false",
        "angle" => "0",
        "superJumpTick" => 0,
        "gooTick" => 0,
        "moveGrappling" => 0,
        "durability" => [],
    };
    $self->{guid} = "";
    $self->{gsession} = "";
    $self->{gpos} = -1;
    $self->{connection_type} = "";
}


method construct_player_profile(){
    {
        "player"            => $self->{details}->{id},
        "color"             => $self->{avatar}->{color},
        "ownedPet"          => $self->{details}->{ownedPets}->{$self->{details}->{currentPet}},
        "currentTurn"       => $self->{avatar}->{currentTurn},
        "startFireTick"     => $self->{avatar}->{startFireTick},
        "gunFirePower"      => $self->{avatar}->{gunFirePower},
        "isFacingRight"     => $self->{avatar}->{isFacingRight},
        "isWalkingLeft"     => $self->{avatar}->{isWalkingLeft},
        "isWalkingRight"    => $self->{avatar}->{isWalkingRight},
        "waitingForJump"    => $self->{avatar}->{waitingForJump},
        "jumpDirection"     => $self->{avatar}->{jumpDirection},
        "waitingForJumpTick"=> $self->{avatar}->{waitingForJumpTick},
        "underwater"        => $self->{avatar}->{underwater},
        "climbing"          => $self->{avatar}->{climbing},
        "digging"           => $self->{avatar}->{digging},
        "angle"             => $self->{avatar}->{angle},
        "superJumpTick"     => $self->{avatar}->{superJumpTick},
        "gooTick"           => $self->{avatar}->{gooTick},
        "moveGrappling"     => $self->{avatar}->{moveGrappling}
    };
}

method setup($data){
    $self->{details}->{id} = $data->{id};
    $self->{details}->{dname} = $data->{usr};
    $self->{details}->{nw} = $data->{nw};
    $self->{details}->{level} = $data->{level};
    $self->{details}->{userAccessories} = $data->{userAccessories};
    $self->{details}->{accessories} = $data->{accessories};
    $self->{details}->{currentPet} = $data->{currentPet};
    $self->{details}->{login_streak} = $data->{login_streak};
    $self->{details}->{playerStatus} = $data->{playerStatus};
    $self->{details}->{status} = $data->{status};
    $self->{details}->{net} = $data->{net};
    $self->{details}->{snum} = $data->{snum};
    $self->{details}->{xp} = $data->{xp};
    $self->{details}->{gamecount} = $data->{gamecount};
    $self->{details}->{gold} = $data->{gold};
    $self->{details}->{treats} = $data->{treats};
    $self->{details}->{hp} = $data->{hp};
    $self->{details}->{wins} = $data->{wins};
    $self->{details}->{gold} = $data->{gold};
    $self->{details}->{sesscount} = $data->{sesscount};
    $self->{details}->{losses} = $data->{losses};
    $self->{details}->{speed} = $data->{speed};
    $self->{details}->{attack} = $data->{attack};
    $self->{details}->{defence} = $data->{defence};
    $self->{details}->{jump} = $data->{jump};
    $self->{details}->{ownedPets} = $data->{ownedPets};
    $self->{details}->{userWeaponsOwned} = $data->{userWeaponsOwned};
    $self->{details}->{userWeaponsEquipped} = $data->{userWeaponsEquipped};
    $self->{details}->{durability} = $data->{durability};
    $self->{details}->{command} = "player";

    $self->{details}->{online} = $self->{parent}->get_load();
}

method send_player($id){ #send client details about another client
    my $client_obj = $self->{parent}->get_player_by_id($id);
    $self->send($client_obj->{details});
}

method handle(){
    my $msg = $self->{buffer};

    if($msg =~ m/policy-file-request/){
        $self->write(qq(<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>\0));
    }elsif($msg =~ /^\x2d/){
        # \x2d type \x01 name \x01 password
        $self->{logger}->out("Login packet " . $msg . "\n" . Strings->to_hex($msg), Logger::LEVELS->{inf});
        my $packer = Packer->new();
        $packer->{buffer} = $msg;
        $packer->read_byte();
        my $action = $packer->read_byte();

        if($action == 1){
            my $usr = $packer->read_str();
            my $psw = $packer->read_str();

            $self->authenticate($usr, $psw);
        }

    }else{
        $self->{logger}->out("Packet [" .$self->{connection_type} . "]:" . $msg , Logger::LEVELS->{inf});

        if($msg =~ /^POST/){
            #for this to work I need
            # 1. Flower
            # 2. Eggs
            # 3. 2 spaces with the second containing an exclamation mark
            # on the left side of the exclamation mark there must be fk it; use try catch
            try{
                my $post_path = (split " ", $msg)[1];
                $self->{connection_type} = (split "/", (split /[?]/, $post_path)[0])[2];

                if($self->{connection_type} eq "game"){
                    my @game_tokens = (split "&", ((split /[?]/, $post_path)[1]));
                    $self->{guid} = (split "=", $game_tokens[0])[1];
                    $self->{gsession} = (split "=", $game_tokens[1])[1];

                    #print "guid is " . ($self->{guid}) . "\n\n";
                }

                #my $ctype = (split "?", $path)[0];
                #print "connection type is " . $ctype . "\n";
                print "PATH: " . $post_path, "\n";
                print "CTYPE " . $self->{connection_type}, "\n";
                if(!$self->posted_header()){
                    $self->{loader_information}->{posted_header} = 1;
                    $msg = substr $msg, index($msg, "\r\n\r\n");
                    $msg = substr $msg, 4;
                }

            }catch{
                $msg = "";
                $self->{logger}->out("Caught exception: " . $_, Logger::LEVELS->{wrn});
            };
        }

        $self->handle_json($msg);
          #  my $packet = substr $msg, $parts[0] + 1, $length;
          #  $self->{packet_position} = unpack("C", $packet);
          #  $packet = substr $packet, 1;
          #  my $headers = substr $packet, 0, 2;
          #  my $data = substr $packet, 2;

          #  my $handler = $self->{parent}->{handlers}->{$headers};

          #  if(defined $handler){
          #      foreach(values %{$self->{parent}->{crumbs}}){
          #          if($_->can($handler)){
          #              $_->$handler($data, $self);
          #          }
          #      }
          #  }else{
          #      $self->{logger}->out("Unhandled packet: " . Strings->to_hex($packet) , Logger::LEVELS->{inf});
          #  }
            #print $length . "\n";

    }
}

method authenticate($usr, $psw){
    $self->{logger}->out("User is trying to login with the following credentials $usr $psw", Logger::LEVELS->{inf});
    #generate key & add it to the database table
    my $packer = Packer->new();
    $packer->{buffer} = "";
    $packer->write_byte(45);
    $packer->write_byte(3);
    $packer->write_str("abc12345");
    print "Writing ", (length $packer->out()), " bytes of data\n";
    $self->write($packer->out());
}

method handle_json($msg){
    if($msg eq ""){ return; }
    if(substr($msg, 6, 1) ne "{" || substr($msg, (length $msg) - 1, 1) ne "}"){

        #print substr($msg, 4, 1) . " AND " . substr($msg, (length $msg) - 1, 1) . "\n";
        return };

    my $loc = $msg;
    my $len = substr $loc, 0, 6;
    my $len_n = 0;

    while($len ne ""){
        $len_n = $len_n * 10 + int(substr $len, 0, 1);
        $len = substr $len, 1, (length $len) - 1;
    }

    my $content = substr $loc, 6;

    if(length $content eq $len_n){
        #print "resulted: " . $content . "\n";
        my $obj = decode_json($content);
        my $cmd =  $obj->{command};

        my $handler = $self->{parent}->{handlers}->{$cmd};

        if(defined $handler){
            foreach(values %{$self->{parent}->{crumbs}}){
                if($_->can($handler)){
                    $_->$handler($obj, $self);
                }
            }
         }else{
             $self->{logger}->out("Unhandled packet: " . $cmd , Logger::LEVELS->{inf});
         }
    }else{
        #print "length is " . $len_n . " and actual length is " . (length $content);
        my $left_content = substr $content, $len_n;
        $content = substr $content, 0, $len_n;

        #print "\nContent I am now processing " . $content . "\n\n";
        #print "\nLeft content " . $left_content . "\n\n";

        $self->handle_json($left_content);

        #$content1 = substr $content, 0, ($len_n - 1);
        #$content2 = substr $content, $len_n -1 , read len

        my $obj = decode_json($content);
        my $cmd =  $obj->{command};

        my $handler = $self->{parent}->{handlers}->{$cmd};

        if(defined $handler){
            foreach(values %{$self->{parent}->{crumbs}}){
                if($_->can($handler)){
                    $_->$handler($obj, $self);
                }
            }
         }else{
             $self->{logger}->out("Unhandled packet: " . $cmd , Logger::LEVELS->{inf});
         }
    }
}

### SENDERS ###

method notify(){
    my $msg = {
        "command" => "alert",
        "text"    => "<font color='#ffffff'>Wild Ones : Private Wars</font>\n\nWelcome <font color='#d71212'>" . $self->{details}->{dname} ."</font>! Follow us on Twitter and like us on Facebook to stay updated with the latest events. The WOPW forums are also now open. \n\nYours truly,\nThe WOPW Team"
    };
    $self->send($msg);
}

method update(){
    $self->send($self->{details});
}

method charge_treats($amount){
    $self->{details}->{treats} -= $amount;
    $self->update();
}

method charge_gold($amount){
    $self->{details}->{gold} -= $amount;
    $self->update();
}

method update_treats($amount){
    $self->{details}->{treats} = $amount;
    $self->update();
}

method update_gold($amount){
    $self->{details}->{treats} = $amount;
    $self->update();
}

method add_weapon($type, $amount){
    if($self->{details}->{userWeaponsOwned}->{$type}){
        $self->{details}->{userWeaponsOwned}->{$type} += $amount;
    }else{
        $self->{details}->{userWeaponsOwned}->{$type} = $amount;
    }

    $self->update();
}

method send_fake_player($id, $name){
    my $container = $self->{details};
    $container->{dname} = $name;
    $container->{id} = $id;
    $self->send($container);
}

### GETS ###

method get_code(){
    return 0;
}

method get_privilege_level(){
    if($self->{details}->{is_guest}){
        return 0;
    }
}

method get_id(){
    if($self->{details}->{is_guest}){
        return 0;
    }
}

method get_level(){
    return $self->{details}->{level};
}

method get_usr(){
    return $self->{details}->{usr};
}

method posted_header(){
    return $self->{loader_information}->{posted_header};
}

###  I/O   ###

method send($packet){
    my $json_data = encode_json($packet);
    my $length = length $json_data;

    $length = sprintf("%06d", $length);
    my $output  = $json_data;
    if($self->{loader_information}->{posted_header} != 2){
        $output = $length . $output;
        $output = $self->{inspiration} . $output;
        $self->write($output);
        $self->{logger}->out("Added inspiration", Logger::LEVELS->{inf});
        $self->{logger}->out("Output " . $output, Logger::LEVELS->{inf});
        $self->{loader_information}->{posted_header} = 2;
        return;
    }
    # 6
    $self->write($length);
    $self->write($output);
    $self->{logger}->out("Sent unencrypted " . $output, Logger::LEVELS->{inf});
}

method write($msg){
    $self->{stream}->send($msg);
    $self->{stream}->flush;
}

method disconnect(){
    $self->{logger}->out("Disconnecting", Logger::LEVELS->{dbg});

    if($self->{connection_type} eq "game"){
        #remove from games
        if($self->{guid} ne ""){
            #$self->{parent}->remove_player_from_game($self->{guid});
            delete($self->{parent}->{games}->{$self->{guid}}->{players}->{$self->{details}->{id}});
            my $hr = $self->{parent}->{games}->{$self->{guid}}->{players};
            my @list_data = map { s/^test(\d+)/part${1}_0/; $_ } values %$hr;
            my $msg = {"command" => "game", "status" => "idle", "playerCount" => 1, "id" => $self->{guid}, "min" => 2, "players" => \@list_data, "map" => "Crash Landing", "name" => "Crash Landing", "cl" => 0, "skip"=> [], "sumOfLevels" => 10, "turnDuration" => 60000, "gameDuration" => 600000, "time" => 1464593355058};
            $self->{parent}->send_to_game($self->{guid}, $msg, $self->{details}->{id});
        }
    }
}

1;
