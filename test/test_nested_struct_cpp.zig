const std = @import("std");

pub const RootStruct = extern struct {
    value_begin: c_int,
    nested_struct_1a: __Struct0,
    nested_struct_1b: __Struct0,
    value_mid: c_int,
    nested_struct_2b: NestedStruct2a,
    nested_struct_3b: NestedStruct3a,
    nested_struct_3c: NestedStruct3a,
    __struct_field2: __Struct1,
    value_end: c_int,

    pub const __Struct0 = extern struct {
        m1: f32,
    };

    pub const NestedStruct2a = extern struct {
        m2: f32,
    };

    pub const NestedStruct3a = extern struct {
        m3: f32,
    };

    pub const __Struct1 = extern struct {
        m44: f32,
    };
};

extern fn _1_test_sizeof_RootStruct_() c_int;
pub const test_sizeof_RootStruct = _1_test_sizeof_RootStruct_;

pub const RootUnion = extern struct {
    value_begin: c_int,
    nested_union_1a: __Union0,
    nested_union_1b: __Union0,
    value_mid: c_int,
    nested_union_2b: NestedUnion2a,
    nested_union_3b: NestedUnion3a,
    nested_union_3c: NestedUnion3a,
    __union_field2: __Union1,
    value_end: c_int,

    pub const __Union0 = extern union {
        iii1: c_int,
        fff1: f32,
    };

    pub const NestedUnion2a = extern union {
        iii2: c_int,
        fff2: f32,
    };

    pub const NestedUnion3a = extern union {
        iii3: c_int,
        fff3: f32,
    };

    pub const __Union1 = extern union {
        iii4: c_int,
        fff4: f32,
    };
};

extern fn _1_test_sizeof_RootUnion_() c_int;
pub const test_sizeof_RootUnion = _1_test_sizeof_RootUnion_;
