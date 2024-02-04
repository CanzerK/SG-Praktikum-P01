#import <Foundation/Foundation.h>

template <typename T>
class ObjCPtr
{
public:
	ObjCPtr() = default;
	ObjCPtr(T* object)
		: _object(object)
	{
		[_object retain];
	}

	ObjCPtr(const ObjCPtr& other) = default;
	ObjCPtr& operator=(const ObjCPtr& other) = default;
	ObjCPtr(ObjCPtr&& other) = default;
	ObjCPtr& operator=(ObjCPtr&& other) = default;

	virtual ~ObjCPtr()
	{
		[_object release];
	}

	T* get() const
	{
		return _object;
	}

private:
	T* _object = nullptr;
};
