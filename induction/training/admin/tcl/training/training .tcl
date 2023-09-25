namespace eval TRAINING {

	asSetAct KOJOLU_GreedyPig         [namespace code go_greedy_pig]
	asSetAct KOJOLU_lobby         [namespace code lobby]

 	proc go_greedy_pig args {
  			asPlayFile -nocache training/greedy_pig/login.html
	}

	 	proc lobby args {
  			asPlayFile -nocache training/greedy_pig/lobby.html
	}
}
