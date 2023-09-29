namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig         [namespace code go_greedy_pig]
	asSetAct KOJOLU_lobby         	  [namespace code lobby]
	asSetAct KOJOLU_deposit			  [namespace code deposit]
	asSetAct KOJOLU_login  	  		  [namespace code go_login]
	asSetAct KOJOLU_pollGame		  [namespace code go_pollGame]
	asSetAct KOJOLU_game			  [namespace code go_game]
	asSetAct KOJOLU_roll_dice 		  [namespace code roll_dice_event]
	asSetAct KOJOLU_checklimit		  [namespace code go_check_limit]

 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}

	proc go_check_limit args {
		
		#TODO implement 24hr check

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

		set stmt [inf_prep_sql $DB $get_remaining_limit]
		set rs   [inf_exec_stmt $stmt $user_id]

		set remaining_limit [db_get_col $rs 0 remaining_limit]

		inf_close_stmt $stmt
		db_close $rs	

		if {$remaining_limit <= 0} {
			build_json {"is_reached"} "1"
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

	proc updateUserDeposit {userId amount} {
		global DB

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

		updateUserDeposit $userid $amount
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
		set userId [reqGetArg userId]
		set balance [reqGetArg balance]
		set roomId [reqGetArg roomId]
		set roomStake [reqGetArg roomStake]
		set roomWin [reqGetArg roomWin]

		puts "INSIDE GAME INIT  ======= $roomId $roomStake $roomWin $userId"

		set gameId [findGame $roomId $userId]	

		if {$gameId} {
			joinGame $gameId $userId
		} else {
			createGame $roomId $userId

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

	proc findGame {roomId playerId} {
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
				player_2_id = ? OR
				player_2_id is NULL)
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

proc roll_dice_event args {
		# Hardcoded game ID of one
		
		set current_player_id [reqGetArg current_player_id]
		set waiting_player_id [reqGetArg waiting_player_id]
		set current_player_accum [reqGetArg current_player_accum]
		set roll_result [reqGetArg roll_result]
		set player_1_score [reqGetArg player_1_score]
		set player_2_score [reqGetArg player_2_score]
		set player_action "ROLL"
		set game_id [reqGetArg game_id] 		;#change later!
	
		global DB
		
		puts "===============================pre SQL statement for roll dice"
	
		set sql {
			INSERT INTO
				tGameEventKojolu (current_player_id, waiting_player_id,current_player_accum, time_event, roll_result, player_1_score, player_2_score, player_action, game_id)
			VALUES
				(?, ?, ?, CURRENT year to second, ?, ?, ?, ?);	
		}
		
		puts "===============================pre execution"
	
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}
	
		if {[catch {set rs [inf_exec_stmt $stmt $current_player_id $waiting_player_id $current_player_accum $roll_result $player_1_score $player_2_score $player_action $game_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
				catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}
		
	puts "===============================post execution"
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

}