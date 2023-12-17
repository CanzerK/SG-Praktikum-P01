using Godot;
using System;

public partial class DeviceManager : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		if (!Engine.HasSingleton("GodotShare")) return;
		
		var singleton = Engine.GetSingleton("GodotShare");
		// var result = singleton.function_demo(101) as Int32?;
		// GD.Print(new String(result));

		// singleton.FindDevices();
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}
