#import "GodotSphero.h"

#include "SpheroManager.h"
#include <core/config/engine.h>

SpheroManager* plugin = nullptr;

void godot_sphero_init()
{
	plugin = memnew(SpheroManager);
	Engine::get_singleton()->add_singleton(Engine::Singleton("Sphero", plugin));
}

void godot_sphero_deinit()
{
	if (plugin)
	{
		memdelete(plugin);
	}
}
