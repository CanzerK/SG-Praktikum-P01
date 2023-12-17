#ifndef SpheroManager_h
#define SpheroManager_h

#include <swift/bridging>

#import <CoreBluetooth/CoreBluetooth.h>
#import <SpheroBOLT-Swift.h>

#include <core/version.h>
#include <core/object/class_db.h>

@interface SpheroManagerImpl : NSObject <DeviceCoordinatorDelegate, DeviceDelegate>

@property (nonatomic, strong) DeviceCoordinator* _Nonnull deviceCoordinator;
@property (nonatomic, strong) NSMutableArray* _Nonnull connectedDevices;

- (instancetype _Nullable)init;

- (void)findDevices;
- (void)stop;

- (void)deviceCoordinatorDidUpdateBluetoothState:(DeviceCoordinator * _Nonnull)deviceCoordinator state:(CBManagerState)state;
- (void)deviceCoordinatorDidFindDevice:(DeviceCoordinator * _Nonnull)coordinator device:(Device * _Nonnull)device;
- (void)deviceCoordinatorDidDisconnectDevice:(DeviceCoordinator * _Nonnull)coordinator device:(Device * _Nonnull)device;

- (void)deviceDidChangeState:(Device * _Nonnull)device;
- (void)deviceDidUpdateConnectionState:(Device * _Nonnull)device state:(enum ConnectionState)state;
- (void)deviceDidFailConnectionState:(Device * _Nonnull)device error:(NSError * _Nullable)error;
- (void)deviceDidWake:(Device * _Nonnull)device;
- (void)deviceDidSleep:(Device * _Nonnull)device;

@end

class SpheroManager : public Object
{
	GDCLASS(SpheroManager, Object);

	static SpheroManager* _instance;
	static void _bind_methods();

public:
	static SpheroManager* get_singleton();

	SpheroManager();
	~SpheroManager();

	void findDevices();

	void stop();

private:
	SpheroManagerImpl* _manager = nullptr;
};

#endif /* SpheroManager_h */
