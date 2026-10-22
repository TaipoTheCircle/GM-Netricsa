Nouveau CNP (CNP provisoire)


CLASSE:      Nouveau CNP (CNP provisoire)
MÉTABOLISME: ???
PERCEPTION: Modèle / PNC de base
TAILLE:       5,9 pieds
ENDURANCE:  Très faible
HOSTILITÉ:  Neutre / Aucun
ARMES:    Aucune =
RÉCOMPENSE:     1 FC
MENACE:     Très faible

DESCRIPTION:

Nouveau Npc est un modèle NPC inclus dans le SDK source-essentiellement un squelette ou un porte-place pour les modders pour construire de nouveaux caractères AI à partir.

À lui seul, il a une fonctionnalité très minimale: une référence de modèle fictif (=models/mymodel.mdl=) qui se traduit souvent par un modèle d'erreur si elle n'est pas remplacée.

Il hérite des capacités NPC de base (mouvement, vue, etc.) via la hiérarchie de classe CAI BaseNPC → CBaseCombatCharacter → etc.

Les drapeaux et les comportements peuvent être personnalisés via des valeurs clés (p. ex. relations, nom d'équipe, rayon de réveil) pour créer des types NPC plus avancés.

Dans le code, New Npc est utilisé comme point de départ: modders copie npc newnpc code (dans npc new.cpp) et remplace les noms de classe, les chemins de modèle, les tâches, les horaires, etc. pour faire un NPC entièrement fonctionnel.


CONSEILS:

- Utilisez New Npc comme fondation lors de la conception de nouveaux NPC personnalisés.
