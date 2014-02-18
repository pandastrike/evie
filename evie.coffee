{EventEmitter} = require "events"

# Method to mix the Evie methods into a class of your choosing.
evie = (klass) ->
  for name in ["emit", "forward", "source", "serially", "concurrently", "wrap"]
    method = Evie::[name]
    console.log name
    klass::[name] = method


class Evie extends EventEmitter


  emit: (name, args...) ->
    if name != "error" || @_events?.error? || !@_forwards?
      super(name, args...)

    if @_forwards?
      for other in @_forwards
        other.emit name, args...

  forward: (other) ->
    @_forwards ?= []
    @_forwards.push(other)

  source: ->
    other = new @constructor()
    other.forward @
    other

  serially: (builder) ->
    functions = []
    go = (fn) ->
      functions.push fn
    builder go
    series = @source()
    (arg) ->
      results = []
      count = 0
      _fn = (arg) ->
        results.push arg unless arg == undefined
        fn = functions.shift()
        if fn?
          count++
          try
            rval = fn(arg)
            if rval instanceof @constructor
              rval.on "success", _fn
              rval.on "error", (error) ->
                series.emit "error", error
            else
              _fn rval
          catch error
            series.emit "error", error
        else
          series.emit "success", results
      _fn( arg )
      return series

  concurrently: (builder) ->
    functions = []
    go = (name, fn) ->
      functions.push (if fn? then [name, fn] else [null, name])
    builder go
    events = @source()
    (arg) ->
      _fn = (arg) ->
        results = {}; errors = {}
        called = 0; returned = 0
        finish = ->
          returned++
          if called == returned
            if Object.keys(errors).length == 0
              events.emit "success", results
            else
              _error = new Error "concurrently: unable to complete"
              _error.errors = errors
              events.emit "error", _error
        record_error = (name, _error) ->
          if name
            errors[name] = _error
          else
            errors.unnamed_actions ||= []
            errors.unnamed_actions.push _error
          finish()
        return arg if functions.length is 0
        for [name, fn] in functions
          do (name, fn) ->
            success = (result) ->
              results[name] = result if name?
              finish()
            try
              called++
              rval = fn( arg )
              if rval instanceof @constructor
                rval.on "success", success
                rval.on "error", (error) ->
                  record_error name, error
              else
                success rval
            catch _error
              record_error name, _error
      _fn( arg )
      events

  wrap: (fns...) ->
    rval = for fn in fns
      # produce a function that returns an EventChannel
      (args...) =>
        @source (events) =>
          # use the type detection in ::serially to asynchronously
          # evaluate any arguments that are themselves EventChannels.
          series = do @serially (step) =>
            for arg, i in args
              do (arg) =>
                # If the argument is not an EventChannel, it is simply
                # added to the series results array.
                # If the argument is an EventChannel, ::serially will
                # wait for the result and add it to the results array.
                step => arg
          series.on "error", (error) =>
            events.emit "error", error
          series.on "success", (results) =>
            # The items in the results array are now the arguments passed
            # to the wrapper function, except the EventChannel results
            # have been asynchronously evaluated.
            try
              fn(results..., events.callback)
            catch error
              events.emit "error", error

    if rval.length < 2 then rval[0] else rval


module.exports = {evie, Evie}



