/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class EmptySignature <: AnyKey {
  private static let EMPTY_KEY: EmptySignature = EmptySignature();

  public static func obtain(): EmptySignature {
    return EMPTY_KEY;
  }

  private init() {
    // Empty.
  }

  public override func toString(): String {
    return "EmptySignature";
  }

  public func updateDiskCacheKey(md5: MD5): Unit {
    // Do nothing.
  }

  public override func hashCode(): Int64 {
    return "EmptySignature".hashCode()
  }

    public operator func ==(that: AnyKey): Bool {
        if(that is EmptySignature) {
            return this.toString() == (that as EmptySignature).getOrThrow().toString()
        }
        return false
    }

    public operator func !=(that: AnyKey): Bool {
        if(that is EmptySignature) {
            return this.toString() != (that as EmptySignature).getOrThrow().toString()
        }
        return true
    }
}
