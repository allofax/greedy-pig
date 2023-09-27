namespace eval TRAINING {

	asSetAct KOJOLU_greedy_pig		[namespace code go_greedy_pig]
	asSetAct TRAINING_go_Lukas_ex1		[namespace code go_Lukas_ex1]
	asSetAct TRAINING_go_drilldown		[namespace code go_drilldown]
	asSetAct TRAINING_PlayPage              [namespace code go_play_page]
	asSetAct TRAINING_PlayPageIncl          [namespace code go_play_page_incl]
	asSetAct TRAINING_tpBindString          [namespace code go_tpBindString]
	asSetAct TRAINING_tpSetVar              [namespace code go_tpSetVar]
	asSetAct TRAINING_ifelse                [namespace code go_ifelse]
	asSetAct TRAINING_loop                  [namespace code go_loop]
	asSetAct TRAINING_dbvalues              [namespace code go_dbvalues]
	asSetAct TRAINING_dbcriteria            [namespace code go_dbcriteria]
	asSetAct TRAINING_go_reqGetArg          [namespace code go_reqGetArg]
	asSetAct TRAINING_do_reqGetArg          [namespace code do_reqGetArg]
	asSetAct TRAINING_go_catch              [namespace code go_catch]
	asSetAct TRAINING_do_catch              [namespace code do_catch]
	asSetAct TRAINING_get_details           [namespace code get_details]
	
	proc go_greedy_pig args {
		asPlayFile -nocache training/greedy_pig/login.html
	}
	
	proc go_drilldown args {
		# load categories from sql
		# then for loop it
		# two vars: where u are/going (level), the ID of the parent
		# 'hardcode' the levels of the category
		# regGetArg, if empty string then it means its in category
		# cat -> parent id = id
		
		global DB
		global MEMBERS
		
		set level [reqGetArg lev]
		
		# category
		if {$level == ""} {
			set sql {
				SELECT
					name,
					category as id
				FROM
					tevcategory;
			}
			
		}
		
		set parent [reqGetArg parent]
		
		# class
		if {$level == "class"} {
			set sql {
				SELECT
					name,
					category as id
				FROM
					tevclass
				WHERE
					tevclass.id = ?;
			}
		}
		
				
		set stmt [inf_prep_sql $DB $sql]
		set rs [inf_exec_stmt $stmt]
		
		inf_close_stmt $stmt
		
		set num_level_members [db_get_nrows $rs]
		tpSetVar num_level_members $num_level_members

		
		for {set i 0} {$i < $num_level_members} {incr i} {
			set MEMBERS($i,name)    [db_get_col $rs $i name]
			set MEMBERS($i,id) [db_get_col $rs $i id]
		}
		
		db_close $rs
			
		tpBindVar MEMBERS_NAME MEMBERS name memb_idx
		tpBindVar MEMBERS_ID MEMBERS id memb_idx
	
		asPlayFile -nocache training/drilldown.html
	}
	
	proc go_Lukas_ex1 args {
		global DB
		set cust_id [reqGetArg cust_id]
		
		set sql {
			SELECT
				tcustomerreg.fname as fname,
				tcustomerreg.lname as lname,
				tcustomer.bet_count as bet_count
			FROM
				tcustomerreg
			INNER JOIN
				tcustomer ON tcustomerreg.cust_id=tcustomer.cust_id
			WHERE
				tcustomer.cust_id = ?
			
		}
		
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			asPlayFile -nocache training/catch.html
			return
		}
		
		if {[catch {set rs [inf_exec_stmt $stmt $cust_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			asPlayFile -nocache training/catch.html
			return
		}
		
		catch {inf_close_stmt $stmt}
		
		if {[db_get_nrows $rs]} {
			tpSetVar found_cust_details 1
			tpBindString CUST_FNAME   [db_get_col $rs 0 fname]
			tpBindString CUST_LNAME [db_get_col $rs 0 lname]
			tpBindString CUST_BET_COUNT  [db_get_col $rs 0 bet_count]
		}
		
		set found_cust_details 1
		
		do_catch
	}

	proc go_play_page args {
		asPlayFile -nocache training/page.html
	}

	proc go_play_page_incl args {
		asPlayFile -nocache training/page-incl.html
	}

	proc go_tpBindString args {
		global USERNAME
		
		tpBindString username MY_NEW_NAME
		asPlayFile -nocache training/tpBindString.html
	}
	

	proc go_tpSetVar args {
		global USERNAME
		tpBindString username $USERNAME
		
		tpSetVar show_username 1

		asPlayFile -nocache training/tpSetVar.html
	}

	proc go_ifelse args {
		global USERNAME
		
		tpBindString username $USERNAME
		
		tpSetVar show_username 1
		
		tpSetVar display_hrz_line 0
		
		asPlayFile -nocache training/if-else.html
	}

	proc go_loop args {
		global PEOPLE
		
		set PEOPLE(0,name) "John"
		set PEOPLE(1,name) "Tom"
		set PEOPLE(2,name) "Will"
        set PEOPLE(0,age) 23
        set PEOPLE(1,age) 34
        set PEOPLE(2,age) 44
		
		
		tpSetVar num_people 3
		

		tpBindVar THE_NAME PEOPLE name people_idx
        tpBindVar THE_AGE  PEOPLE age  people_idx
		
		asPlayFile -nocache training/loop.html
	}

	proc go_dbvalues args {
		global DB
		global CUST
		
		set sql {
			select first 10
				username,
				password
			from
				tcustomer
		}
		
		set stmt [inf_prep_sql $DB $sql]
		set rs   [inf_exec_stmt $stmt]
		
		inf_close_stmt $stmt
		
		set num_custs [db_get_nrows $rs]
		tpSetVar num_custs $num_custs
		
		for {set i 0} {$i < $num_custs} {incr i} {
			set CUST($i,uname) [db_get_col $rs $i username]
			set CUST($i,pwrd)  [db_get_col $rs $i password]
		}
		
		db_close $rs
		
		tpBindVar CUST_UNAME CUST uname cust_idx
		tpBindVar CUST_PWRD  CUST pwrd  cust_idx
		
		asPlayFile -nocache training/dbvalues.html
	}

	proc go_dbcriteria args {
		global DB
		global CUST
		
		set sql {
			select
				cust_id,
				username,
				password
			from
				tcustomer
			where
				cust_id >= ? and
				cust_id <= ?
		}
		
		set low_cust_id  3
		set high_cust_id 9
		
		set stmt [inf_prep_sql $DB $sql]
		set rs   [inf_exec_stmt $stmt $low_cust_id  $high_cust_id]
		
		inf_close_stmt $stmt
		
		set num_custs [db_get_nrows $rs]
		tpSetVar num_custs $num_custs
		
		for {set i 0} {$i < $num_custs} {incr i} {
			set CUST($i,id)    [db_get_col $rs $i cust_id]
			set CUST($i,uname) [db_get_col $rs $i username]
			set CUST($i,pwrd)  [db_get_col $rs $i password]
		}
		
		db_close $rs
		
		tpBindVar CUST_ID    CUST id    cust_idx
		tpBindVar CUST_UNAME CUST uname cust_idx
		tpBindVar CUST_PWRD  CUST pwrd  cust_idx
		
		asPlayFile -nocache training/dbcriteria.html
	}
	
	proc go_reqGetArg args {
		
		asPlayFile -nocache training/reqGetArg.html
	}

	proc do_reqGetArg {} {
		global DB
		
		set cust_id [reqGetArg cust_id]
		
		set sql {
			select
				username,
				password
			from
				tcustomer
			where
				cust_id = ?
		}
		
		set stmt [inf_prep_sql $DB $sql]
		set rs   [inf_exec_stmt $stmt $cust_id]
		
		inf_close_stmt $stmt
		
		if {[db_get_nrows $rs]} {
			tpSetVar found_cust 1
		}
		
		tpBindString CUST_ID    $cust_id
		tpBindString CUST_UNAME [db_get_col $rs 0 username]
		tpBindString CUST_PWRD  [db_get_col $rs 0 password]
		
		db_close $rs
		
		asPlayFile -nocache training/reqGetArg.html
	}
	
	proc go_catch args {
		
		asPlayFile -nocache training/catch.html
	}

	proc do_catch {} {
		global DB
		
		set cust_id [reqGetArg cust_id]
		
		set sql {
			select first 10
				cust_id,
				username,
				password
			from
				tcustomer
			where
				cust_id = ?
		}
		
		if {[catch {set stmt [inf_prep_sql $DB $sql]} msg]} {
			tpBindString err_msg "error occured while preparing statement"
			ob::log::write ERROR {===>error: $msg}
			tpSetVar err 1
			asPlayFile -nocache training/catch.html
			return
		}
		
		if {[catch {set rs [inf_exec_stmt $stmt $cust_id]} msg]} {
			tpBindString err_msg "error occured while executing query"
			ob::log::write ERROR {===>error: $msg}
            catch {inf_close_stmt $stmt}
			tpSetVar err 1
			asPlayFile -nocache training/catch.html
			return
		}
		
		catch {inf_close_stmt $stmt}
		
		if {[db_get_nrows $rs]} {
			tpSetVar found_cust 1
			tpBindString CUST_ID    [db_get_col $rs 0 cust_id]
			tpBindString CUST_UNAME [db_get_col $rs 0 username]
			tpBindString CUST_PWRD  [db_get_col $rs 0 password]
		}
		
		
		
		
		catch {db_close $rs}
		
		asPlayFile -nocache training/catch.html
	}
	
	
	proc go_play_page_new args {
		
		core::view::add_header \
			-name  "Content-Type" \
			-value "text/html;"
		
		core::view::play -filename training/page.html
	}
	
	proc go_tpBindString_new args {
		global USERNAME
		
		tpBindString username $USERNAME
		
		core::view::add_header \
			-name  "Content-Type" \
			-value "text/html;"
		
		core::view::play -filename training/tpBindString.html
	}
	
	
	proc go_reqGetArg_new args {
		
		core::view::add_header \
			-name  "Content-Type" \
			-value "text/html;"
		
		core::view::play -filename training/reqGetArgNew.html
	}

	proc do_reqGetArg_new {} {
		global DB
		
		set cust_id [reqGetArg cust_id]
		
		set sql {
			select
				username,
				password
			from
				tcustomer
			where
				cust_id = ?
		}
		
		set stmt [inf_prep_sql $DB $sql]
		set rs   [inf_exec_stmt $stmt $cust_id]
		
		inf_close_stmt $stmt
		
		if {[db_get_nrows $rs]} {
			tpSetVar found_cust 1
		}
		
		tpBindString CUST_ID    $cust_id
		tpBindString CUST_UNAME [db_get_col $rs 0 username]
		tpBindString CUST_PWRD  [db_get_col $rs 0 password]
		
		db_close $rs
		
		core::view::add_header \
			-name  "Content-Type" \
			-value "text/html;"
		
		core::view::play -filename training/reqGetArgNew.html
	}
}
