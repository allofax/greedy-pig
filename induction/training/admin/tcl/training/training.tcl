package require json

namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig     [namespace code go_greedy_pig]
	asSetAct KOJOLU_lobby         [namespace code lobby]
	asSetAct KOJOLU_login_JSON    [namespace code go_login_JSON]


 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}

	proc lobby args {
  			asPlayFile -nocache training/greedy_pig/lobby.html
	}

	proc go_login_JSON args {
		global DB

		# get username from request URL sent from frontend login.js
		set username [reqGetArg username]

		# statement used to insert a new user if the username entered doesn't already exist
		set insert_new_user {
			insert into 
				tUSerKojolu (username)
			values
				(?)
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

			append json_pairs "\{\"id\":\"[db_get_col $rs 0 user_id]\","
			append json_pairs "\"username\":\"[db_get_col $rs 0 username]\"\}"
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
}
