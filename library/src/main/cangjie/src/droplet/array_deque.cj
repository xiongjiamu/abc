/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class ArrayDeque<K> {
    public var list: ArrayList<K> = ArrayList<K>()

    public func offer(k: K): Bool {
        list.append(k)
        return true
    }

    public func poll(): Option<K> {
        if(list.size > 0) {
            return Some(list[0])
        }
        return None
    }

    public func size(): Int64 {
        return list.size
    }
}