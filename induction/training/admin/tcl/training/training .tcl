namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig         [namespace code go_greedy_pig]

 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}
}
