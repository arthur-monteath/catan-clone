@abstract
class_name ActionCardAction extends Resource

# enum ActionCardAction {
	#StealFromAll,
	#StealFromPlayer,
	#GetVictoryPoints,
	#GetSecretVictoryPoints,
	#GetResourceChoice,
	#GetResource
#}

@abstract
func Run(players: Dictionary) -> void
