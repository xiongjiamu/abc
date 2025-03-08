/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public interface AnyFutureTarget <: AnyTarget {
}

public abstract class FutureTarget<R> <: Target<R> & AnyFutureTarget {
  public var future: Option<Future<Option<R>>> = None;

  public func get(): Option<R>
}

public class RequestFutureTarget<R> <: FutureTarget<R> & RequestListener<R> {

  private var resource: Option<R> = None;
  private var request: Option<LoadRequest> = None;
  private var loadFailed: Bool = false;
  private var resultReceived: Bool = false;
  public let width: Int64;
  public let height: Int64;

  private var exception: DropletException = DropletException("");

  private let mon: Monitor
  private var flag: Bool = true

  public init(width: Int64, height: Int64) {
    this.width = width
    this.height = height
    mon = Monitor()
  }

  public func start(): Unit {
      this.future = Some(spawn {
          mon.lock()
          while (flag) {
            mon.wait()
          }
          mon.unlock()
          return resource
      })
  }

  public func onLoadStarted(placeholder: Option<CJResourceDrawable>): Unit {
    start()
  }

  public func onLoadFailed(placeholder: Option<CJResourceDrawable>): Unit {
    loadFailed = true
  }

  public func onLoadCleared(placeholder: Option<CJResourceDrawable>): Unit {
  }

  public func getSize(cb: SizeReadyCallback): Unit {
    cb.onSizeReady(width, height);
  }
    public func removeCallback(): Unit {}


  /** Sets the current request for this target to retain, should not be called outside of Droplet. */
  public func setRequest(request: Option<LoadRequest>): Unit {
    this.request = request
  }

  /** Retrieves the current request for this target, should not be called outside of Droplet. */
  public func getRequest(): Option<LoadRequest> {
    return this.request
  }

  public func get(): Option<R> {
    if(match(this.future) {
      case Some(x) => true
      case _ => false
    }) {
      let f: Future<Option<R>> = this.future.getOrThrow()
      let o1: Option<R> = f.get()
      if(match(o1) {
        case Some(x) => true
        case _ => false
      }) {
        return o1
      }
    }
    return resource
  }

  public func onResourceReady(resource: R, transition: Option<DrawableTransition>): Unit {
  }

  public func onStart(): Unit {}

  public func onStop(): Unit {}

  public func onDestroy(): Unit {}

  public func onLoadFailed(e: DropletException, model: Model, target: Target<R>, isFirstResource: Bool): Bool {
    loadFailed = true;
    exception = e
    return false;
  }

  public func onResourceReady(resource: R, model: Model, target: Target<R>, dataSource: DataSource, isFirstResource: Bool): Bool {
    resultReceived = true;

    if(resource is ByteArrayStream) {
      let r = (resource as ByteArrayStream).getOrThrow().clone()
      this.resource = (r as R)
    } else if(resource is GifDrawable) {
      this.resource = Some(resource)
    } else if(resource is PixelMapDrawable) {
      this.resource = Some(resource)
    } else if(resource is PixelMap) {
      this.resource = Some(resource)
    } else {
      this.resource = Some(resource)
    }
    
    mon.lock()
    flag = false
    mon.unlock()
    mon.lock()
    mon.notifyAll()
    mon.unlock()

    return false;
  }

  public override func hashCode(): Int64 {
    Utils.hashCodeWrite(width.hashCode(), reset: true)
    Utils.hashCodeWrite(height.hashCode())
    if(match(request) {
      case Some(x) => true
      case _ => false
    }) {
      Utils.hashCodeWrite(request.getOrThrow().hashCode())
    }
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: LifecycleListener): Bool {
      if(that is RequestFutureTarget<R>) {
          return this.request == (that as RequestFutureTarget<R>).getOrThrow().request
      }
      return false
  }

  public operator func !=(that: LifecycleListener): Bool {
      if(that is RequestFutureTarget<R>) {
          return this.request != (that as RequestFutureTarget<R>).getOrThrow().request
      }
      return true
  }

  public operator func ==(that: AnyTarget): Bool {
      if(that is RequestFutureTarget<R>) {
          return this.request == (that as RequestFutureTarget<R>).getOrThrow().request
      }
      return false
  }

  public operator func !=(that: AnyTarget): Bool {
      if(that is RequestFutureTarget<R>) {
          return this.request != (that as RequestFutureTarget<R>).getOrThrow().request
      }
      return true
  }

}
