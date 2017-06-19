---
layout: post
title:  "Macros, Macros, Macros"
date:   2017-06-19 13:34:00 -0800
categories: macros
comments: true
---

If you've already taken a look at the [PHP source][php-source], you'll notice there are macros everywhere. Perhaps
you're not familiar with macros, so let's take a look at what they are and why they are used.

## What is a macro in C?

In C, macros are handled by a preprocessor and a generally substituted in the source files before the real
compilation occurs. An easy way to think about it is that for each `#define XXX YYY`, the preprocessor will search
through all of the code and replace the `XXX` value with `YYY`.

## Why do we use macros?

There are three main reasons we use macros: contants, optimization and compatibilty.

### Macros as constants

We can use macros to define contants. When writing your code, it's much easier to see a named constant and
understand its purpose, rather than just seeing a number or string. Consider:

```c
char path[256];
```

versus

```c
char path[MAXPATHLEN];
```

In C, we often represent types as an enum or even a bitmask. It's much clearer to see:

```c
// what does this mean?
int flags = 0x101;

// Versus:
#define ZEND_ACC_STATIC     0x01
#define ZEND_ACC_PUBLIC     0x100

// Note: the compiler optimizer should be able to optimize this into the integer without having
// to calculate it at runtime.
int flags = ZEND_ACC_STATIC | ZEND_ACC_PUBLIC;
```

### Macros as optimization

Macros can also be used to optimize code. Not all C compilers will respect the
[`inline` function attribute][inline-function]. For an operation that may happen many times, each function call
will add a stack frame and add some overhead for the simple function. By using macros, we can ensure that the
injected code will not add an additional function call.

### Macros as compatibilty shims

This is probably the most popular use case for macros in PHP. PHP has many compile time features - ZTS or NTS,
standard extension support - which can affect how functions behave. Additionally, the core internal PHP data models
can change between versions. In fact, almost every internal data structure changed between PHP 5 and 7.

For extensions that want to work for both PHP 5 and 7 that use internal data structures, you have two options:
write your extension twice or use macros around the places that need to be implemented differently.

Here, macros can be used as placeholders for the real implementation.

```c
// in some header
#if PHP_MAJOR_VERSION < 7
    #define MY_MACRO(x) php5_my_function(x);
#else
    #define MY_MACRO(x) php7_my_function(x);
#endif /* PHP_MAJOR_VERSION */
```

Your code would just reference `MY_MACRO(x)` and the macro would handle each implementation.

## What are common macros used in the PHP source?

### Function Visibility

These macros are used as compatibility shims for symbol visibility (what functions and variables are available
outside of the scope of the file). For the GNU C compiler, visibility was added in version 4 - prior to that,
all functions were considered public and were available anywhere.

```c
#if defined(__GNUC__) && __GNUC__ >= 4
# define ZEND_API __attribute__ ((visibility("default")))
# define ZEND_DLEXPORT __attribute__ ((visibility("default")))
#else
# define ZEND_API
# define ZEND_DLEXPORT
#endif

...
#if defined(__GNUC__) && __GNUC__ >= 4
# define PHPAPI __attribute__ ((visibility("default")))
#else
# define PHPAPI
#endif
```

When prefixed in front of a function declaration, we are making that function available across shared object
boundaries.

Example:

```c
// in main/main.c
PHPAPI size_t php_printf(const char *format, ...);
```

The `php_printf()` function is available to any linked object we compile - including any extension that we write.

### Function Declaration

These two macros are used to simplify the declaration of functions and methods available to the user from our
extension. If the standard interface for a PHP function ever changes, you won't have to change all of your
function declarations. Additionally, it standardizes the names of the arguments to your functions, allowing
additional macros to be able to simplify your function's implementation.

```c
// in Zend/zend_API.h
#define PHP_FUNCTION                    ZEND_FUNCTION
#define PHP_METHOD                      ZEND_METHOD
#define ZEND_FUNCTION(name)             ZEND_NAMED_FUNCTION(ZEND_FN(name))
#define ZEND_METHOD(classname, name)    ZEND_NAMED_FUNCTION(ZEND_MN(classname##_##name))
#define ZEND_NAMED_FUNCTION(name)       void name(INTERNAL_FUNCTION_PARAMETERS)
#define ZEND_FN(name)                   zif_##name
#define ZEND_MN(name)                   zim_##name
...
// in Zend/zend.h
# define INTERNAL_FUNCTION_PARAMETERS   zend_execute_data *execute_data, zval *return_value
```

The macros make it simple to define a PHP function. Additionally, it self documents the code by making it easy
to see which C functions correspond to PHP functions.

```c
PHP_FUNCTION(hello_world)
{
    return;
}

PHP_METHOD(MyClass, myMethod)
{
    return;
}

// This roughly translates to:
void zif_##hello_world(zend_execute_data *execute_data, zval *return_value)
{
    return;
}

void zim_##MyClass##_##myMethod(zend_execute_data *execute_data, zval *return_value)
{
    return;
}
```

### Global Variable Access

Throughout the PHP source code, you may encounter macros like `CG()`, `EG()`. These macros simplify
access to global variables or well-known local variables. Because the implementation of per-request globals
is different between Zend Thread Safe (ZTS) and non thread safe (NTS) versions of PHP, we use a macro to
allow for compatibilty for both configurations.

Examples:

* `CG()` - references "compiler globals" and wraps the `zend_compiler_globals` struct
* `EG()` - references "executor globals" and wraps the `zend_executor_globals` struct
* `LANG_SCNG()` - references "language scanner globals" and wraps the `language_scanner_globals` struct
* `INI_SCNG()` - references "ini scanner globals" and wraps the `ini_scanner_globals` struct

```c
// in Zend/zend_global_macros.h
#ifdef ZTS
# define CG(v) ZEND_TSRMG(compiler_globals_id, zend_compiler_globals *, v)
#else
# define CG(v) (compiler_globals.v)
extern ZEND_API struct _zend_compiler_globals compiler_globals;
#endif
...
```

These macros, use the same mechanism, you will use for [creating your own global variables][global-variables]
in your own extension.

[php-source]: https://github.com/php/php-src/
[inline-function]: https://en.wikipedia.org/wiki/Inline_function
[global-variables]: using-global-variables
