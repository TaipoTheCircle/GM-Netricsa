NOUVEAU PNJ (PNJ modèle)


CLASS: Nouveau PNJ (PNJ modèle)
METABOLISM: None
PERCEPTION: Modèle / PNJ de base
SIZE: 5,9 pieds
ENDURANCE: Très faible
HOSTILITY: Neutre / Aucun
WEAPONS: Aucun=
REWARD: 1 FC
THREAT: Très faible

DESCRIPTION: 

New Npc est un modèle de PNJ inclus dans le SDK Source, essentiellement un squelette ou un espace réservé permettant aux moddeurs de créer de nouveaux personnages IA.

On its own, it has very minimal functionality: une référence de modèle factice (« models/mymodel.mdl ») qui entraîne souvent un modèle « d'erreur » s'il n'est pas remplacé.

Il hérite des capacités de base des PNJ (déplacement, vue, etc.) via la hiérarchie de classes CAI_BaseNPC → CBaseCombatCharacter → etc.

Les drapeaux et les comportements peuvent être personnalisés via des valeurs clés (par exemple, relations, nom d'équipe, rayon de sillage) pour créer des types de PNJ plus avancés.

In code, New Npc is used as a starting point: les moddeurs copient le code npc_newnpc (dans npc_new.cpp) et remplacent les noms de classe, les chemins de modèle, les tâches, les horaires, etc. pour créer un PNJ entièrement fonctionnel.


TIPS: 

- Utilisez New Npc comme base lors de la conception de nouveaux PNJ personnalisés.
