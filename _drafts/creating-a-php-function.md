---
layout: post
title: Creating a PHP Function
categories: internals data-structures
---

## A Simple Example

```c
PHP_FUNCTION(hello_world)
{
  RETURN_STRING("Hello World!");
}
```

Why do we need the `PHP_FUNCTION` macro? It standardizes the entry point for all internal PHP functions. If allows extension and core developers to succinctly define the interface for built-in functions. If you need a forward declaration or are creating your function stub, you can simply declare: `PHP_FUNCTION(hello_world);`.

So what is the `PHP_FUNCTION` macro doing behind the scenes?

```c
// From main/php.h
#define PHP_FUNCTION                  ZEND_FUNCTION

// From Zend/zend_API.h
#define ZEND_NAMED_FUNCTION(name)     void name(INTERNAL_FUNCTION_PARAMETERS)
#define ZEND_FUNCTION(name)           ZEND_NAMED_FUNCTION(ZEND_FN(name))
#define INTERNAL_FUNCTION_PARAMETERS  zend_execute_data *execute_data, zval *return_value
```

Our expanded `hello_world` snipped now looks something like this:

```c
void hello_world(zend_execute_data *execute_data, zval *return_value)
{
  RETURN_STRING("Hello World!");
}
```

The `execute_data` parameter includes all of the call arguments for your function and `return_value` is the expected `zval` return.

## Returning Output

As we can see from the method signature, we need to return a reverence to our `return_value`. The Zend API gives us additional macros to help us do this easily.

```c
// From Zend/zend_types.h

// From Zend/zend_API.h
#define ZVAL_STRINGL(z, s, l) do {                \
    ZVAL_NEW_STR(z, zend_string_init(s, l, 0));   \
  } while (0)
#define ZVAL_STRING(z, s) do {                    \
  const char *_s = (s);                           \
  ZVAL_STRINGL(z, _s, strlen(_s));                \
} while (0)
#define RETVAL_STRING(s)      ZVAL_STRING(return_value, s)
#define RETURN_STRING(s)      { RETVAL_STRING(s); return; }

```

## Parsing Input
