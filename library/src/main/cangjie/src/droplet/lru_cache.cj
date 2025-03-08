/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet

public open class LruCache<T, Y> where T <: DropletAny<T>, Y <: DropletAny<Y> {
  public let cache: CacheMap<T, MemoryEntry<Y>> = CacheMap<T, MemoryEntry<Y>>();
  private let initialMaxSize: Int64;
  private var maxSize: Int64;
  private var currentSize: Int64 = 0;

  private let mtx = ReentrantMutex()

  /**
   * Constructor for LruCache.
   *
   * @param size The maximum size of the cache, the units must match the units used in {@link
   *     #getSize(Object)}.
   */
  public init(size: Int64) {
    this.initialMaxSize = size;
    this.maxSize = size;
  }

  /**
   * Sets a size multiplier that will be applied to the size provided in the constructor to put the
   * new size of the cache. If the new size is less than the current size, entries will be evicted
   * until the current size is less than or equal to the new size.
   *
   * @param multiplier The multiplier to apply.
   */
  public func setSizeMultiplier(multiplier: Float32): Unit {
    synchronized(mtx) {
        if (multiplier < 0.0) {
            throw IllegalArgumentException("Multiplier must be >= 0");
        }
        maxSize = Int64(round(Float32(initialMaxSize) * multiplier));
        evict();
    }
  }

  /**
   * Returns the size of a given item, defaulting to one. The units must match those used in the
   * size passed in to the constructor. Subclasses can override this method to return sizes in
   * various units, usually bytes.
   *
   * @param item The item to get the size of.
   */
  protected open func getSize(item: Y): Int64 {
    return 1;
  }

  /** Returns the number of entries stored in cache. */
  protected func getCount(): Int64 {
    synchronized(mtx) {
        return cache.size();
    }
  }

  /**
   * A callback called whenever an item is evicted from the cache. Subclasses can override.
   *
   * @param key The key of the evicted item.
   * @param item The evicted item.
   */
  protected open func onItemEvicted(key: T , item: Y): Unit {
    // optional override
  }

  /** Returns the current maximum size of the cache in bytes. */
  public func getMaxSize(): Int64 {
    synchronized(mtx) {
        return maxSize;
    }
  }

  /** Returns the sum of the sizes of all items in the cache. */
  public func getCurrentSize(): Int64 {
    synchronized(mtx) {
        return currentSize;
    }
  }

  /**
   * Returns true if there is a value for the given key in the cache.
   *
   * @param key The key to check.
   */
  public func contains(key: T): Bool {
    synchronized(mtx) {
        return cache.containsKey(key);
    }
  }

  /**
   * Returns the item in the cache for the given key or null if no such item exists.
   *
   * @param key The key to check.
   */
  public func get(key: T): Option<Y> {
    synchronized(mtx) {
        var entry: Option<MemoryEntry<Y>> = cache.get(key);
        if(match(entry) {
            case Some(x) => true
            case _ => false
        }) {
          let e: MemoryEntry<Y> = entry.getOrThrow()
          return Some(e.value)
        } else {
          return None
        }
    }
  }

  /**
   * Adds the given item to the cache with the given key and returns any previous entry for the
   * given key that may have already been in the cache.
   *
   * <p>If the size of the item is larger than the total cache size, the item will not be added to
   * the cache and instead {@link #onItemEvicted(Object, Object)} will be called synchronously with
   * the given key and item.
   *
   * <p>The size of the item is determined by the {@link #getSize(Object)} method. To avoid errors
   * where {@link #getSize(Object)} returns different values for the same object when called at
   * different times, the size value is acquired in {@code put} and retained until the item is
   * evicted, replaced or removed.
   *
   * <p>If {@code item} is null the behavior here is a little odd. For the most part it's similar to
   * simply calling {@link #remove(Object)} with the given key. The difference is that calling this
   * method with a null {@code item} will result in an entry remaining in the cache with a null
   * value and 0 size. The only real consequence is that at some point {@link #onItemEvicted(Object,
   * Object)} may be called with the given {@code key} and a null value. Ideally we'd make calling
   * this method with a null {@code item} identical to {@link #remove(Object)} but we're preserving
   * this odd behavior to match older versions :(.
   *
   * @param key The key to add the item at.
   * @param item The item to add.
   */
  public func put(key: T, item: Y): Option<Y> {
    synchronized(mtx) {
        let itemSize: Int64 = getSize(item);
        if (itemSize >= maxSize) {
            onItemEvicted(key, item);
            return None;
        }

        currentSize += itemSize;

        var old: Option<MemoryEntry<Y>> = cache.put(key, MemoryEntry<Y>(item, itemSize));
        
        if (match(old) {
            case Some(x) => true
            case _ => false
        }) {
            currentSize -= old.getOrThrow().size;

            if (old.getOrThrow().value != item) {
                onItemEvicted(key, old.getOrThrow().value);
            }
        }
        evict();

        if(match(old) {
            case Some(x) => true
            case _ => false
        }) {
            return Some(old.getOrThrow().value)
        } else {
            return None
        }
    }
  }

  /**
   * Removes the item at the given key and returns the removed item if present, and null otherwise.
   *
   * @param key The key to remove the item at.
   */
  public func remove(key: T): Option<Y> {
    synchronized(mtx) {
        var entry: Option<MemoryEntry<Y>> = cache.remove(key);
        if (match(entry) {
            case Some(x) => false
            case _ => true
        }) {
            return None;
        }
        currentSize -= entry.getOrThrow().size;
        return entry.getOrThrow().value;
    }
  }

  /** Clears all items in the cache. */
  public func clearMemory(): Unit {
    trimToSize(0);
  }

  /**
   * Removes the least recently used items from the cache until the current size is less than the
   * given size.
   *
   * @param size The size the cache should be less than.
   */
  protected func trimToSize(size: Int64): Unit {
    synchronized(mtx) {

        while (currentSize > size) {

            var last: CustomMapItem<T, MemoryEntry<Y>> = cache.list[0]
            var toRemove: MemoryEntry<Y> = last.v
            currentSize -= toRemove.size
            var key: T = last.k
            cache.list.remove(0)
            onItemEvicted(key, toRemove.value);
        }
    }
  }

  private func evict(): Unit {
    trimToSize(maxSize);
  }

}

public class MemoryEntry<Y> <: DropletAny<MemoryEntry<Y>> where Y <: DropletAny<Y> {
    public let value: Y;
    public let size: Int64;

    MemoryEntry(value: Y, size: Int64) {
        this.value = value;
        this.size = size;
    }

    public operator func ==(that: MemoryEntry<Y>): Bool {
      that.size == this.size && that.value == this.value
    }

    public operator func !=(that: MemoryEntry<Y>): Bool {
      that.size != this.size || that.value != this.value
    }

    public func hashCode(): Int64 {
      Utils.hashCodeWrite(value.hashCode(), reset: true)
      Utils.hashCodeWrite(size.hashCode())
      Utils.hashCodeFinish()
    }

    public func toString(): String {
      "Entry : ${value} : ${size}"
    }

}
