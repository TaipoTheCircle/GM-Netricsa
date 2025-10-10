BULLSEYE 


CLASS:      Target Proxy / Redirect Entity
METABOLISM: Scripted entity
PERCEPTION: Linkable tracing system
SIZE:       ~1 ft (small sphere)
ENDURANCE:  Low (fragile)
HOSTILITY:  Neutral (non-offensive)
WEAPONS:    None (redirects attacks)
REWARD:     1 FC
THREAT:     Very Low

DESCRIPTION:

Bullseye is a special scripted entity used internally by the engine (and map makers) to redirect damage. Essentially, it is a target proxy: anything that is linked to Bullseye will have its damage or fireray redirected to Bullseye’s position. For example, you can place a Bullseye invisible in a room, link NPC models to it, and make attacks aimed at those NPCs hit at Bullseye's true location instead.

In gameplay terms, Bullseye is invisible and intangible; it doesn’t fight or react. Its role is purely technical — used in maps to enable “shoot through walls” or redirect attacks for puzzles, traps, or scripted events.

TIPS:

- Understanding Bullseye lets mappers produce teleporting bullets, glass-walls, or remote triggers.