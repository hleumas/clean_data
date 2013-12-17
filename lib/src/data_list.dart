// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//TODO nested Data objects
//TODO consider functions as subList, getRange, etc. to return DataList
//TODO expand(Iterable) ?

part of clean_dart;

/**
 * List with change notifications. Change set contains indexes which were changed.
 */

class DataList extends Object with ListMixin, ChangeNotificationsMixin implements List {

  Iterator get iterator => _elements.iterator;

  /**
   * Number of elements in this [DataList].
   */
  int get length => _elements.length;

  bool _checkRange(int start, int end){
    if(end < start || start < 0 || _elements.length < end){
      throw new ArgumentError("Incorrect range [$start, $end) for DataList of size ${_elements.length}");
    }
    return true;
  }

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive
   * and replaces them with the contents of the [iterable].
   */
  void replaceRange(int start, int end, Iterable iterable, {skipCount:0, author: null}){
    _checkRange(start, end);
    if(iterable.length < end-start){
      throw new ArgumentError("Must give at least ${end - start} elements in iterable.");
    }

    var iter = iterable.iterator;
    for(int i=0; i<=skipCount ;i++){
      iter.moveNext();
    }
    for(int key = start ; key < end ; key++, iter.moveNext()){
      _markChanged(key, new Change(_elements[key], iter.current));
      _elements[key] = iter.current;
    }

    _notify(author: author);
  }

  /**
   * Overwrites objects of `this` with the objects of [iterable], starting
   * at position [index] in this list.
   */
  void setAll(int index, Iterable iterable, {author: null}){
    replaceRange(index, _elements.length, iterable, author: author);
  }

  /**
   * Removes the object at position [index] from this list.
   */
  dynamic removeAt(int index, {author: null}){
    dynamic result = _elements[index];
    removeRange(index, index+1, author: author);
    return result;
  }

  /**
   * Removes all objects from this list that satisfy [test].
   */
  void removeWhere(bool test(dynamic element), {author: null}){
    List toRemove = [];
    for(int key=0; key<_elements.length ; key++){
        if(test(_elements[key])) toRemove.add(key);
    };
    removeAll(toRemove, author: author);
  }

  /**
   * Removes all objects from this list that fail to satisfy [test].
   */
  void retainWhere(bool test(dynamic element), {author: null}){
    List toRemove = [];
    for(int key=0; key<_elements.length ; key++){
        if(!test(_elements[key])) toRemove.add(key);
    };
    removeAll(toRemove, author: author);
  }

  void removeAll(Iterable indexes, {author: null}){
    List toRemove = new List.from(indexes, growable: false);
    toRemove.sort();

    for(int i=toRemove.length-1; i>=0; i--){
      int key = toRemove[i];
      removeAt(key);
    }
  }

  /**
   * Sorts this list according to the order specified by the [compare] function.
   */
  //TODO author (problem with named and positional paramters)
  void sort([int compare(dynamic a, dynamic b), author=null]){
    List target = new List.from(_elements, growable: false);
    target.sort(compare);

    for(int key=0; key<_elements.length ; key++){
      _markChanged(key, new Change(_elements[key], target[key]));
      _elements[key] = target[key];
    }

    _notify(author: author);
  }

  /**
   * Sets the objects in the range [start] inclusive to [end] exclusive
   * to the given [fillValue].
   */
  //TODO author
  void fillRange(int start, int end, [dynamic fillValue, author=null]){
    for(int key=start ; key<end; key++){
      _markChanged(key, new Change(_elements[key], fillValue));
      _elements[key] = fillValue;
    }

    _notify(author: author);
  }

  /**
   * Shuffles the elements of this list randomly.
   */
  //TODO author
  void shuffle([Random random, author=null]){
    List target = new List.from(_elements, growable: false);
    target.shuffle(random);

    for(int key=0; key<_elements.length ; key++){
      _markChanged(key, new Change(_elements[key], target[key]));
      _elements[key] = target[key];
    }

    _notify(author: author);
  }

