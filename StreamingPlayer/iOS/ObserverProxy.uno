using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

[Require("Source.Include", "Foundation/Foundation.h")]
[Require("Source.Include", "iOS/ObserverProxy.h")]
extern(iOS) public static class ObserverProxy
{
	static ObjC.Object _proxy;

	static ObserverProxy()
	{
		_proxy = Create(OnCallback);
	}

	static Dictionary<string, Action> _observers = 
		new Dictionary<string, Action>();

	static void OnCallback(string keyPath)
	{
		if (_observers.ContainsKey(keyPath))
			_observers[keyPath]();
	}

	public static void AddObserver(ObjC.Object target, string keyPath, int options, Action callback)
	{
		AddObserver(_proxy, target, keyPath, options);
		_observers.Add(keyPath, callback);
	}

	public static void RemoveObserver(ObjC.Object target, string keyPath)
	{
		_observers.Remove(keyPath);
		RemoveObserver(_proxy, target, keyPath);
	}

	[Foreign(Language.ObjC)]
	static void RemoveObserver(ObjC.Object proxy, ObjC.Object target, string kp)
	@{
		NSObject* p = (NSObject*)proxy;
		NSObject* t = (NSObject*)target;
		[t removeObserver:p forKeyPath:kp];
	@}

	[Foreign(Language.ObjC)]
	static void AddObserver(ObjC.Object proxy, ObjC.Object target, string kp, int o)
	@{
		NSObject* p = (NSObject*)proxy;
		NSObject* t = (NSObject*)target;
		[t addObserver:p forKeyPath:kp options:o context:nil];
	@}

	[Foreign(Language.ObjC)]
	static ObjC.Object Create(Action<string> callback)
	@{
		ObserverProxyImpl* obs = [[ObserverProxyImpl alloc] init];
		[obs setCallback: callback];
		return obs;
	@}

}
