/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet



public interface DiskCache {
    func get(key: AnyKey): Option<DropletFile>
    func put(key: AnyKey, writer: DiskCacheWriter): Unit
    func delete(key: AnyKey): Unit
    func clear(): Unit
}

public interface DiskCacheWriter {
    func write(file: DropletFile): Bool
}

public interface DiskCacheFactory {
    func build(): DiskCache
}

