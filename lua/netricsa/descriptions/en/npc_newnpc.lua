NEW NPC (Template NPC)


CLASS:      Template / Base NPC
METABOLISM: Synthetic (template entity, no real biology)
PERCEPTION: Basic (stubbed AI)
SIZE:       Human scale (~5.8–6 ft model)
ENDURANCE:  Very Low (default, minimal health)
HOSTILITY:  Neutral / None (does not attack by default)
WEAPONS:    None (no offensive behavior by default)
REWARD:     1 FC
THREAT:     Very Low

DESCRIPTION:

New Npc is a template NPC included in the Source SDK-essentially a skeleton or placeholder for modders to build new AI characters from. 

On its own, it has very minimal functionality: a dummy model reference (“models/mymodel.mdl”) that often results in an “error” model if not replaced. 

It inherits base NPC capabilities (movement, sight, etc.) via the class hierarchy CAI_BaseNPC → CBaseCombatCharacter → etc. 

Flags and behaviors can be customized via keyvalues (e.g. relationships, squad name, wake radius) to create more advanced NPC types. 

In code, New Npc is used as a starting point: modders copy npc_newnpc code (in npc_new.cpp) and replace class names, model paths, tasks, schedules, etc. to make a fully functional NPC. 


TIPS:

- Use New Npc as a foundation when designing new custom NPCs.