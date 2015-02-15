#ifndef STDARG_H
#define STDARG_H 

typedef char *va_list;

#define INTSIZEOF(arg) (( (sizeof(arg) + sizeof(int) - 1) ) / sizeof(int) * sizeof(int))

#define va_start(ap,v) ( ap = (char *)&v + _INTSIZEOF(v) )

#define va_arg(ap, TYPE)						\
 (ap += INTSIZEOF(TYPE),					\
  *( (TYPE *) (ap - INTSIZEOF(TYPE)) ) )

 #define va_end(ap) ( ap = (va_list)0 )

#endif