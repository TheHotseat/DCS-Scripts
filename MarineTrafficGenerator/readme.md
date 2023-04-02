**Marine Traffic Generator Readme**

The Marine Traffic Generator is a script that allows for the generation of ships based on real-world positions using trigger zones. This script supports circular and shaped zones and can spawn ships as static objects or AI units depending on the parameters included in the zone name.

**Usage**

To activate the Marine Traffic Generator, add the phrase "[MARINE_TRAFFIC:true]" to the name of the trigger zone. To specify whether the ships should be spawned as static objects or AI units, you can include the parameter "[MT_SPAWN_AS_STATIC:true]" in the zone name to spawn the ships as static objects, or omit the parameter or include "[MT_SPAWN_AS_STATIC:false]" to spawn the ships as AI units.

**Example**

An example trigger zone name that activates the Marine Traffic Generator script to spawn ships as static objects would be "[MARINE_TRAFFIC:true][MT_SPAWN_AS_STATIC:true]". An example trigger zone name that activates the script to spawn ships as AI units would be "[MARINE_TRAFFIC:true]".

**Notes**

Please note that to maintain acceptable performance, trigger zones should be kept small. Additionally, spawning the ships as static objects is less resource-intensive than spawning them as AI units.