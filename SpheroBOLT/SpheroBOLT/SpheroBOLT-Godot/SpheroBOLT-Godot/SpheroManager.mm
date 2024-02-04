#include "GodotSphero.h"
#include "SpheroManager.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <platform/ios/app_delegate.h>

@interface SpheroManagerImpl() <DeviceCoordinatorDelegate>

@property (nonatomic, strong) DeviceCoordinator* _Nonnull deviceCoordinator;

@property (atomic, unsafe_unretained, assign) SpheroManager* _Nonnull godotManager;

- (void)deviceCoordinatorDidUpdateBluetoothState:(DeviceCoordinator * _Nonnull)deviceCoordinator
										   state:(CBManagerState)state;
- (void)deviceCoordinatorDidFindDevice:(DeviceCoordinator * _Nonnull)coordinator 
								device:(Device * _Nonnull)device;
- (void)deviceCoordinatorDidDisconnectDevice:(DeviceCoordinator * _Nonnull)coordinator 
									  device:(Device * _Nonnull)device;

@end

@implementation SpheroManagerImpl

- (instancetype)init
{
	if (self = [super init])
	{
		self.deviceCoordinator = [DeviceCoordinator new];
		self.deviceCoordinator.delegate = self;
	}

	return self;
}

- (void)dealloc
{
	_godotManager = nullptr;

	[super dealloc];
}

- (CBManagerState)state
{
	return _deviceCoordinator.state;
}

- (void)findDevices
{
	[_deviceCoordinator findDevices];
}

- (void)stop
{
	[_deviceCoordinator stop];
}

- (void)deviceCoordinatorDidUpdateBluetoothState:(DeviceCoordinator * _Nonnull)deviceCoordinator
										   state:(CBManagerState)state
{
	_godotManager->emit_signal("manager_state_updated", Variant((int)state));
}

- (void)deviceCoordinatorDidFindDevice:(DeviceCoordinator * _Nonnull)coordinator
								device:(Device * _Nonnull)device
{
	Ref<SpheroDevice> spheroDevice(memnew(SpheroDevice));
	DeviceImpl* deviceImpl = [[DeviceImpl alloc] initWithCoordinator:coordinator 
															  device:device
													 spheroDevicePtr:spheroDevice];
	spheroDevice->set_device(deviceImpl);
	spheroDevice->set_manager(_godotManager);


	_godotManager->emit_signal("manager_did_find_device", Variant(spheroDevice));
}

- (void)deviceCoordinatorDidDisconnectDevice:(DeviceCoordinator * _Nonnull)coordinator
									  device:(Device * _Nonnull)device
{
	_godotManager->emit_signal("manager_did_disconnect_device", Variant(String(device.name.UTF8String)));
}

@end

@interface DeviceImpl() <DeviceDelegate>

@property (nonatomic, strong) DeviceCoordinator* _Nonnull deviceCoordinator;
@property (nonatomic, strong) Device* _Nonnull device;

@property (atomic, unsafe_unretained, assign) SpheroDevice* godotDevice;

- (void)deviceDidChangeState:(Device * _Nonnull)device;
- (void)deviceDidUpdateConnectionState:(Device * _Nonnull)device state:(enum ConnectionState)state;
- (void)deviceDidFailConnectionState:(Device * _Nonnull)device error:(NSError * _Nullable)error;
- (void)deviceDidWake:(Device * _Nonnull)device;
- (void)deviceDidSleep:(Device * _Nonnull)device;

@end

@implementation DeviceImpl

- (instancetype _Nullable)initWithCoordinator:(DeviceCoordinator * _Nonnull)coordinator
									   device:(Device * _Nonnull)device
							  spheroDevicePtr:(Ref<SpheroDevice>)devicePtr
{
	if (self = [super init])
	{
		self.deviceCoordinator = coordinator;
		self.device = device;
		self.godotDevice = devicePtr.ptr();
	}

	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString *)name
{
	return _device.name;
}

- (DeviceState)state
{
	return _device.state;
}

- (void)deviceDidFailConnectionState:(Device * _Nonnull)device error:(NSError * _Nullable)error
{
	_godotDevice->emit_signal("device_did_fail_connection", Variant(_godotDevice->get_name()));
}

