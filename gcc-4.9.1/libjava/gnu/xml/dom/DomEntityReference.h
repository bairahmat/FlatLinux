
// DO NOT EDIT THIS FILE - it is machine generated -*- c++ -*-

#ifndef __gnu_xml_dom_DomEntityReference__
#define __gnu_xml_dom_DomEntityReference__

#pragma interface

#include <gnu/xml/dom/DomNode.h>
extern "Java"
{
  namespace gnu
  {
    namespace xml
    {
      namespace dom
      {
          class DomDocument;
          class DomEntityReference;
      }
    }
  }
}

class gnu::xml::dom::DomEntityReference : public ::gnu::xml::dom::DomNode
{

public: // actually protected
  DomEntityReference(::gnu::xml::dom::DomDocument *, ::java::lang::String *);
public:
  virtual ::java::lang::String * getNodeName();
  virtual ::java::lang::String * getBaseURI();
private:
  ::java::lang::String * __attribute__((aligned(__alignof__( ::gnu::xml::dom::DomNode)))) name;
public:
  static ::java::lang::Class class$;
};

#endif // __gnu_xml_dom_DomEntityReference__