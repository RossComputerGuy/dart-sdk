// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the file APIs by providing unexpected type arguments. The test
// passes if the VM does not crash.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'fuzz_support.dart';
import 'file_write_only_test.dart' show withTempDir, withTempDirSync;

import "package:expect/async_helper.dart";

fuzzSyncMethods() {
  withTempDirSync('dart_file_fuzz', (temp) {
    typeMapping.forEach((k, v) {
      File? file;
      doItSync(() => file = new File('${temp.path}/${v as String}'));
      if (file == null) return;
      final f = file!;
      doItSync(f.existsSync);
      doItSync(f.createSync);
      doItSync(f.deleteSync);
      doItSync(f.lengthSync);
      doItSync(f.lastModifiedSync);
      doItSync(() => f.path);
      doItSync(() => f.openRead().listen((_) {}, onError: (e) {}));
      doItSync(f.readAsBytesSync);
      doItSync(f.readAsStringSync);
      doItSync(f.readAsLinesSync);
      typeMapping.forEach((k2, v2) {
        doItSync(() => f.openSync(mode: v2 as FileMode));
        doItSync(() => f.openWrite(mode: v2 as FileMode));
        doItSync(() => f.readAsStringSync(encoding: v2 as Encoding));
        doItSync(() => f.readAsLinesSync(encoding: v2 as Encoding));
      });
    });
  });
}

fuzzAsyncMethods() async {
  asyncStart();
  withTempDir('dart_file_fuzz', (temp) async {
    final futures = <Future>[];
    typeMapping.forEach((k, v) {
      File? file;
      doItSync(() => file = new File('${temp.path}/${v as String}'));
      if (file == null) return;
      final f = file!;
      futures.add(doItAsync(f.exists));
      futures.add(doItAsync(f.delete));
      futures.add(doItAsync(() => f.parent));
      futures.add(doItAsync(f.length));
      futures.add(doItAsync(f.lastModified));
      futures.add(doItAsync(f.open));
      futures.add(doItAsync(() => f.path));
      futures.add(doItAsync(f.readAsBytes));
      futures.add(doItAsync(f.readAsLines));
      futures.add(doItAsync(f.readAsString));
      typeMapping.forEach((k2, v2) {
        futures.add(doItAsync(() => f.open(mode: v2 as FileMode)));
        futures.add(doItAsync(() => f.readAsString(encoding: v2 as Encoding)));
        futures.add(doItAsync(() => f.readAsLines(encoding: v2 as Encoding)));
      });
    });
    await Future.wait(futures).then((_) {
      asyncEnd();
    });
  });
}

fuzzSyncRandomAccessMethods() {
  withTempDirSync('dart_file_fuzz', (temp) {
    var file = new File('${temp.path}/x');
    file.createSync();
    var modes = [FileMode.read, FileMode.write, FileMode.append];
    for (var m in modes) {
      var opened = file.openSync(mode: m);
      typeMapping.forEach((k, v) {
        doItSync(() => opened.setPositionSync(v as int));
        doItSync(() => opened.truncateSync(v as int));
        doItSync(() => opened.writeByteSync(v as int));
      });
      for (var p in typePermutations(2)) {
        doItSync(() => opened.writeStringSync(p[0], encoding: p[1]));
      }
      for (var p in typePermutations(3)) {
        doItSync(() => opened.readIntoSync(p[0], p[1], p[2]));
        doItSync(() => opened.writeFromSync(p[0], p[1], p[2]));
      }
      opened.closeSync();
    }
  });
}

fuzzAsyncRandomAccessMethods() async {
  asyncStart();
  await withTempDir('dart_file_fuzz', (temp) async {
    var file = new File('${temp.path}/x');
    file.createSync();
    var modes = [FileMode.read, FileMode.write, FileMode.append];
    var futures = <Future>[];
    var openedFiles = [];
    for (var m in modes) {
      var opened = file.openSync(mode: m);
      openedFiles.add(opened);
      typeMapping.forEach((k, v) {
        futures.add(doItAsync(() => opened.setPosition(v as int)));
        futures.add(doItAsync(() => opened.truncate(v as int)));
        futures.add(doItAsync(() => opened.writeByte(v as int)));
      });
      for (var p in typePermutations(2)) {
        futures.add(doItAsync(() => opened.writeString(p[0], encoding: p[1])));
      }
      for (var p in typePermutations(3)) {
        futures.add(doItAsync(() => opened.readInto(p[0], p[1], p[2])));
        futures.add(doItAsync(() => opened.writeFrom(p[0], p[1], p[2])));
      }
    }
    await Future.wait(futures).then((ignore) {
      for (var opened in openedFiles) {
        opened.closeSync();
      }
      asyncEnd();
    });
  });
}

main() {
  fuzzSyncMethods();
  fuzzAsyncMethods();
  fuzzSyncRandomAccessMethods();
  fuzzAsyncRandomAccessMethods();
}
