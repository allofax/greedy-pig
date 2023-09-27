namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig         [namespace code go_greedy_pig]
	asSetAct KOJOLU_lobby         	  [namespace code lobby]
	asSetAct KOJOLU_deposit			  [namespace code deposit]
	asSetAct KOJOLU_login_JSON    [namespace code go_login_JSON]
	asSetAct KOJOLU_pollGame	[namespace code go_pollGame]

 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}
	proc lobby args {
		puts "INSIDE LOBBY =============================== [reqGetArg userid]"
		set userid [reqGetArg userid]
		set username [reqGetArg username]


		getRoom

		tpBindString username $username
		getUserAccount $userid

  		asPlayFile -nocache training/greedy_pig/lobby.html
	}

		proc go_login_JSON args {
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

		puts "==================================================="
		puts "$num_users"
		puts "==================================================="

		set json_pairs ""

		# if the number of users retrived is 0, the username doesn't exist so create a new user
		if {$num_users == 0} {

			#insert new user
			set stmt [inf_prep_sql $DB $insert_new_user]
			inf_exec_stmt $stmt $username

			# get id of newly added user
			set stmt [inf_prep_sql $DB $get_users]
			set rs   [inf_exec_stmt $stmt $username]

			set user_id [db_get_col $rs 0 user_id]

			append json_pairs "\{\"id\":\"[db_get_col $rs 0 user_id]\","
			append json_pairs "\"username\":\"[db_get_col $rs 0 username]\"\}"

			# create the new user account associated with user
			set stmt [inf_prep_sql $DB $insert_new_user_account]
			set rs   [

			
			db_close $rs

		} else {

			append json_pairs "\{\"id\":\"[db_get_col $rs_users 0 user_id]\","
			append json_pairs "\"username\":\"[db_get_col $rs_users 0 username]\"\}"
			
		}
		
		tpBindString JSON $json_pairs

		puts "==================================================="
		puts "$json_pairs"
		puts "==================================================="

		inf_close_stmt $stmt
		db_close $rs_users

  		asPlayFile -nocache training/greedy_pig/login_json.html
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

		proc getUserAccount2 userId {
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

		getUserAccount2 $userId


	}

	proc getUserIdFromUsername {username} {
		global DB
		puts "$username INSIDE GETUSERIDFROMUSERNAME"
		

		set sql {
			select
				user_id
			from
				tUserKojolu
			where username = ?;
		}

		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			return
		}

		if {[catch {set rs [inf_exec_stmt $stmt $username]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			return
		}

		catch {inf_close_stmt $stmt}

		if {[db_get_nrows $rs]} {
			puts "==================== [db_get_col $rs 0 user_id]"
			set user_id [db_get_col $rs 0 user_id]
		}
		
		catch {db_close $rs}
		puts "====================INSIDE IF $user_id"
		return $user_id
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
		puts "INSIDE DEPOSIT ====================================================="
		set username [reqGetArg username]
		puts "$username ================== INSIDE DEPOSIT USERNAME"
		set amount [reqGetArg amount]
		set user_id [getUserIdFromUsername $username]

		puts "========================= $username $amount $user_id"

		updateUserDeposit $user_id $amount

	}
	
	proc go_game args {
		asPlayFile -nocache training/greedy_pig/index.html
	}
	
	proc go_pollGame args {
		set name [reqGetArg name]
		puts "hi $name"
	}

}
