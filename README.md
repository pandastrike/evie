# Evie

Evie provides an EventEmtter-style interface, but provides support for event-bubbling, wild-card events, object-literal handler specs, and doesn't require a handler for an `error` event.

```coffee-script
count = 0
parent = Evie.create()
parent.on parent: -> count++

child = Evie.create()
child.forward parent

child.emit "bam"
child.emit "*"

assert count == 2
```
