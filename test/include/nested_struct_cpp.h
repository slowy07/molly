class RootStruct {
  int value_begin;
  struct {
    float m1;
  } nested_struct_1a, nested_struct_1b;

  class NestedStruct2a {
    float m2;
  };

  int value_mid;
  NestedStruct2a nested_struct_2b;

  struct NestedStruct3a {
    float m3;
  } nested_struct_3b, nested_struct_3c;

  struct {
    float m44;
  };

  int value_end;
};

int test_sizeof_RootStruct();

class RootUnion {
  int value_begin;
  union {
    int iii1;
    float fff1;
  } nested_union_1a, nested_union_1b;

  union NestedUnion2a {
    int iii2;
    float fff2;
  };

  int value_mid;

  NestedUnion2a nested_union_2b;

  union NestedUnion3a {
    int iii3;
    float fff3;
  } nested_union_3b, nested_union_3c;

  union {
    int iii4;
    float fff4;
  };
  int value_end;
};

int test_sizeof_RootUnion();
