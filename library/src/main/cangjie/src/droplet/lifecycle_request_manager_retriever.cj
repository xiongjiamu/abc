/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


/**
* RequestManager查找器
*/
public class LifecycleRequestManagerRetriever {
    private let lifecycleToRequestManager: HashMap<String, RequestManager> = HashMap<String, RequestManager>();
    private let deviceLifecycleMap: HashMap<String, DeviceLifecycle> = HashMap<String, DeviceLifecycle>()

    private var factory: RequestManagerFactory;

    public init(factory: RequestManagerFactory) {
        this.factory = factory
    }

    public func getDeviceLifecycle(key: String): DeviceLifecycle {
        let deviceLifecycle: Option<DeviceLifecycle> = deviceLifecycleMap.get(key)
        if(match(deviceLifecycle) {
            case Some(x) => false
            case _ => true
        }) {
            let deviceLifecycleObj: DeviceLifecycle = DeviceLifecycle(key)
            deviceLifecycleMap.put(key, deviceLifecycleObj)
            return deviceLifecycleObj
        }
        return deviceLifecycle.getOrThrow()
    }

    public func getOrCreate(
        context: AbilityContext,
        droplet: Droplet,
        key: String,
        isParentVisible: Bool): RequestManager {

        var managerKey: String = Utils.getRequestManagerKey(key)

        var result: Option<RequestManager> = lifecycleToRequestManager.get(managerKey);
        if (match(result) {
            case Some(x) => false
            case _ => true
        }) {
            let deviceLifecycle = getDeviceLifecycle(key)
            var dropletLifecycle: LifecycleLifecycle = LifecycleLifecycle(deviceLifecycle);
            result =
                Some(factory.build(
                    droplet,
                    dropletLifecycle,
                    context,
                    managerKey));
            
            lifecycleToRequestManager.put(managerKey, result.getOrThrow());
            
            dropletLifecycle.addListener(DefaultLifecycleListener(lifecycleToRequestManager, managerKey));
                
            // This is a bit of hack, we're going to start the RequestManager, but not the
            // corresponding Lifecycle. It's safe to start the RequestManager, but starting the
            // Lifecycle might trigger memory leaks. See b/154405040
            if (isParentVisible) {
                result.getOrThrow().onStart();
            }
        }
        return result.getOrThrow();
    }
    
}

public class DefaultLifecycleListener <: LifecycleListener {

    public var lifecycleToRequestManager: HashMap<String, RequestManager>;

    public var requestManagerKey: String

    public init(lifecycleToRequestManager: HashMap<String, RequestManager>, requestManagerKey: String) {
        this.lifecycleToRequestManager = lifecycleToRequestManager
        this.requestManagerKey = requestManagerKey
    }

    public override func onStart(): Unit {
    }

    public override func onStop(): Unit {
    }

    public override func onDestroy(): Unit {
        this.lifecycleToRequestManager.remove(requestManagerKey);
    }

    public override func hashCode(): Int64 {
        return requestManagerKey.hashCode()
    }

    public operator func ==(that: LifecycleListener): Bool {
        if(that is DefaultLifecycleListener) {
            return this.requestManagerKey == (that as DefaultLifecycleListener).getOrThrow().requestManagerKey
        }
        return false
    }

    public operator func !=(that: LifecycleListener): Bool {
        if(that is DefaultLifecycleListener) {
            return this.requestManagerKey != (that as DefaultLifecycleListener).getOrThrow().requestManagerKey
        }
        return true
    }
}
