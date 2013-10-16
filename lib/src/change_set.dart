// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * A representation of a single change in a scalar value.
 */
class Change {
  dynamic oldValue;
  dynamic newValue;

  /**
   * Creates new [Change] from information about the value before change
   * [oldValue] and after the change [newValue].
   */
  Change(this.oldValue, this.newValue);

  /**
   * Applies another [change] to get representation of whole change.
   */
  void mergeIn(Change change) {
    newValue = change.newValue;
  }

}

/**
 * A representation of a change of map like object.
 */
class ChangeSet {

  Set addedItems = new Set();
  Set removedItems = new Set();

  /**
   * Contains mapping between the changed children and respective changes.
   *
   * The changes are represented either by [ChangeSet] object or by [Change].
   */
  Map changedItems = new Map();

  /**
   * Creates an empty [ChangeSet].
   */
  ChangeSet();

  /**
   * Marks [dataObj] as added.
   */
  void markAdded(dynamic dataObj) {
    if(this.removedItems.contains(dataObj)) {
      this.removedItems.remove(dataObj);
    } else {
      this.addedItems.add(dataObj);
    }
  }

  /**
   * Marks [dataObj] as removed.
   */
  void markRemoved(dynamic dataObj) {
    if(addedItems.contains(dataObj)) {
      this.addedItems.remove(dataObj);
    } else {
      this.removedItems.add(dataObj);
    }
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [dataObj].
   */
  void markChanged(dynamic dataObj, changeSet) {
    if(addedItems.contains(dataObj)) return;

    if(changedItems.containsKey(dataObj)) {
      changedItems[dataObj].mergeIn(changeSet);
    } else {
      changedItems[dataObj] = changeSet;
    }
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void mergeIn(ChangeSet changeSet) {
    for(var child in changeSet.addedItems ){
      markAdded(child);
    }
    for(var dataObj in changeSet.removedItems) {
      markRemoved(dataObj);
    }
    changeSet.changedItems.forEach((child,changeSet) {
      markChanged(child,changeSet);
    });
  }


  /**
   * Returns true if there are no changes in the [ChangeSet].
   */
  bool get isEmpty =>
    this.addedItems.isEmpty &&
    this.removedItems.isEmpty &&
    this.changedItems.isEmpty;
  
}
