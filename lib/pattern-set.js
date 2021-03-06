// Generated by CoffeeScript 1.7.1
(function() {
  var Pattern, PatternSet;

  Pattern = require("./pattern");

  PatternSet = (function() {
    function PatternSet() {
      this._patterns = {};
    }

    PatternSet.prototype.add = function(specification) {
      var _base;
      return (_base = this._patterns)[specification] != null ? _base[specification] : _base[specification] = new Pattern(specification);
    };

    PatternSet.prototype.remove = function(specification) {
      return delete this._patterns[specification];
    };

    PatternSet.prototype.match = function(target, callback) {
      var pattern, results, specification, _ref;
      results = [];
      _ref = this._patterns;
      for (specification in _ref) {
        pattern = _ref[specification];
        if (pattern.match(target)) {
          if (callback != null) {
            callback(specification);
          }
          results.push(specification);
        }
      }
      return results;
    };

    return PatternSet;

  })();

  module.exports = PatternSet;

}).call(this);
