// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemoryCachingByteStoreTest);
  });
}

@reflectiveTest
class MemoryCachingByteStoreTest {
  test_get_put_evict() {
    var store = new _TestByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // Keys: [1, 2].
    cachingStore.put('1', _b(40));
    cachingStore.put('2', _b(50));

    // Request '1', so now it is the most recently used.
    // Keys: [2, 1].
    cachingStore.get('1');

    // 40 + 50 + 30 > 100
    // So, '2' is evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), hasLength(40));
    expect(cachingStore.get('2'), isNull);
    expect(cachingStore.get('3'), hasLength(30));
  }

  test_put_evict_first() {
    var store = new _TestByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // 40 + 50 < 100
    cachingStore.put('1', _b(40));
    cachingStore.put('2', _b(50));
    expect(cachingStore.get('1'), hasLength(40));
    expect(cachingStore.get('2'), hasLength(50));

    // 40 + 50 + 30 > 100
    // So, '1' is evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), isNull);
    expect(cachingStore.get('2'), hasLength(50));
    expect(cachingStore.get('3'), hasLength(30));
  }

  test_put_evict_firstAndSecond() {
    var store = new _TestByteStore();
    var cachingStore = new MemoryCachingByteStore(store, 100);

    // 10 + 80 < 100
    cachingStore.put('1', _b(10));
    cachingStore.put('2', _b(80));
    expect(cachingStore.get('1'), hasLength(10));
    expect(cachingStore.get('2'), hasLength(80));

    // 10 + 80 + 30 > 100
    // So, '1' and '2' are evicted.
    cachingStore.put('3', _b(30));
    expect(cachingStore.get('1'), isNull);
    expect(cachingStore.get('2'), isNull);
    expect(cachingStore.get('3'), hasLength(30));
  }

  static List<int> _b(int length) {
    return new List<int>(length);
  }
}

class _TestByteStore extends TypedMock implements ByteStore {}
