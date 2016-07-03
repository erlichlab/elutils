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


