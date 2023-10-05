namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig         [namespace code go_greedy_pig]
	asSetAct KOJOLU_lobby         	  [namespace code lobby]
	asSetAct KOJOLU_deposit			  [namespace code deposit]
	asSetAct KOJOLU_login  	  		  [namespace code go_login]
	asSetAct KOJOLU_pollGame		  [namespace code go_pollGame]
	asSetAct KOJOLU_game			  [namespace code go_game]
	asSetAct KOJOLU_checklimit		  [namespace code go_check_limit]
	asSetAct KOJOLU_roll_dice_event   [namespace code roll_dice_event]
	asSetAct KOJOLU_findRoomJSON   	  [namespace code findRoomJSON]
	asSetAct KOJOLU_roll_one_event    [namespace code roll_one_event]
	asSetAct KOJOLU_hold_event		  [namespace code go_hold_event]
	asSetAct KOJOLU_win_event 		  [namespace code win_event]
	asSetAct KOJOLU_PollPlayerTwo     [namespace code pollPlayerTwo]
	asSetAct KOJOLU_insertFirst       [namespace code insert_first_event]
	asSetAct KOJOLU_getLatestEventJSON [namespace code getLatestEventJSON]

	proc update_transactions {user_id transaction_type game_id amount} {

		set insert_game_transaction_winner {
			insert into 
				tTransactionKojolu (amount, transaction_type, game_id, account_no)
			values
				(?, ?, ?, ?)
		}

		set stmt [inf_prep_sql $DB $insert_game_transaction_winner]
		inf_exec_stmt $stmt $amount $transaction_type $game_id $user_id
		
		inf_close_stmt $stmt
	}

	proc getLatestEventJSON args {
		
		set game_id [reqGetArg gameId]

		set event_list_values [getMostRecentEventForGameId $game_id]
		puts "the event values are $event_list_values"
		set key_list [list "event_id" "current_player_id" "waiting_player_id" "current_player_accum" "time_event" "roll_result" "player_action" "player_1_score" "player_2_score" "game_id"]

		build_json $key_list $event_list_values
	}

	proc insert_first_event args {

		set game_id [reqGetArg gameId]

		global DB

		set get_usernames {
			select 
				username 
			from 
				tUserKojolu 
			where 
				user_id 
			in 
				(?,?) 
		}

		set check_empty_events {

			select 
				event_id
			from
				tGameEventKojolu 
			where
				game_id = ?
		}

		set get_player_ids {
			
			select
				player_1_id,
				player_2_id
			from 
				tGameKojolu
			where 
				game_id = ?
		}

		set insert_first_event {

			insert into
				tGameEventKojolu (current_player_id, waiting_player_id, game_id, time_event)
			values
				(?, ?, ?, CURRENT year to second)
		}

		set get_first_event {

			select first 1
				event_id, 
				current_player_id, 
				waiting_player_id				
			from 
				tGameEventKojolu
			where
				game_id = ?
			order by 
				event_id
			ASC
		}

		set stmt [inf_prep_sql $DB $check_empty_events]
		set rs   [inf_exec_stmt $stmt $game_id]
		set rows [db_get_nrows $rs]

		inf_close_stmt $stmt
		db_close $rs	

		if {$rows == 0} {

			set stmt [inf_prep_sql $DB $get_player_ids]
			set rs   [inf_exec_stmt $stmt $game_id]

			set p1 [db_get_col $rs 0 player_1_id]
			set p2 [db_get_col $rs 0 player_2_id]

			inf_close_stmt $stmt
			db_close $rs	

			set random_number [expr {rand()}]

			# Use a conditional statement to assign current_player_id and waiting_player_id based on the random number
			if {$random_number < 0.5} {
				set p1_seed $p1
				set p2_seed $p2
			} else {
				set p1_seed $p2
				set p2_seed $p1
			}			

			set stmt [inf_prep_sql $DB $insert_first_event]
			inf_exec_stmt $stmt $p1_seed $p2_seed $game_id
			inf_close_stmt $stmt

			set stmt [inf_prep_sql $DB $get_usernames]
			set rs [inf_exec_stmt $stmt $p1 $p2]

			build_json [list "game_table_player_1_id" "game_table_player_2_id" "current_player_id" "waiting_player_id" "player_1_username" "player_2_username"] [list "$p1" "$p2" "$p1_seed" "$p2_seed" "[db_get_col $rs 0 username]" "[db_get_col $rs 1 username]"]			
			
			inf_close_stmt $stmt
			db_close $rs	

		} else {
			set stmt [inf_prep_sql $DB $get_player_ids]
			set rs   [inf_exec_stmt $stmt $game_id]

			set p1_g [db_get_col $rs 0 player_1_id]
			set p2_g [db_get_col $rs 0 player_2_id]

			inf_close_stmt $stmt
			db_close $rs	

			set stmt [inf_prep_sql $DB $get_first_event]
			set rs   [inf_exec_stmt $stmt $game_id]

			set p1 [db_get_col $rs 0 current_player_id]
			set p2 [db_get_col $rs 0 waiting_player_id]

			inf_close_stmt $stmt
			db_close $rs	

			set stmt [inf_prep_sql $DB $get_usernames]
			set rs [inf_exec_stmt $stmt $p1_g $p2_g]

			build_json [list "game_table_player_1_id" "game_table_player_2_id" "current_player_id" "waiting_player_id" "player_1_username" "player_2_username"] [list "$p1_g" "$p2_g" "$p1" "$p2" "[db_get_col $rs 0 username]" "[db_get_col $rs 1 username]"]

			inf_close_stmt $stmt
			db_close $rs	
		}
	}


 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}

	proc go_check_limit args {
		
		global DB

		set user_id [reqGetArg id]

		set get_remaining_limit {
			select 
				remaining_limit,
				last_top_up_time
			from 
				tUserKojolu tu,
				tAccountKojolu ta
			where
				ta.user_id = tu.user_id and
				ta.user_id = ?
		}	

		set reset_limit {
			update
				tAccountKojolu ta
			set 
				remaining_limit = 100,
				last_top_up_time = CURRENT year to second
			where
				ta.account_no = ?
		}

		set stmt [inf_prep_sql $DB $get_remaining_limit]
		set rs   [inf_exec_stmt $stmt $user_id]

		set remaining_limit [db_get_col $rs 0 remaining_limit]
		set last_top_up_time [db_get_col $rs 0 last_top_up_time]

		inf_close_stmt $stmt
		db_close $rs	

		# user hasn't made a deposit before
		if {$last_top_up_time == ""} {

			build_json {"is_reached"} [list 0]
			return
			
		}

		# Get the current time in the same format as db time (year to seconds)
		set current_time [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

		# Convert both times to Unix timestamps
		set last_top_up_timestamp [clock scan $last_top_up_time -format "%Y-%m-%d %H:%M:%S"]
		set current_timestamp [clock scan $current_time -format "%Y-%m-%d %H:%M:%S"]

		# Calculate the time difference in seconds
		set time_difference [expr {$current_timestamp - $last_top_up_timestamp}]

		# if 24hrs have passed, reset user's remaining limit
		if {$time_difference >= 86400} {

			set stmt [inf_prep_sql $DB $reset_limit]
			inf_exec_stmt $stmt $user_id
			
			inf_close_stmt $stmt
			build_json {"is_reached" "remaining_limit" "refresh"} "0 100 1"

		} elseif {$remaining_limit <= 0} {

			# Calculate the next top-up time
			set next_top_up_timestamp [expr {$last_top_up_timestamp + 86400}]
			set next_top_up_time [clock format $next_top_up_timestamp -format "%Y-%m-%d %H:%M:%S"]

			build_json {"is_reached" "next_top_up_time"} [list 1 "$next_top_up_time"]

		} else {
 
			build_json {"is_reached" "remaining_limit"} "0 $remaining_limit"

		}

	}

	proc lobby args {
		
		set userid [reqGetArg userid]
		set username [reqGetArg username]

		getRoom

		tpBindString username $username
		tpBindString userid $userid

		getUserAccount $userid
  		asPlayFile -nocache training/greedy_pig/lobby.html
		
	}

	proc go_login args {

		global DB

		# get username from request URL sent from frontend login.js
		set username [reqGetArg username]

		# statement used to insert a new user if the username entered doesn't already exist
		set insert_new_user {
			insert into 
				tUserKojolu (username)
			values
				(?)
		}

		# statement used to create a new account associated for a new user.
		set insert_new_user_account {
			insert into 
				tAccountKojolu (account_no, balance, deposit_limit, remaining_limit, user_id, account_type)
			values
				(?, ?, ?, ?, ?, ?)
		}

		# statement used to check if user exists
		set get_users {
			select 
				user_id,
				username
			from 
				tUserKojolu tu
			where
				tu.username = ?
		}	
				
		set stmt [inf_prep_sql $DB $get_users]
		set rs_users   [inf_exec_stmt $stmt $username]
		
		# number of users retrieved with entered username
		set num_users [db_get_nrows $rs_users]

		puts "==================================================================="
		puts "Number of users with username \($username\): $num_users -> \[MSG LOCATION: go_login proc\]"
		puts "==================================================================="


		# if the number of users retrived is 0, the username doesn't exist so create a new user
		if {$num_users == 0} {

			#insert new user
			set stmt [inf_prep_sql $DB $insert_new_user]
			inf_exec_stmt $stmt $username

			# get id of newly added user
			set stmt [inf_prep_sql $DB $get_users]
			set rs   [inf_exec_stmt $stmt $username]

			set user_id [db_get_col $rs 0 user_id]
			set u_name [db_get_col $rs 0 username]

			# create the new user account associated with user
			set stmt [inf_prep_sql $DB $insert_new_user_account]
			set rs   [inf_exec_stmt $stmt $user_id 0.00 100.00 100.00 $user_id Debit]

			inf_close_stmt $stmt
			db_close $rs	

			build_json {"id" "username"} "$user_id $u_name"

		} else {
			
			set user_id [db_get_col $rs_users 0 user_id]
			set u_name [db_get_col $rs_users 0 username]
			
			inf_close_stmt $stmt
			db_close $rs_users

			build_json {"id" "username"} "$user_id $u_name"
		}
		
	}

	# generalised json function, takes a list of keys (what items will be referenced as in the front end)
	# and takes a list of values associated to the keys
	# finally returns a JSONified string 
	proc build_json {key_list value_list} {
		set JSON ""
		set open_brace "\{"
		set end_brace "\}"
		set json_string ""
		set final_json ""
		set list_length [llength $key_list]


		for {set i 0} {$i < $list_length} {incr i} {

			append json_string "\"[lindex $key_list $i]\":\"[lindex $value_list $i]\""

			if {$i != [expr $list_length - 1] } {
					append json_string ","
			}
		}

		append JSON $open_brace$json_string$end_brace
		tpBindString JSON $JSON

  		asPlayFile -nocache training/greedy_pig/json.html
	}

	proc getUserAccount userId {
		global DB

		set sql {
			select
				ta.balance,
				ta.remaining_limit
			from
				tAccountKojolu ta
			inner join 
			tUserKojolu tu
			on ta.user_id = tu.user_id
			where tu.user_id = ?;
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $userId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			tpSetVar found_balance 1
			tpBindString balance [db_get_col $rs 0 balance]
			tpBindString remaining_limit [db_get_col $rs 0 remaining_limit]

		}
		catch {db_close $rs}
	}

	proc updateUserDeposit {userId type amount} {
		global DB


		# statment that logs transactions for deposits 
		set insert_transaction {
			insert into 
				tTransactionKojolu (amount, transaction_type, account_no)
			values
				(?, ?, ?)
		}

		set sql {
			update 
				tAccountKojolu
			set
				balance = balance + ?,
				last_top_up_time = CURRENT year to second,
				remaining_limit = remaining_limit - ?
			where 
				user_id = ?;
	
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $amount $amount $userId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}
		catch {db_close $rs}
		
		# insert deposit as transaction
		set stmt [inf_prep_sql $DB $insert_transaction]
		inf_exec_stmt $stmt $amount $type $userId 

		inf_close_stmt $stmt

	}

	proc getRoom {} {

		global DB ROOM

		set sql {
			select
				room_id,
				stake_amount,
				win_amount
			from
				tPlayRoomKojolu
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {

			tpSetVar found_room 1

		}

		set amountRows [db_get_nrows $rs]
		tpSetVar rooms $amountRows 

		for {set i 0} {$i < $amountRows} {incr i} {

			set ROOM($i,room_id) [db_get_col $rs $i room_id]
			set ROOM($i,stake_amount) [db_get_col $rs $i stake_amount]
			set ROOM($i,win_amount) [db_get_col $rs $i win_amount]

		}

		tpBindVar ROOM_ID ROOM room_id room_idx
		tpBindVar ROOM_STAKE ROOM stake_amount room_idx
		tpBindVar ROOM_WIN 	 ROOM win_amount   room_idx
	
		catch {db_close $rs}

	}

	proc deposit args {

		set userid [reqGetArg userid]
		set amount [reqGetArg amount]

		updateUserDeposit $userid "DEPOSIT" $amount
	}

	proc go_pollGame args {

		set name [reqGetArg name]
		puts "hi $name"

	}

	proc go_game args {	

		gameInit

		asPlayFile -nocache training/greedy_pig/index.html

	}

	proc gameInit {} {
		global roomIdPlayer
		set userId [reqGetArg userId]
		set balance [reqGetArg balance]
		set roomId [reqGetArg roomId]
		set roomStake [reqGetArg roomStake]
		set roomWin [reqGetArg roomWin]
		tpBindString roomIdPlayer $roomId

		puts "INSIDE GAME INIT  ======= $roomId $roomStake $roomWin $userId"

		set gameIdRejoin [findGameRejoin $roomId $userId]	
		set gameIdNew [findGameNew $roomId $userId]	


		if {$gameIdRejoin} {
			joinGame $gameIdRejoin $userId
		} elseif {$gameIdNew} {
			joinGame $gameIdNew $userId
			updateUserDeposit $userId "room_stake" "\-$roomStake"
		} else {
			puts "cREATING GAME"
			createGame $roomId $userId
			updateUserDeposit $userId "room_stake" "\-$roomStake"
		}

	}

	proc checkBalanceForGame {userId roomStake} {
		global DB

		puts "CHECKING BALNACE =============+ USER ID $userId, roomStakte $roomStake"

		set sql {
			select
				ta.balance
			from
				tAccountKojolu ta
			inner join 
			tUserKojolu tu
			on ta.user_id = tu.user_id
			where tu.user_id = ?;
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $userId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			set balance [db_get_col $rs 0 balance]
		}
		catch {db_close $rs}

		puts "INISDE CHECK BALANCE ============== BALANCE IS $balance"

		if {$balance < $roomStake} {
			set fundAvailable 0
			tpSetVar funds $fundAvailable
			puts "INISDE IF FUNDSAVAILBE ============== FUND AVAILBE $fundAvailable"

			return $fundAvailable
		} else {
			set fundAvailable 1
			tpSetVar funds $fundAvailable
			puts "INISDE IF FUNDSAVAILBE ============== FUND AVAILBE $fundAvailable"

			return $fundAvailable

		}

	}

	proc createGame {roomId player_one_id} {
		global DB

		set sql {
			insert into 
				tGameKojolu (room_id, player_1_id)
			values
				(?, ?)
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch [inf_exec_stmt $stmt $roomId $player_one_id] msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		tpSetVar created_game 1
		
	
		catch {db_close $rs}
	}

	proc findGameRejoin {roomId playerId} {
		puts "INSIDE FIND GAMEEEE ROOM ID $roomId player id : $playerId"
		global DB

		set sql {
			select 
				game_id	
			from 
				tGameKojolu
			where 
				room_id = ? AND
				end_time is NULL AND
				(player_1_id = ? OR
				player_2_id = ?)
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $roomId $playerId $playerId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			tpSetVar game_exists 1
			#TODO add a check for the first game created and grab that one instead
			set game_id [db_get_col $rs 0 game_id]
			tpBindString game_id $game_id
			puts "GAME HAS BEEN FOUND APPARENTLY [db_get_nrows $rs]" 

			catch {db_close $rs}

			return $game_id
		} else {
			tpSetVar game_exists 0
			catch {db_close $rs}
			return 0
		}
	
		
	}

	proc findGameNew {roomId playerId} {
		puts "INSIDE FIND GAMEEEE ROOM ID $roomId player id : $playerId"
		global DB

		set sql {
			select 
				game_id	
			from 
				tGameKojolu
			where 
				room_id = ? AND
				end_time is NULL AND
				(player_1_id != ? AND 
				player_2_id is NULL)
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $roomId $playerId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			tpSetVar game_exists 1
			#TODO add a check for the first game created and grab that one instead
			set game_id [db_get_col $rs 0 game_id]
			tpBindString game_id $game_id
			puts "GAME HAS BEEN FOUND APPARENTLY [db_get_nrows $rs]" 

			catch {db_close $rs}

			return $game_id
		} else {
			tpSetVar game_exists 0
			catch {db_close $rs}
			return 0
		}
	
		
	}

	proc roll_dice_event args {
		puts "INSIDE ROLL DICE =============+"
			
			set roll_result [reqGetArg roll_result]
			set player_action "ROLL"
			set game_id [reqGetArg game_id]
			set userId [reqGetArg current_player_id]


			set lastGameEventList [getMostRecentEventForGameId $game_id]

			set current_player_accum [expr [lindex $lastGameEventList 3] + $roll_result]

			insertEvent $userId [lindex $lastGameEventList 2] $current_player_accum $roll_result [lindex $lastGameEventList 7] [lindex $lastGameEventList 8] $player_action $game_id
		
	}


	proc roll_one_event args {	
		puts "INSIDE ROLL ONE ==============+++"
	
				
		set player_action "ROLL"
		set game_id [reqGetArg game_id]
		set user_id [reqGetArg user_id]
		set waiting_player_id [getMostRecentEventWaitingPlayerId $game_id]
		
		set lastGameEventList [getMostRecentEventForGameId $game_id]

		insertEvent $waiting_player_id $user_id 0 1 [lindex $lastGameEventList 7] [lindex $lastGameEventList 8] $player_action $game_id
	
	}

	proc go_hold_event args {

		puts "inside HOLDDD ==============="
		set player_action "HOLD"
		set game_id [reqGetArg game_id]
		set user_id [reqGetArg user_id]		
		set whichPlayer [getCurrentPlayer $game_id $user_id]

		set lastGameEventList [getMostRecentEventForGameId $game_id]

		if {$whichPlayer == 1} {
			set player_1_score [expr [lindex $lastGameEventList 7] + [lindex $lastGameEventList 3]]
			insertEvent [lindex $lastGameEventList 2] [lindex $lastGameEventList 1] 0 0 $player_1_score [lindex $lastGameEventList 8] $player_action $game_id
		} elseif {$whichPlayer == 2} {
			set player_2_score [expr [lindex $lastGameEventList 8] + [lindex $lastGameEventList 3]]
			insertEvent [lindex $lastGameEventList 2] [lindex $lastGameEventList 1] 0 0 [lindex $lastGameEventList 7] $player_2_score $player_action $game_id
		}
		
	}

	proc win_event args {

        set game_id [reqGetArg game_id]
        set lastGameEventList [getMostRecentEventForGameId $game_id]

    	updateGameWin $game_id [lindex $lastGameEventList 2] [lindex $lastGameEventList 1]

		set game_values [get_game_info $game_id]
		set room_values [get_room_values [lindex $game_values 1]]

		update_transactions [lindex $game_values 0] GAME_PRIZE $game_id [lindex $room_values 0]
				
    }	
	
	proc get_game_info {game_id} {

		global DB

		set get_info {
			select
				winner_id,
				room_id
			from 
				tGameKojolu
			where
				game_id = ?
		}

		set stmt [inf_prep_sql $DB $get_info]
		set rs inf_exec_stmt $stmt $game_id 
		
		set winner_id [db_get_col $rs 0 winner_id]
		set room_id [db_get_col $rs 0 room_id]

		inf_close_stmt $stmt
		db_close $rs

		return [list $winner_id $room_id]
	}

	proc get_room_values {room_id} {
		
		global DB

		set get_room_values {
			select 
				win_amount
			from 
				tPlayRoomKojolu
			where
				room_id = ?
		}

		set stmt [inf_prep_sql $DB $get_room_values]
		set rs inf_exec_stmt $stmt $room_id 
		
		set win_amount [db_get_col $rs 0 win_amount]

		inf_close_stmt $stmt
		db_close $rs

		return [list $win_amount]
	}

	proc go_pollGame args {
		set name [reqGetArg name]
		puts "hi $name"
	}

	proc joinGame {gameId playerId} {
		puts "INSIDE OF JOIN GAMEEE"
		global DB

		set sql {
			update
				tGameKojolu 
			set
				player_2_id = ? 
			where
				game_id = ? AND
				player_1_id != ?
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch [inf_exec_stmt $stmt $playerId $gameId $playerId] msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		tpSetVar joined_game 1

		catch {inf_close_stmt $stmt}

		catch {db_close $rs}
		
	}


	proc insertEvent {current_player_id waiting_player_id current_player_accum roll_result player_1_score player_2_score player_action game_id} {
		global DB

		puts "INSIDE INSERT EVENT"
		set sql_insert {
			INSERT INTO
				tGameEventKojolu (current_player_id, waiting_player_id, current_player_accum, time_event, roll_result, player_1_score, player_2_score, player_action, game_id)
			VALUES
				(?, ?, ?, CURRENT year to second, ?, ?, ?, ?, ?);	
		}
					puts "AFTER SQL HAS BEEN DEFINED WHICH IS $sql_insert"

		
		if {[catch {set stmt [inf_prep_sql $DB $sql_insert]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}
		puts "AFTER THE SET STM $stmt"
		if {[catch {set rs [inf_exec_stmt $stmt $current_player_id $waiting_player_id $current_player_accum $roll_result $player_1_score $player_2_score $player_action $game_id] msg}]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
			catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		puts "AFTER THE EXECUTING"

		
		catch {inf_close_stmt $stmt}
		catch {db_close $rs}

	}

	proc updateGameWin {game_id winner_id loser_id} {
		global DB

		set sql {
			update 
				tGameKojolu
			set
				winner_id = ?,
				loser_id = ?,
				end_time = CURRENT year to second
			where 
				game_id = ?;
	
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $winner_id $loser_id $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}
		catch {db_close $rs}

	}



	proc findRoomJSON args {
		set roomId [reqGetArg roomId]
		set userId [reqGetArg userId]

		set room [findGameRejoin $roomId $userId]

		build_json {"room"} "$room"

	}

proc pollPlayerTwo args {
		puts "INSIDE POLL PLAYER 2"
		global DB

		set gameId [reqGetArg gameId]

		set sql {
			select 
				player_2_id
			from 
				tGameKojolu
			where 
				game_id = ? AND
				player_2_id is not null
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $gameId]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}


		puts "AMOUNT OF ROWS IS [db_get_nrows $rs]"
		if {[db_get_nrows $rs]} {
			tpSetVar loading 0
			tpSetVar game_exists 1
			set game_id [db_get_col $rs 0 player_2_id]
			tpBindString game_id $game_id
			puts "GAME HAS BEEN FOUND APPARENTLY [db_get_nrows $rs]" 
			build_json "full" "1"
			catch {db_close $rs}

		} else {
			tpSetVar loading 1
			tpSetVar game_exists 0
			catch {db_close $rs}
			build_json "full" "0"
		}
	}

	proc getCurrentPlayer {game_id current_player_id} {
		global DB
		set sql {
			select 
				player_1_id,
				player_2_id
			from 
				tGameKojolu
			where 
				game_id = ?
		
		}
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}
		if {[catch {set rs [inf_exec_stmt $stmt $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		catch {inf_close_stmt $stmt}
		if {[db_get_nrows $rs]} {
			set player_1_id [db_get_col $rs 0 player_1_id]
			set player_2_id [db_get_col $rs 0 player_2_id]
			catch {db_close $rs}
		} 
		puts "CURRENT PLAYER IS $current_player_id PLAYER 1 IS $player_1_id PLYAER 2 IS $player_2_id"
		
		if {$current_player_id == $player_1_id} {
			return 1
			
		} elseif {$current_player_id == $player_2_id} {
			return 2
		}
	}
	
	
	
	proc getMostRecentEventWaitingPlayerId {game_id} {
	global DB 
	
	set sql {
			select first 1
				waiting_player_id
			from 
				tGameEventKojolu
			where 
				game_id = ?
			ORDER BY 
				event_id
			DESC
		}
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}
		if {[catch {set rs [inf_exec_stmt $stmt $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		catch {inf_close_stmt $stmt}
		if {[db_get_nrows $rs]} {
			tpSetVar event_exists 1
			set waiting_player_id [db_get_col $rs 0 waiting_player_id]
			puts "wating PLAYER IS IS ========================== $waiting_player_id"
			return $waiting_player_id
			catch {db_close $rs}
		}
	}

	
proc getMostRecentEventCurrentPlayerId {game_id} {
	global DB 
	
	set sql {
			select first 1
				current_player_id
			from 
				tGameEventKojolu
			where 
				game_id = ?
			ORDER BY 
				event_id
			DESC
		}
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}
		if {[catch {set rs [inf_exec_stmt $stmt $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		catch {inf_close_stmt $stmt}
		if {[db_get_nrows $rs]} {
			tpSetVar event_exists 1
			set current_player_id [db_get_col $rs 0 current_player_id]
			return $current_player_id
			catch {db_close $rs}
		}
	}


	proc getMostRecentEventForGameId {game_id} {
	global DB 
	
	set sql {
			select first 1
				event_id,
				current_player_id,
				waiting_player_id,
				current_player_accum,
				time_event,
				roll_result,
				player_action,
				player_1_score,
				player_2_score,
				game_id
			from 
				tGameEventKojolu
			where 
				game_id = ?
			ORDER BY 
				event_id
			DESC
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			tpSetVar event_exists 1
			set event_id [db_get_col $rs 0 event_id]
			set current_player_id [db_get_col $rs 0 current_player_id]
			set waiting_player_id [db_get_col $rs 0 waiting_player_id]
			set current_player_accum [db_get_col $rs 0 current_player_accum]
			set time_event [db_get_col $rs 0 time_event]
			set roll_result [db_get_col $rs 0 roll_result]
			set player_action [db_get_col $rs 0 player_action]
			set player_1_score [db_get_col $rs 0 player_1_score]
			set player_2_score [db_get_col $rs 0 player_2_score]
			set game_id [db_get_col $rs 0 game_id]

			catch {db_close $rs}
			return [list $event_id $current_player_id $waiting_player_id $current_player_accum $time_event $roll_result $player_action $player_1_score $player_2_score $game_id] 

		}
	}
}