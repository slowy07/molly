#include <cstdint>
#include <stdint.h>
#include <stdio.h>
#include <string>
#include <utility>

template <typename T, size_t N> class STLAlignedAllocator {
private:
  size_t state = 0xFAFA0000FAFA0000;

public:
  using value_type = T;
  using pointer = T *;
  using const_pointer = const T *;
  using reference = T &;
  using const_reference = const T &;
  using size_type = size_t;
  using difference_type = ptrdiff_t;

  inline STLAlignedAllocator() = default;
  template <typename T2>
  inline explicit STLAlignedAllocator(const STLAlignedAllocator<T2, N> &) {}

  inline pointer allocate(size_t inN) {
    return (pointer)malloc(sizeof(T) * inN);
  }

  inline void deallocate(pointer inPointer, size_type) {
    free((void *)inPointer);
  }

  inline bool operator==(const STLAlignedAllocator<T, N> &) const {
    return true;
  }

  inline bool operator!=(const STLAlignedAllocator<T, N> &) const {
    return false;
  }

  template <typename T2> struct rebind {
    using other = STLAlignedAllocator<T2, N>;
  };
};

struct string_layout {
#ifdef _MSC_VER
  void *ptr;
  size_t __data;
  size_t len;
  size_t capacity;
#else
  size_t capacity;
  size_t len;
  void *ptr;
#endif // _MSC_VER
};

template <class _Alloc> struct string_with_custom_alloc_layout {
#ifdef _MSC_VER
  _Alloc alloc;
  void *ptr;
  size_t __data;
  size_t len;
  size_t capacity;
#else
  size_t capacity;
  size_t len;
  void *ptr;
  _Alloc alloc;
#endif
};

int main(int argc, char *argv[]) {
  printf("std::string<char>\n");
  printf("size: %llu -> %llu\n", sizeof(std::string), sizeof(string_layout));

  auto vec0 = std::string();
  for (size_t i = 0; i < 55; i++) {
    vec0.push_back('0');
  }
  auto in_place0 = (char *)(&vec0);
  auto heap0 = (string_layout *)(&vec0);

  printf("len: %lld\n", (int64_t)vec0.length());
  printf("data: %p\n", vec0.data());
  printf("in_place: ");
  for (size_t i = 0; i < sizeof(std::string); i++) {
    if ((i != 0) && (i % 8 == 0))
      printf(" ");
    printf("%02hhX", in_place0[i]);
  }
  printf("\n");
  printf("heap: %p %lld %lld\n", heap0->ptr, heap0->len, heap0->capacity);
  printf("-----------");
  printf("std::basic_string<char, std::char_traits<char>, "
         "STLAlignedAllocator<char, 64>>\n");
  printf(
      "size: %llu -> %llu\n",
      sizeof(std::basic_string<char, std::char_traits<char>,
                               STLAlignedAllocator<char, 64>>),
      sizeof(string_with_custom_alloc_layout<STLAlignedAllocator<char, 64>>));

  auto vec1 = std::basic_string<char, std::char_traits<char>,
                                STLAlignedAllocator<char, 64>>();
  for (size_t i = 0; i < 55; i++) {
    vec1.push_back('0');
  }

  auto in_place1 = (char *)(&vec1);
  auto heap1 =
      (string_with_custom_alloc_layout<STLAlignedAllocator<char, 64>> *)(&vec1);

  printf("len: %lld\n", (int64_t)vec1.length());
  printf("data: %p\n", vec1.data());
  printf("in_place: ");
  for (size_t i = 0;
       i < sizeof(std::basic_string<char, std::char_traits<char>,
                                    STLAlignedAllocator<char, 64>>);
       i++) {
    if ((i != 0) && (i % 8 == 0))
      printf(" ");
    printf("%02hhX", in_place1[i]);
  }
  printf("\n");
  printf("alloc: %p\n", heap1->alloc);
  printf("heap: %p %lld %lld\n", heap1->ptr, heap1->len, heap1->capacity);

  return 0;
}
