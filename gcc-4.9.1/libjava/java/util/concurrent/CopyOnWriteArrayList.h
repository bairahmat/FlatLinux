
// DO NOT EDIT THIS FILE - it is machine generated -*- c++ -*-

#ifndef __java_util_concurrent_CopyOnWriteArrayList__
#define __java_util_concurrent_CopyOnWriteArrayList__

#pragma interface

#include <java/lang/Object.h>
#include <gcj/array.h>


class java::util::concurrent::CopyOnWriteArrayList : public ::java::lang::Object
{

public:
  CopyOnWriteArrayList();
  CopyOnWriteArrayList(::java::util::Collection *);
  CopyOnWriteArrayList(JArray< ::java::lang::Object * > *);
  virtual jint size();
  virtual jboolean isEmpty();
  virtual jboolean contains(::java::lang::Object *);
  virtual jboolean containsAll(::java::util::Collection *);
  virtual jint indexOf(::java::lang::Object *);
  virtual jint indexOf(::java::lang::Object *, jint);
  virtual jint lastIndexOf(::java::lang::Object *);
  virtual jint lastIndexOf(::java::lang::Object *, jint);
  virtual ::java::lang::Object * clone();
  virtual JArray< ::java::lang::Object * > * toArray();
  virtual JArray< ::java::lang::Object * > * toArray(JArray< ::java::lang::Object * > *);
  virtual ::java::lang::Object * get(jint);
  virtual ::java::lang::Object * set(jint, ::java::lang::Object *);
  virtual jboolean add(::java::lang::Object *);
  virtual void add(jint, ::java::lang::Object *);
  virtual ::java::lang::Object * remove(jint);
  virtual jboolean remove(::java::lang::Object *);
  virtual jboolean removeAll(::java::util::Collection *);
  virtual jboolean retainAll(::java::util::Collection *);
  virtual void clear();
  virtual jboolean addAll(::java::util::Collection *);
  virtual jboolean addAll(jint, ::java::util::Collection *);
  virtual jboolean addIfAbsent(::java::lang::Object *);
  virtual jint addAllAbsent(::java::util::Collection *);
  virtual ::java::lang::String * toString();
  virtual jboolean equals(::java::lang::Object *);
  virtual jint hashCode();
  virtual ::java::util::Iterator * iterator();
  virtual ::java::util::ListIterator * listIterator();
  virtual ::java::util::ListIterator * listIterator(jint);
  virtual ::java::util::List * subList(jint, jint);
private:
  void writeObject(::java::io::ObjectOutputStream *);
  void readObject(::java::io::ObjectInputStream *);
public: // actually package-private
  static jboolean equals(::java::lang::Object *, ::java::lang::Object *);
  virtual JArray< ::java::lang::Object * > * getArray();
  static JArray< ::java::lang::Object * > * access$0(::java::util::concurrent::CopyOnWriteArrayList *);
  static void access$1(::java::util::concurrent::CopyOnWriteArrayList *, JArray< ::java::lang::Object * > *);
private:
  static const jlong serialVersionUID = 8673264195747942595LL;
  JArray< ::java::lang::Object * > * __attribute__((aligned(__alignof__( ::java::lang::Object)))) data;
public:
  static ::java::lang::Class class$;
};

#endif // __java_util_concurrent_CopyOnWriteArrayList__