  /**
   * Inserts all objects of [iterable] at position [index] in this list.
   */
  void insertAll(int index, Iterable iterable, {author: null}){
    List other = (iterable is List) ? iterable : new List.from(iterable, growable: false);

    // The list will be shifted right after the addition.
    // Changed keys for iterable [index, index + iterable.length)
    for(int key=index ; key<index+iterable.length ; key++){
      _markChanged(key, new Change(_elements[key], other[key-index]));
    };
    // Changed keys for _elements
    for(int key=index + iterable.length ; key<_elements.length ; key++){
      _markChanged(key, new Change(_elements[key], _elements[key - iterable.length]));
    };
    // Added keys [_elements.length, _elements.length + iterable.length).
    for(int key=_elements.length ; key<_elements.length + iterable.length ; key++){
      _markChanged(key, new Change(null, _elements[key - iterable.length]));
      _markAdded(key);
    };

    _elements.insertAll(index, iterable);

    _notify(author: author);
  }

  /**
   * Inserts the object at position [index] in this list.
   */
  void insert(int index, dynamic element, {author: null}){
    insertAll(index, [element], author: author);
  }

  /**
   * Pops and returns the last object in this list.
   */
  dynamic removeLast({author: null}){
    return removeAt(_elements.length-1);
  }

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive.
   */
  //TODO check if optimal when removing from the end of the list
  void removeRange(int start, int end, {author: null}){
    _checkRange(start, end);

    //nothing to do
    if(end == start){
      return;
    }

    int change_end_i = _elements.length - end + start;

    // The list will be shifted left after the removal.
    // Changed keys [start, change_end_i) will be changed for [end, end + change_end_i - start)
    for(int key=start ; key<change_end_i ; key++){
      _markChanged(key, new Change(_elements[key], _elements[end + key - start]));
    };
    // Removed keys [change_end_i, _elements.length).
    for(int key=change_end_i ; key<_elements.length ; key++){
      _markChanged(key, new Change(_elements[key], null));
      _markRemoved(key);
    };

    _elements.removeRange(start, end);

    _notify(author: author);
  }

  /**
   * Copies the objects of [iterable], skipping [skipCount] objects first,
   * into the range [start] inclusive to [end] exclusive of `this`.
   */
  //TODO author
  void setRange(int start, int end, Iterable iterable, [int skipCount = 0, author=null]){
    replaceRange(start, end, iterable, skipCount: skipCount, author: author);
  }


  final List _elements = new List();

  /**
   * Creates an empty [DataList] object.
   */
  DataList();

  /**
   * Creates a new [DataList] object from [Iterable]
   */
  factory DataList.from(Iterable other) {
    DataList result = new DataList();
    other.forEach((element)=>result._elements.add(element));
    result._clearChanges();
    //TODO should be also _clearChangesSync?
    return result;
  }

  dynamic operator[](index) => _elements[index];

  /**
   * Returns true if there is no {key, value} pair in the data object.
   */
  bool get isEmpty {
    return _elements.isEmpty;
  }

  /**
   * Returns true if there is at least one {key, value} pair in the data object.
   */
  bool get isNotEmpty {
    return _elements.isNotEmpty;
  }

  /**
   * Adds the [value] to the end of [DataList].
   */
  void add(dynamic value, {author: null}) {
    addAll([value], author: author);
  }

  /**
   * Adds all key-value pairs of [other] to end of [DataList].
   */
  //TODO add to particular indexes
  void addAll(Iterable other, {author: null}) {
    other.forEach((element) {
      int key = _elements.length;
      _markChanged(key, new Change(null, element));
      _markAdded(key);
      _elements.add(element);
    });

    _notify(author: author);
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(int index, value) {
    _markChanged(index, new Change(_elements[index], value));
    _elements[index] = value;
    _notify();
  }

  /**
   * Removes element with [index] from the data object.
   */
  bool remove(int index, {author: null}) {
    removeRange(index, index+1, author: author);
  }

  void clear({author: null}) {
    removeRange(0, _elements.length, author:author);
  }
}
