namespace eval TRAINING {

	asSetAct TRAINING_GreedyPig             [namespace code go_greedy_pig]
	asSetAct TRAINING_DrillDown             [namespace code go_drill_down]
	asSetAct TRAINING_CustInfo              [namespace code go_cust_info]
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
	
	proc go_drill_down args {
		global DB
		
		set level [reqGetArg level]
		set id [reqGetArg id]
		
		tpSetVar parent_level $level
		tpSetVar id $id
		
		if {$level == ""} {
			# Category Page code
			global categories_array					
			set select_categories {
				select 
					category as id,
					name 
				from 
					tevcategory;
			}
			
			set stmt [inf_prep_sql $DB $select_categories]
			set rs   [inf_exec_stmt $stmt]
			
			inf_close_stmt $stmt

			set num_categories [db_get_nrows $rs]
			tpSetVar num_categories $num_categories
			
			for {set i 0} {$i < $num_categories} {incr i} {
				set categories_array($i,category_id) [db_get_col $rs $i id]
				set categories_array($i,name) [db_get_col $rs $i name]
			}
			
			db_close $rs
			
			tpBindVar CATEGORY_ID categories_array category_id category_idx
			tpBindVar NAME categories_array name category_idx
			# END --------------------------------------------
		} elseif {$level == "CATEGORIES"} {
			# Class Page code
			global classes_array					
			set select_classes {
				select 
					tevclass.ev_class_id as id, 
					tevclass.name 
				from 
					tevclass, 
					tevcategory
				where
					tevcategory.category = ? and
					tevcategory.category = tevclass.category;
			}
			
			set stmt [inf_prep_sql $DB $select_classes]
			set rs   [inf_exec_stmt $stmt $id]
			
			inf_close_stmt $stmt

			set num_classes [db_get_nrows $rs]
			tpSetVar num_classes $num_classes
			
			for {set i 0} {$i < $num_classes} {incr i} {
				set classes_array($i,class_id) [db_get_col $rs $i id]
				set classes_array($i,name) [db_get_col $rs $i name]
			}
			
			db_close $rs
			
			tpBindVar CLASS_ID classes_array class_id class_idx
			tpBindVar NAME classes_array name class_idx
			# END --------------------------------------------
		}

		
		
		set select_types {
			select 
				tevtype.ev_type_id as id,
				tevtype.name
			from 
				tevtype, 
				tevclass
				
			where
				tevtype.ev_class_id = ? and
				tevtype.ev_class_id = tevclass.ev_class_id 	
		}
		
		asPlayFile -nocache training/drilldown.html
		
		set select_events {
			select 
				tev.ev_id as id,
				tev.desc as name 
			from 
				tev,
				tevclass
			where
				tev.ev_class_id = ? and
				tev.ev_class_id = tevclass.ev_class_id	
		}	

		set select_markets {
			select 
				tevmkt.ev_mkt_id as id,
				tevmkt.name 
			from 
				tevmkt,
				tev
			where
				tev.ev_id = ? and
				tev.ev_id = tevmkt.ev_id	
		}	

		set select_outcomes {
			select 
				tevoc.ev_oc_id as id,
				tevoc.desc as nam
			from 
				tevtype
			where
				name = 	
		}		
		
	}
	
	proc go_cust_info args {
		global DB
		set cust_id [reqGetArg cust_id]			
		set loc [reqGetArg loc]
		
		set sql_after {
			select
				tcustomer.cust_id,
				tcustomer.bet_count,
				tcustomerreg.fname,
				tcustomerreg.lname
			from
				tcustomer, 
				tcustomerreg
			where
				tcustomer.cust_id = ? and
				tcustomer.cust_id = tcustomerreg.cust_id 
		}
		
		set stmt [inf_prep_sql $DB $sql_after]
		set rs   [inf_exec_stmt $stmt $cust_id]
		
		inf_close_stmt $stmt
		
		if {[db_get_nrows $rs] && $loc == "after"} {
			tpSetVar found_cust_details 1
		}		
		
		tpBindString CUST_ID $cust_id
		tpBindString CUST_BET [db_get_col $rs 0 bet_count]
		tpBindString CUST_FNAME [db_get_col $rs 0 fname]
		tpBindString CUST_LNAME  [db_get_col $rs 0 lname]
	
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
		
		tpSetVar display_hrz_line 1
		
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
