# json2env

[![](https://images.microbadger.com/badges/image/decknroll/json2env.svg)](https://microbadger.com/images/decknroll.com/json2env)
[![](https://img.shields.io/docker/pulls/decknroll/json2env.svg?style=plastic)](https://hub.docker.com/r/decknroll/json2env/)
[![](https://img.shields.io/docker/stars/decknroll/json2env.svg?style=plastic)](https://hub.docker.com/r/decknroll/json2env/)
[![](https://img.shields.io/badge/docker_build-automated-blue.svg?style=plastic)](https://cloud.docker.com/swarm/kilna/repository/docker/decknroll/json2env/builds)

DockerHub: [json2evn](https://hub.docker.com/r/decknroll/json2env/)
GitHub: [json2env](https://github.com/decknroll/json2env)

Kilna's swiss army knife for turning JSON objects into eval-able environment
shell code for setting environment variables.

There are a few projects named `json2env` out there, this one attempts to
meet the following goals:

* Runs under Alpine Linux
* Has only POSIX or busybox tools, plus `jq` as its preprequisites
* Runs under `dash` (busybox/alpine), `bash` and `ksh` shells
* Can output JSON arrays as:
  * Native shell arrays
  * Delimited strings
  * JSON string (compact or pretty)
* Can output JSON objects (dicts/maps) as:
  * Bash-style associative arrays
  * Delimited strings
  * JSON string (compact or pretty)
* Processes input from files or STDIN
* Outputs to STDOUT or a file
* Environment variable name options
  * Change case of the var name(s)
  * Prefix the var name(s)
  * Translate all or only one variable
    * Optionally use a different name than the JSON key
* Can select a subpath of the JSON to export
* Translate with or without export of environment variables

This covers the majority of the use cases for shell-based build and
automation that needs access to JSON data.

## Usage

```
USAGE: json2env [ OPTIONS ] [ FILENAMES ]

Kilna's swiss army knife for turning key-values in a JSON object into eval-able
shell code for setting environment variables.

Processes FILENAMES as JSON documents if provided, otherwise processes standard
input as a JSON document.

         --export : Export shell variables
               -x   (prepend each key=val with shell's export keyword)

      --path PATH : JSON sub-path in jq .path.to.the.object dot-prefix notation
          -p PATH   (e.g '.env_vars') - defaults to '.' for the root JSON object.
                    The referenced path must only be a JSON object (dict/map/hash),
                    not an array, string, etc.

  --prefix PREFIX : Prepend this string the to names of output shell variables
        -p PREFIX

          --upper : Translate JSON keys into uppercase shell environment vars
               -u

          --lower : Translate JSON keys into lowercase shell environment vars
               -l

        --key KEY : Only output this single key in the object
           -k KEY   (defaults to all keys)

  --env-name NAME : When outputting a single key with --key, force this value
          -e NAME   as the environment variable name

           --text : JSON objects and arrays become newline delimited text
               -t   rather than the default behavior of setting the shell
                    environment variable to a JSON string representation

  --kv-sep STRING : Key-value separator for list-style translation of JSON
        -K STRING   objects (defaults to ':')

--list-sep STRING : Record separator for list-style translation
        -L STRING   (defaults to newline)

          --array : JSON arrays are translated into POSIX shell native arrays
               -a   (overrides --text)

          --assoc : JSON objects are tranlated into bash-style native
               -a   associative arrays (overrides --text)

          --force : Output shell native for --array or --assoc even if the
               -f   current shell does not support it

         --strict : Fail on JSON keys which aren't alphanumeric + underscore
               -s   (defaults to translating keys)

  --out-file FILE : Output to a file instead of STDOUT
          -o FILE

        --compact : Outpu Opt JSON strings in compact mode
               -c

           --help : Show help
               -h
```
## Docker

This project also builds an associated docker image `decknroll/json2env`, so
you can run `json2env` without installing locally:

```
$ cat env.json | docker run decknroll/json2env > env.sh
```

All of the command line parameters are supported, pass them as options to
`docker run` the same as if you were calling the script directly:

```
$ cat foo.json | docker run decknroll/json2env --lower --prefix env_ --text > foo.sh
```

The Docker image is only 7mb in size.

## Examples

### Saving to a `.env` file

Many tools use a `.env` file to set properties for a given directory. If you
have a bunch of parameters in an `environment.json` file:

```
{
  "profile": "main",
  "mode":    "init"
}
```

...and you want to create `.env` file from it, simply:

```
$ json2env --out-file .env environment.json
$ cat .env
profile=main
mode=init
```

### Setting environment variables for immediate use

If you need the environment variables available in the currently-running shell,
simply `eval` the output of this script:

```
$ eval $(json2env --export env-vars.json)
```

Make sure to use `--export` so that any commands run by your shell will inherit
the set values.

### Selecting a JSON sub-path

If you want to set environment variables only for a certain object in the JSON
document `config.json`:

```
{
  "project": "foo",
  "environ": {
    "SERVICE_TOKEN": "ynubAEtfyHue2DZfNPRSAfSDN34zuvbh"
  }
}
```

Then you can export only the `env` key by:

```
$ json2env --export --path .environ config.json
export SERVICE_TOKEN=ynubAEtfyHue2DZfNPRSAfSDN34zuvbh
```

The `--path` is provided in `jq` style .path.to.the.object syntax.

### Changing variable names

If you want to change the case of the var names you can use `--lower` or
`--upper`:

```
$ json2env --export --lower .environ config.json
export service_token=ynubAEtfyHue2DZfNPRSAfSDN34zuvbh
```

If you only need one key as opposed to all keys in a JSON document path, you
can specify it using `--key`, and if you want to set an environment variable
name other than one based on the key, use the `--env-name` option.

You can also prefix all keys with `--prefix` to avoid name collisions and/or to
group the environment variables.

### Arrays

Given a file `letters.json`
```
{
  "alpha": [
    "a",
    "b",
    "c"
  ]
}
```

We can see that JSON arrays are by default translated to JSON strings for the
environment:

```
$ json2env letters.json
alpha='[
  "a",
  "b",
  "c"
]'
```

You can also compact the JSON syntax:

```
$ json2env --compact letters.json
alpha='["a","b","c"]'
```

JSON isn't very handy for manipulating in the shell, so you can alos
use `--array` to output as a shell array:

```
$ json2env --array letters.json
alpha=('a' 'b' 'c')
```

Which you can then use in a `for` loop.

Some minimalist shells don't support arrays (like `dash` which comes with
Alpine Linux), or sometimes you just want to flatten to a text-based list,
and that's what `--text` is for:

```
$ json2env --array letters.json
alpha='a
b
c'
```

The default delimited is newline, if you want to use for example spaces
or commas instead, use `--list-sep`:

```
$ json2env --text --list-sep ' ' letters.json
alpha='a b c'
$ json2env --text --list-sep , letters.json
alpha='a,b,c'
```

### Objects

Likewise given a file `translate.json`
```
{
  "words": {
    "uno": "one",
    "dos": "two",
    "tres": "three"
  }
}
```

Much the same, JSON objects are by default translated to JSON strings for the
environment:

```
$ json2env translate.json
words='{
  "uno": "one",
  "dos": "two",
  "tres": "three"
}'
```

Just like with arrays, you can also compact the JSON syntax:

```
$ json2env --compact translate.json
words='{"uno":"one","dos":"two","tres":"three"}'
```

If you have a modern bash-like shell, you can also use `--assoc` to output an
associative array:

```
$ json2env --assoc translate.json
declare -A words=(
  [dos]=two
  [tres]=three
  [uno]=one
)
```

Many shells don't support bash-style associative arrays. So, as with arrays,
you can also use `--text` to output objects as lists. The default is a space
between the key and the value, with a newline between each entry.

```
$ json2env --text translate.json
words='dos two
tres three
uno one'
```

And you can change the separators as well with `--list-sep` and `--kv-sep`:

```
$ json2env --text --list-sep ';' --kv-sep '=' translate.json
words='dos=two;tres=three;uno=one'
```

