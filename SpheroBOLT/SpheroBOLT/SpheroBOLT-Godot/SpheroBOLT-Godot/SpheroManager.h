#pragma once

#include <swift/bridging>

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreGraphics/CoreGraphics.h>
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
- (void)ping;
- (void)sleep;
- (void)wait:(float)duration;
- (void)driveWithHeading:(uint8_t)speed
				 heading:(uint16_t)heading
			   direction:(Direction)direction
				duration:(float)duration
				 driveId:(int)driveId;
- (void)setAllLEDColorsFront:(_Nonnull CGColorRef)front
					 andBack:(_Nonnull CGColorRef)back;
- (void)setMainLEDColor:(_Nonnull CGColorRef)color;
- (void)setBackLEDColor:(_Nonnull CGColorRef)color;

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

	void try_connect();
	void wake();
	void sleep();
	void ping();
	void wait(const float duration);
	void drive(const uint8_t speed,
			   const uint16_t heading,
			   const int direction,
			   const float duration,
			   const int drive_id);
	void set_all_colors(const Color front, const Color back);
	void set_main_color(const Color color);
	void set_back_color(const Color color);

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
