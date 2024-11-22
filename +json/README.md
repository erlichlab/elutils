# Why does this exist?

`mdumps` and `mloads` were written to serve a specific purpose. To create (using `mdumps`) an augmented JSON format that would still be valid JSON but would allow a function (`mloads`) to create a matlab structure from the JSON such that the original and the reloaded structure would be equal. In other words
```matlab
A.foo = 1
A.bar.t = rand(10)
A.bar.d = 'a char array'
A.nerf = 1:10
s = json.mdumps(A) % s is valid json
B = json.mloads(s)

isequaln(A,B) % true

```

This is not possible with the built-in matlab `jsondecode` and `jsonencode` because matlab has two array types: numeric and cell. JSON only has one array type. 

The workaround is to save the matlab object (usually a struct) with two dictionaries. A `val` dictionary which is more or less the output of `jsonencode` and a `meta` dictionary which has type and shape information which can be used to reconstruct the original `struct`.


The following files are compiled binaries from code in [christianpanton/matlab-json](https://github.com/christianpanton/matlab-json.git).
* `fromjson.mex*`
* `setjsonfield.mex*`
* `tojson.mex*`

The libraries in `jsonlib` are compiled from code in [json-c/json-c](https://github.com/json-c/json-c)

In order to use the mexfunctions you must copy (or symlink) the libraries in jsoblib to the appropriate place.

For mac
```bash
cd jsonlib/maci64
sudo cp * /usr/local/lib
```

For linux
```bash
cd jsonlib/amd64
sudo cp * /usr/lib
```


