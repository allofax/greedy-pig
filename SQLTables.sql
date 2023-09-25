drop table tUserKojolu;
drop table tAccountKojolu;
drop table tTransactionKojolu;
drop table tPlayRoomKojolu;
drop table tGameKojolu;
drop table tGameEventKojolu;


create table tUserKojolu
(
	user_id 		serial  				not null,
	username		varchar(30)				not null,
	cr_date datetime year to second default CURRENT year to second not null,
	login_count 	int 		default 1 	not null
);

create table tAccountKojolu
(
	account_no	serial		not null,
	balance		decimal(8,2) 	default 0 	not null,
	deposit_limit 		decimal(6,2) 	default 100,
	last_top_up_time datetime year to second,
	remaining_limit decimal(6,2) default 100,
	user_id 	int			not null,
	account_type varchar(30)
);


create table tTransactionKojolu
(
	transaction_id 	serial 		not null,
	amount		decimal(8,2) 	not null,
	transaction_type varchar(15) 	not null,
	date_now 		datetime year to second default CURRENT year to second	not null,
	game_id		int,	
	account_no 	int 		not null
);

create table tPlayRoomKojolu 
(
	room_id		serial		not null,
	stake_amount	int		default 0 	not null,
	win_amount	int		default 0 	not null
);

create table tGameKojolu
(
	game_id		serial 		not null,
	player_1_id	int		not null,
	player_2_id 	int		not null,
	room_id		int 		not null,
	winner_id	int,		
	loser_id	int,
	start_time	datetime year to second default CURRENT year to second	not null,
	end_time	datetime year to second
);

create table tGameEventKojolu
(
	event_id 	serial 		not null,
	current_player_id int 		not null,
	waiting_player_id int		not null,
	current_player_accum int 	default 0 not null,
	time_event	datetime year to second,
	roll_result	  int,
	player_action	  char(4),
	player_1_score 	int default 0	not null,
	player_2_score 	int default 0	not null,
	game_id 		int 			not null
);

alter table tUserKojolu add constraint (
	primary key(user_id)
		constraint cUserKojolu_pk
);

alter table tUserKojolu add constraint (
	unique (username)
		constraint cUserKojolu_u1
);

alter table tUserKojolu add constraint (
	check (length(username) <> '')
		constraint cUserKojolu_c1
);
	
alter table tAccountKojolu add constraint (
	primary key(account_no)
		constraint cAccountKojolu_pk
);

alter table tAccountKojolu add constraint (
	foreign key(user_id) references tUserKojolu(user_id)
		constraint cAccountKojolu_f2
);

alter table tAccountKojolu add constraint (
	check (balance >= 0)
		constraint cAccountKojolu_c1
);

alter table tTransactionKojolu add constraint (
	primary key(transaction_id)
		constraint cTransactionKojolu_pk
);

alter table tGameKojolu add constraint (
	primary key(game_id)
		constraint cGameKojolu_pk
);

alter table tTransactionKojolu add constraint (
	foreign key(game_id) references tGameKojolu(game_id)
		constraint cTransactionKojolu_f1
);

alter table tTransactionKojolu add constraint (
	foreign key(account_no) references tAccountKojolu(account_no)
		constraint cTransactionKojolu_f2
);

alter table tPlayRoomKojolu add constraint (
	primary key(room_id)
		constraint cPlayRoomKojolu_pk
);



alter table tGameKojolu add constraint (
	foreign key(player_1_id) references tUserKojolu(user_id)
		constraint cGameKojolu_f1
);

alter table tGameKojolu add constraint (
	foreign key(player_2_id) references tUserKojolu(user_id)
		constraint cGameKojolu_f2
);

alter table tGameKojolu add constraint (
	foreign key(room_id) references tPlayRoomKojolu(room_id)
		constraint cGameKojolu_f3
);


alter table tGameEventKojolu add constraint (
	primary key(event_id)
		constraint cGameEventKojolu_pk
);

alter table tGameEventKojolu add constraint (
	foreign key(current_player_id) references tUserKojolu(user_id)
		constraint cGameEventKojolu_f1
);

alter table tGameEventKojolu add constraint (
	foreign key(waiting_player_id) references tUserKojolu(user_id)
		constraint cGameEventKojolu_f2
);

alter table tGameEventKojolu add constraint (
	foreign key(game_id) references tGameKojolu(game_id)
		constraint cGameEventKojolu_f3
);
