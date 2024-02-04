#pragma once

#include <swift/bridging>

#import <CoreBluetooth/CoreBluetooth.h>
#import <SpheroBOLT-Swift.h>
#import "ObjCPtr.mm"

#include <core/version.h>
#include <core/object/class_db.h>
#include <core/object/ref_counted.h>

class SpheroManager;

@interface SpheroManagerImpl : NSObject

@property (nonatomic, readonly) CBManagerState state;

- (instancetype _Nullable)init;
- (void)dealloc;

- (void)findDevices;
- (void)stop;

@end

@interface DeviceImpl : NSObject

@property (nonatomic, readonly) NSString* _Nonnull name;
@property (nonatomic, readonly) DeviceState state;

- (instancetype _Nullable)initWithCoordinator:(DeviceCoordinator *_Nonnull)coordinator
									   device:(Device * _Nonnull)device
							  spheroDevicePtr:(Ref<class SpheroDevice>)devicePtr;
- (void)dealloc;

- (void)connect;
- (void)wake;

@end

class SpheroDevice : public RefCounted
{
	NS_ASSUME_NONNULL_BEGIN
	GDCLASS(SpheroDevice, Object);
	NS_ASSUME_NONNULL_END

	static void _bind_methods();

public:
	SpheroDevice() = default;
	~SpheroDevice();

	void attempt_connection();
	void wake();
	String get_name();

public:
	void set_device(DeviceImpl* _Nonnull new_device);
	void set_manager(SpheroManager* _Nonnull new_manager);

private:
	ObjCPtr<DeviceImpl> _device;
	SpheroManager* _Nullable _manager = nullptr;
};

class SpheroManager : public Object
{
	NS_ASSUME_NONNULL_BEGIN
	GDCLASS(SpheroManager, Object);
	NS_ASSUME_NONNULL_END

	static SpheroManager* _Nonnull _instance;
	static void _bind_methods();

public:
	static SpheroManager* _Nonnull get_singleton();

	SpheroManager();
	~SpheroManager();

	Variant get_state();
	void find_devices();
	void stop();

private:
	ObjCPtr<SpheroManagerImpl> _manager;
};
