# molly
CPP binding with ZIG including transpiler

running binding

```
zig cc -x c++ -std=c++11 -Xclang -ast-dump=json {input_files}
```

## basic

- run by 
    ```
    zig build run -- library.h
    ```
- modify generated bindings until it works, you might need to import `cpp.zig` located at `src`
