#ifndef SpheroManager_h
#define SpheroManager_h

#include <swift/bridging>

#import <CoreBluetooth/CoreBluetooth.h>
#import <SpheroBOLT-Swift.h>

#include <core/version.h>
#include <core/object/class_db.h>

class SpheroManager;

@interface SpheroManagerImpl : NSObject

- (instancetype _Nullable)init;
- (void)dealloc;

- (void)findDevices;
- (void)stop;
- (NSArray *_Nonnull)getConnectedDevices;

@end

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

	void findDevices();

	void stop();

	Array getConnectedDevices() const;

private:
	SpheroManagerImpl* _Nullable _manager = nullptr;
};

#endif /* SpheroManager_h */
