package Database;

use MongoDB;
use Server::Plugin::Logger;

use Method::Signatures::Simple;
use Mo;

use Data::Dumper;


has "client";
has "logger";

my $user_collection = "WO_Emu.wo_users";

method ini {
    $self->{logger} = Logger->new(origin => "database");
    $self->{client} = MongoDB->connect("mongodb://localhost");
    $self->{users} = $self->{client}->ns($user_collection);


    $self->{logger}->out("Connected to MongoDB Server", Logger::LEVELS->{inf});

    #print ($self->exists({"id" => 1}));
}

method get_player_by_name($val){
    return $self->{users}->find({"usr" => $val})->next;
}

method get_player_by_id($val){
    return $self->{users}->find({"id" => $val})->next;
}

method exists($val){
    return 1 if $self->{users}->find_one($val);
    return 0;
}

return 1;
