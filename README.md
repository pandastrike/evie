# Evie

Evie provides an EventEmtter-style interface, but provides support for event-bubbling.

```coffee-script
parent = new Evie
parent.on "bam", -> console.log "Bam!"

child = new Evie
child.forward parent
child.emit "bam"
```

Evie also supports serial and concurrent execution of multiple asynchronous operations without the need for an external library, like [async][0]. You can also conveniently wrap Node-style callback functions for use with Evie.

[0]:https://github.com/caolan/async

```coffee-script
events = new Evie
events.on "error", (error) -> console.log error
[read, write] = events.wrap fs.readFile, fs.writeFile
do events.serially (go) ->
  go -> read "foo.txt", encoding: "utf8"
  go (text) -> write "bar.txt", text, encoding: "utf8"
  go -> read "bar.txt", encoding: "utf8"
```

## Install

    npm install evie

## Using Evie Directly

```coffee
{Evie} = require "evie"

events = new Evie()
```

## Inheriting From Evie

```coffee
{evie} = require "evie"

class MyEvents
  evie(@)

events = new MyEvents()
```

## Evie Reference

Evie can be used in a similar fashion to `EventEmitter`. There are a few differences: for example, Evie doesn't throw when an `error` event is emitted and there is no handler.

Events are also emitted using `setImmediate`, instead of invoking handlers directly. This makes it easier to define consistent interfaces without leaking details about the implementation. You can still emit an event synchronously using the `fire` method instead of `emit`:

```coffee-script
# using emit:
events.emit "success", result

# using fire
events.fire event: "success", content: result
```

### `forward` and `source`

Evie also supports event-bubbling, similar to the way DOM events work. To forward events to another Evie object, just use the `forward` method.

```coffee-script
parent = new Evie
parent.on "bam", -> console.log "Bam!"

child = new Evie
child.forward parent
child.emit "bam"
```

You can also create new channels from existing channels using the `source` method. The new channel will forward its events to the original channel.

```coffee-script
parent = new Evie
parent.on "bam", -> console.log "Bam!"

child = parent.source()
child.forward parent
child.emit "bam"
```

The `source` method can also take a channel name, which will be prepended to the event originating from it.

```coffee-script
parent = new Evie
parent.on "child.bam", -> console.log "Bam!"

child = parent.source("child")
child.forward parent
child.emit "bam"
```

The `source` method can also take a function, which is useful when you want to return the child event channel.

```coffee-script
parent = new Evie
parent.on "read.error", (error) -> console.log error

read = (path) ->
  parent.source "read", (events) ->
    fs.readFile path, encoding: "utf8", (error, content) ->
      unless error?
        event.emit "success", content
      else
        event.emit "error", error

read "foo.txt"
.on "success", (content) ->
  console.log content
```

In the example above, the errors are handled in the parent, away from the call to read. This makes it possible to separate your error handling logic from the call site, which is often useful.

### `success` and `error` Events

Some of Evie's most useful methods are based on the convention of emitting `success` or `error` events. These include `wrap`, `serially`, and `concurrently`.

### `wrap`

The `wrap` method takes a function that accepts a Node-style callback as its last argument and returns a function that returns an Evie event channel, emitting either a `success` or `error` event.

```coffee-script
events = new Evie
parent.on "error", (error) -> console.log error

read = parent.wrap fs.readFile

read "foo.txt", encoding: "utf8"
.on "success", (content) ->  console.log content
```

### `serially`

The `serially` method allows you to queue up a sequence of asynchronous functions that follow the Evie convention of returning an Evie event channel that will emit either a `success` or `error` event. If a `success` event is emitted, `serially` will run the next function, passing it the result of the previous function (which you are free to ignore, of course).

```coffee-script
events = new Evie
events.on "error", (error) -> console.log error
[read, write] = events.wrap fs.readFile, fs.writeFile
do events.serially (go) ->
  go -> read "foo.txt", encoding: "utf8"
  go (text) -> write "bar.txt", text, encoding: "utf8"
  go -> read "bar.txt", encoding: "utf8"
```

### `concurrently`

The `concurrently` method works similarly to the `serially` method, except that all functions are run concurrently. If a name is passed to the builder method (assigned to the argument `go` in these examples), the result of the function will be added to an object using that property name. This object will be emitted by `concurrently` when all the functions have returned successful.

```coffee-script
events = new Evie
events.on "error", (error) -> console.log error
[read] = events.wrap fs.readFile
do events.concurrently (go) ->
  for file in files
    go (file) -> read file, encoding: "utf8"
.on "success", (cache) ->
  for file, content in cache
    console.log "File: #{file}", "\nContent: #{content}"
```

# `success` and `error` methods

You can do promise-style coding by using the `success` and `error` shortcuts.

```coffee-script
events = new Evie
events.error (error) -> console.log error
[read] = events.wrap fs.readFile
do events.concurrently (go) ->
  for file in files
    go (file) -> read file, encoding: "utf8"
.success (cache) ->
  for file, content in cache
    console.log "File: #{file}", "\nContent: #{content}"
```
