class MPPointF extends Poolable {
  static ObjectPool<Poolable> pool = ObjectPool.create(32, MPPointF(0, 0))..setReplenishPercentage(0.5);

  double _x;
  double _y;

  // ignore: unnecessary_getters_setters
  double get y => _y;

  // ignore: unnecessary_getters_setters
  set y(double value) {
    _y = value;
  }

  // ignore: unnecessary_getters_setters
  double get x => _x;

  // ignore: unnecessary_getters_setters
  set x(double value) {
    _x = value;
  }

  @override
  String toString() {
    return 'x:$_x y:$_y';
  }

  static MPPointF getInstance1(double x, double y) {
    MPPointF result = pool.get();
    result._x = x;
    result._y = y;
    return result;
  }

  static MPPointF getInstance2() {
    return pool.get();
  }

  static MPPointF getInstance3(MPPointF copy) {
    MPPointF result = pool.get();
    result._x = copy._x;
    result._y = copy._y;
    return result;
  }

  MPPointF(this._x, this._y);

  static void recycleInstance(MPPointF instance) {
    pool.recycle1(instance);
  }

  static void recycleInstances(List<MPPointF> instances) {
    pool.recycle2(instances);
  }

  @override
  Poolable instantiate() {
    return MPPointF(0, 0);
  }
}

class MPPointD extends Poolable {
  static ObjectPool<Poolable> pool = ObjectPool.create(64, MPPointD(0, 0))..setReplenishPercentage(0.5);

  static MPPointD getInstance1(double x, double y) {
    MPPointD result = pool.get();
    result.x = x;
    result.y = y;
    return result;
  }

  static void recycleInstance2(MPPointD instance) {
    pool.recycle1(instance);
  }

  static void recycleInstances3(List<MPPointD> instances) {
    pool.recycle2(instances);
  }

  double x;
  double y;

  @override
  Poolable instantiate() {
    return MPPointD(0, 0);
  }

  MPPointD(this.x, this.y);

  /// returns a string representation of the object
  @override
  String toString() {
    return 'MPPointD, x: $x, y: $y';
  }
}

abstract class Poolable {
  // ignore: non_constant_identifier_names
  static int NO_OWNER = -1;
  int currentOwnerId = NO_OWNER;

  Poolable instantiate();
}

class ObjectPool<T extends Poolable> {
  static int ids = 0;

  int poolId;
  int desiredCapacity;
  List<Object> objects;
  int objectsPointer;
  T modelObject;
  double replenishPercentage;

  /// Returns the id of the given pool instance.
  ///
  /// @return an integer ID belonging to this pool instance.
  int getPoolId() {
    return poolId;
  }

  /// Returns an ObjectPool instance, of a given starting capacity, that recycles instances of a given Poolable object.
  ///
  /// @param withCapacity A positive integer value.
  /// @param object An instance of the object that the pool should recycle.
  /// @return
  static ObjectPool create(int withCapacity, Poolable object) {
    var result = ObjectPool(withCapacity, object);
    result.poolId = ids;
    ids++;

    return result;
  }

  ObjectPool(int withCapacity, T object) {
    if (withCapacity <= 0) {
      throw Exception('Object Pool must be instantiated with a capacity greater than 0!');
    }
    desiredCapacity = withCapacity;
    objects = List(desiredCapacity);
    objectsPointer = 0;
    modelObject = object;
    replenishPercentage = 1.0;
    refillPool1();
  }

  /// Set the percentage of the pool to replenish on empty.  Valid values are between
  /// 0.00f and 1.00f
  ///
  /// @param percentage a value between 0 and 1, representing the percentage of the pool to replenish.
  void setReplenishPercentage(double percentage) {
    var p = percentage;
    if (p > 1) {
      p = 1;
    } else if (p < 0) {
      p = 0;
    }
    replenishPercentage = p;
  }

  double getReplenishPercentage() {
    return replenishPercentage;
  }

  void refillPool1() {
    refillPool2(replenishPercentage);
  }

  void refillPool2(double percentage) {
    var portionOfCapacity = (desiredCapacity * percentage).toInt();

    if (portionOfCapacity < 1) {
      portionOfCapacity = 1;
    } else if (portionOfCapacity > desiredCapacity) {
      portionOfCapacity = desiredCapacity;
    }

    for (var i = 0; i < portionOfCapacity; i++) {
      objects[i] = modelObject.instantiate();
    }
    objectsPointer = portionOfCapacity - 1;
  }

  /// Returns an instance of Poolable.  If get() is called with an empty pool, the pool will be
  /// replenished.  If the pool capacity is sufficiently large, this could come at a performance
  /// cost.
  ///
  /// @return An instance of Poolable object T
  T get() {
    if (objectsPointer == -1 && replenishPercentage > 0.0) {
      refillPool1();
    }

    T result = objects[objectsPointer];
    result.currentOwnerId = Poolable.NO_OWNER;
    objectsPointer--;

    return result;
  }

  /// Recycle an instance of Poolable that this pool is capable of generating.
  /// The T instance passed must not already exist inside this or any other ObjectPool instance.
  ///
  /// @param object An object of type T to recycle
  void recycle1(T object) {
    if (object.currentOwnerId != Poolable.NO_OWNER) {
      if (object.currentOwnerId == poolId) {
        throw Exception('The object passed is already stored in this pool!');
      } else {
        throw Exception(
            'The object to recycle already belongs to poolId ${object.currentOwnerId}.  Object cannot belong to two different pool instances simultaneously!');
      }
    }

    objectsPointer++;
    if (objectsPointer >= objects.length) {
      resizePool();
    }

    object.currentOwnerId = poolId;
    objects[objectsPointer] = object;
  }

  /// Recycle a List of Poolables that this pool is capable of generating.
  /// The T instances passed must not already exist inside this or any other ObjectPool instance.
  ///
  /// @param objects A list of objects of type T to recycle
  void recycle2(List<T> objects) {
    while (objects.length + objectsPointer + 1 > desiredCapacity) {
      resizePool();
    }
    final objectsListSize = objects.length;

    // Not relying on recycle(T object) because this is more performant.
    for (var i = 0; i < objectsListSize; i++) {
      var object = objects[i];
      if (object.currentOwnerId != Poolable.NO_OWNER) {
        if (object.currentOwnerId == poolId) {
          throw Exception('The object passed is already stored in this pool!');
        } else {
          throw Exception(
              'The object to recycle already belongs to poolId ${object.currentOwnerId}.  Object cannot belong to two different pool instances simultaneously!');
        }
      }
      object.currentOwnerId = poolId;
      this.objects[objectsPointer + 1 + i] = object;
    }
    objectsPointer += objectsListSize;
  }

  void resizePool() {
    final oldCapacity = desiredCapacity;
    desiredCapacity *= 2;
    var temp = List<Object>(desiredCapacity);
    for (var i = 0; i < oldCapacity; i++) {
      temp[i] = objects[i];
    }
    objects = temp;
  }

  /// Returns the capacity of this object pool.  Note : The pool will automatically resize
  /// to contain additional objects if the user tries to add more objects than the pool's
  /// capacity allows, but this comes at a performance cost.
  ///
  /// @return The capacity of the pool.
  int getPoolCapacity() {
    return objects.length;
  }

  /// Returns the number of objects remaining in the pool, for diagnostic purposes.
  ///
  /// @return The number of objects remaining in the pool.
  int getPoolCount() {
    return objectsPointer + 1;
  }
}
