#include "GodotSphero.h"
#include "SpheroManager.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <platform/ios/app_delegate.h>

@interface SpheroManagerImpl() <DeviceCoordinatorDelegate, DeviceDelegate>

@property (nonatomic, strong) DeviceCoordinator* _Nonnull deviceCoordinator;
@property (nonatomic, strong) NSMutableArray* _Nonnull connectedDevices;

@property (atomic, unsafe_unretained, assign) SpheroManager* _Nonnull godotManager;

- (void)deviceCoordinatorDidUpdateBluetoothState:(DeviceCoordinator * _Nonnull)deviceCoordinator state:(CBManagerState)state;
- (void)deviceCoordinatorDidFindDevice:(DeviceCoordinator * _Nonnull)coordinator device:(Device * _Nonnull)device;
- (void)deviceCoordinatorDidDisconnectDevice:(DeviceCoordinator * _Nonnull)coordinator device:(Device * _Nonnull)device;

- (void)deviceDidChangeState:(Device * _Nonnull)device;
- (void)deviceDidUpdateConnectionState:(Device * _Nonnull)device state:(enum ConnectionState)state;
- (void)deviceDidFailConnectionState:(Device * _Nonnull)device error:(NSError * _Nullable)error;
- (void)deviceDidWake:(Device * _Nonnull)device;
- (void)deviceDidSleep:(Device * _Nonnull)device;

@end

@implementation SpheroManagerImpl

- (instancetype)init
{
	if (self = [super init])
	{
		self.deviceCoordinator = [DeviceCoordinator new];
		self.deviceCoordinator.delegate = self;

		self.connectedDevices = [NSMutableArray new];
	}

	return self;
}

- (void)dealloc
{
	_godotManager = nullptr;
}

- (void)findDevices
{
	[_deviceCoordinator findDevices];
}

- (void)stop
{
	[_deviceCoordinator stop];
}

- (NSArray *)getConnectedDevices
{
	return [NSArray arrayWithArray:_connectedDevices];
}

- (void)deviceCoordinatorDidUpdateBluetoothState:(DeviceCoordinator * _Nonnull)deviceCoordinator
										   state:(CBManagerState)state
{
//	NSLog(@"%ld", (long)state);

	_godotManager->emit_signal("managerStateUpdated", Variant((int)state));
}

- (void)deviceCoordinatorDidFindDevice:(DeviceCoordinator * _Nonnull)coordinator
								device:(Device * _Nonnull)device
{
	NSLog(@"%@", device.name);

//	device.delegate = self;
//	[coordinator connectToDevice:device];
}

- (void)deviceCoordinatorDidDisconnectDevice:(DeviceCoordinator * _Nonnull)coordinator
									  device:(Device * _Nonnull)device
{
	NSLog(@"%@", device.name);
}

- (void)deviceDidFailConnectionState:(Device * _Nonnull)device error:(NSError * _Nullable)error
{

}

- (void)deviceDidSleep:(Device * _Nonnull)device
{
	
}

- (void)deviceDidUpdateConnectionState:(Device * _Nonnull)device state:(enum ConnectionState)state 
{

}

- (void)deviceDidWake:(Device * _Nonnull)device 
{

}

- (void)deviceDidChangeState:(Device * _Nonnull)device 
{

}

@end

SpheroManager* SpheroManager::_instance = nullptr;

SpheroManager::SpheroManager()
{
	ERR_FAIL_COND(_instance != NULL);

	_instance = this;
	_manager = [SpheroManagerImpl new];
	_manager.godotManager = this;
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
	ClassDB::bind_method(D_METHOD("findDevices"), &SpheroManager::findDevices);
	ClassDB::bind_method(D_METHOD("stop"), &SpheroManager::stop);

//	ClassDB::bind_method(D_METHOD("function_demo", "i"), &SpheroManager::function_demo);
//	ClassDB::bind_method(D_METHOD("signal_demo", "s"), &SpheroManager::signal_demo);
//	ClassDB::bind_method(D_METHOD("share_video_web", "url"), &SpheroManager::share_video_web);

	ADD_SIGNAL(MethodInfo("managerStateUpdated", PropertyInfo(Variant::OBJECT, "device")));
//	ADD_SIGNAL(MethodInfo("signal_demo_complete", PropertyInfo(Variant::INT, "i"), PropertyInfo(Variant::STRING, "s")));
}

void SpheroManager::findDevices()
{
	[_manager findDevices];
}

void SpheroManager::stop()
{
	[_manager stop];
}

Array SpheroManager::getConnectedDevices() const
{
	NSArray* connectedDevices = [_manager getConnectedDevices];

	Array result;
	result.resize(static_cast<int>(connectedDevices.count));

	for (const Device* device : connectedDevices)
	{
		result.push_back(Variant(device));
	}

	return result;
}

//int SpheroManager::function_demo(int i)
//{
//	return [SwiftClass function_demo:i];
//}
//
//void SpheroManager::signal_demo(String s)
//{
//	NSString *ns = [NSString stringWithCString:s.utf8().get_data() encoding:NSUTF8StringEncoding];
//	String ss = [ns UTF8String];
//	emit_signal("signal_demo_complete", 1022, ss);
//}
//
//void SpheroManager::share_img(String path)
//{
//	NSString *imagePath = [NSString stringWithCString:path.utf8().get_data() encoding:NSUTF8StringEncoding];
//	[SwiftClass share_img:imagePath];
//}
//
//void SpheroManager::share_img_web(String url)
//{
//	NSString *imageUrl = [NSString stringWithCString:url.utf8().get_data() encoding:NSUTF8StringEncoding];
//	[SwiftClass share_img_web:imageUrl];
//}
//
//void SpheroManager::share_video_web(String url)
//{
//	NSString *videoUrl = [NSString stringWithCString:url.utf8().get_data() encoding:NSUTF8StringEncoding];
//	[SwiftClass share_video_web:videoUrl];
//}
