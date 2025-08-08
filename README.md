# godot-multiplayerspawner-research
A documentation and tests to explain multiplayer spawner.

MultiplayerSpawner  `Spawn_Path`  is a node that will be used as position to relatively spawn on.
MultiplayerSpawner  `Auto_Spawn_List`  are the Spawn_Path nodes that are allowed to `spawn()`.

To reduce confusion, the word `Path` in the  `Spawn_Path` means a scene node path.
Better name for this variable would have been `Spawn_Node_Path` or `Spawner_Node_Path`,  
because it's really about selecting the node that will be used for spawning a entity.


`Spawn_Path` is a spawnpoint.
Auto_Spawn_List  is a whitelist that will trigger


To reduce confusion, the word `Path` in the  `Spawn_Path` means a node path.
Better name for this variable would have been `Spawn_Node_Path` or `Spawner_Node_Path`,  
because it's really about selecting the node that will be used for spawning a entity.

------------



MultiplayerSpawner  `Spawn_Path`  is a node that will be used as position to relatively spawn on.
MultiplayerSpawner  `Auto_Spawn_List`  are the Spawn_Path nodes that are allowed to `spawn()`.

There are no default spawning processes.
The spawning process have to be created manually through scripting.
Auto_Spawn_List are the list of entities scenes to be spawned.

Once you instatiate these scenes from Auto_Spawn_List, they are replicated and spawned.
Auto_Spawn_List is basicly marking for replication.
After replication you need a synchronizer to synchronize position or other attributes.

The regular setup is 

Common issue: 
Server instance appears with testdot in the corner of container.
And client instance appears with testdot  in the middle of container.

This is what MultplayerSynchronizer is used: to synchronize.
Add property to replicate: `.:position`
