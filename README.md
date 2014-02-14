# Evie

## Install

    npm install evie


## Using the provided class

```coffee
{Evie} = require "evie"

events = new Evie()
```

## Creating your own class with Evie as a mixin

```coffee
{evie} = require "evie"

class MyEvents extends EventEmitter
  evie(@)

events = new MyEvents()
```

## What Evie can do

Evie (and any class that has been evied) provides several useful methods, many
of which rely on following a convention for the names of emitted events.  For
error conditions, emit an event named "error".  For successes, emit "success".

```coffee
events = new Evie()
if everything_wrong?
  events.emit "error", new Error "It is all wrong"
else
  events.emit "success", {everything: "ok"}
```

Other event names are certainly legal, but they are not used by the
`serially`, `concurrently`, and `wrap` methods.

### `forward` and `source`

The `forward` method relays all events from one instance to another. `source`
creates a new instance and forwards all events from it to the caller.  This
allows events to bubble up through a tree, which can be useful in observing
and handling errors at a single place in your system.

```coffee
base = new Evie()
base.on "error", (error) -> console.error "We have a problem:", error

stuff = ->
  base.source (events) ->
    number = Date.now()
    if number % 7 == 0
      events.emit "error", new Error "Oh no, the time is divisible by seven!"
    else
      events.emit "success", number

e1 = stuff()
e1.on "success", (result) ->
  console.log "The time is #{result} and it is NOT divisible by 7"

e2 = stuff()
e2.on "success", (result) ->
  console.log "The time is STILL not divisible by 7."

```

### `wrap`

### `serially`

### `concurrently`



