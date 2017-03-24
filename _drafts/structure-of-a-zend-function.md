---
layout: post
title: Structure of a Zend Function
categories: internals data-structures
---

```c
union _zend_function {
    zend_uchar type;    /* MUST be the first element of this struct! */
    uint32_t   quick_arg_flags;

    struct {
        zend_uchar type;  /* never used */
        zend_uchar arg_flags[3]; /* bitset of arg_info.pass_by_reference */
        uint32_t fn_flags;
        zend_string *function_name;
        zend_class_entry *scope;
        union _zend_function *prototype;
        uint32_t num_args;
        uint32_t required_num_args;
        zend_arg_info *arg_info;
    } common;

    zend_op_array op_array;
    zend_internal_function internal_function;
};
```

```c
struct _zend_op_array {
    /* Common elements */
    zend_uchar type;
    zend_uchar arg_flags[3]; /* bitset of arg_info.pass_by_reference */
    uint32_t fn_flags;
    zend_string *function_name;
    zend_class_entry *scope;
    zend_function *prototype;
    uint32_t num_args;
    uint32_t required_num_args;
    zend_arg_info *arg_info;
    /* END of common elements */

    uint32_t *refcount;

    uint32_t last;
    zend_op *opcodes;

    int last_var;
    uint32_t T;
    zend_string **vars;

    int last_live_range;
    int last_try_catch;
    zend_live_range *live_range;
    zend_try_catch_element *try_catch_array;

    /* static variables support */
    HashTable *static_variables;

    zend_string *filename;
    uint32_t line_start;
    uint32_t line_end;
    zend_string *doc_comment;
    uint32_t early_binding; /* the linked list of delayed declarations */

    int last_literal;
    zval *literals;

    int  cache_size;
    void **run_time_cache;

    void *reserved[ZEND_MAX_RESERVED_RESOURCES];
};
```