- (void)deviceDidSleep:(Device * _Nonnull)device
{
	_godotDevice->emit_signal("device_did_sleep", Variant(_godotDevice->get_name()));
}

- (void)deviceDidUpdateConnectionState:(Device * _Nonnull)device state:(enum ConnectionState)state
{
	_godotDevice->emit_signal("device_did_update_connection_state", Variant(_godotDevice->get_name()), Variant((int)state));
}

- (void)deviceDidWake:(Device * _Nonnull)device
{
	_godotDevice->emit_signal("device_did_wake", Variant(_godotDevice->get_name()));
}

- (void)deviceDidChangeState:(Device * _Nonnull)device
{
	_godotDevice->emit_signal("device_did_change_state", Variant(device.name), Variant((int)_device.state));
}

- (void)connect
{
	self.device.delegate = self;
	[self.deviceCoordinator connectToDevice:self.device];
}

- (void)wake
{
	[self.device sendWakeCommand];
}

@end

SpheroDevice::~SpheroDevice()
{
	_device = nil;
}

void SpheroDevice::_bind_methods()
{
	ClassDB::bind_method(D_METHOD("attempt_connection"), &SpheroDevice::attempt_connection);
	ClassDB::bind_method(D_METHOD("wake"), &SpheroDevice::wake);
	ClassDB::bind_method(D_METHOD("get_name"), &SpheroDevice::get_name);

	ADD_SIGNAL(MethodInfo("device_did_fail_connection", PropertyInfo(Variant::STRING, "device_name")));
	ADD_SIGNAL(MethodInfo("device_did_sleep", PropertyInfo(Variant::OBJECT, "device_name")));
	ADD_SIGNAL(MethodInfo("device_did_update_connection_state", PropertyInfo(Variant::OBJECT, "device_name"), PropertyInfo(Variant::INT, "state")));
	ADD_SIGNAL(MethodInfo("device_did_wake", PropertyInfo(Variant::OBJECT, "device_name")));
	ADD_SIGNAL(MethodInfo("device_did_change_state", PropertyInfo(Variant::OBJECT, "device_name"), PropertyInfo(Variant::INT, "state")));
}

void SpheroDevice::set_device(DeviceImpl* _Nonnull new_device)
{
	_device = ObjCPtr(new_device);
}

void SpheroDevice::set_manager(SpheroManager* _Nonnull new_manager)
{
	_manager = new_manager;
}

void SpheroDevice::attempt_connection()
{
	[_device.get() connect];
}

void SpheroDevice::wake()
{
	[_device.get() wake];
}

String SpheroDevice::get_name()
{
	return String(_device.get().name.UTF8String);
}

SpheroManager* SpheroManager::_instance = nullptr;

SpheroManager::SpheroManager()
{
	ERR_FAIL_COND(_instance != NULL);

	_instance = this;
	_manager = ObjCPtr([SpheroManagerImpl new]);
	_manager.get().godotManager = this;
}

SpheroManager::~SpheroManager()
{
	_instance = nullptr;
	_manager = nil;
}

SpheroManager* SpheroManager::get_singleton()
{
	return _instance;
}

void SpheroManager::_bind_methods()
{
	ClassDB::bind_method(D_METHOD("get_state"), &SpheroManager::get_state);
	ClassDB::bind_method(D_METHOD("find_devices"), &SpheroManager::find_devices);
	ClassDB::bind_method(D_METHOD("stop"), &SpheroManager::stop);

	ADD_SIGNAL(MethodInfo("manager_state_updated", PropertyInfo(Variant::INT, "state")));
	ADD_SIGNAL(MethodInfo("manager_did_find_device", PropertyInfo(Variant::OBJECT, "device")));
	ADD_SIGNAL(MethodInfo("manager_did_disconnect_device", PropertyInfo(Variant::OBJECT, "device")));
}

Variant SpheroManager::get_state()
{
	return Variant(static_cast<int32_t>(_manager.get().state));
}

void SpheroManager::find_devices()
{
	[_manager.get() findDevices];
}

void SpheroManager::stop()
{
	[_manager.get() stop];
}
