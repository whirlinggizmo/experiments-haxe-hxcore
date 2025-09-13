package hxcore.util;

class Glob {
  /**
   * Convert a shell-style glob to an EReg.
   *
   * @param glob           The glob pattern (supports *, ?, **, [..], [!..], {a,b}).
   * @param pathSep        Path separator (default "/"). Must be a single character.
   * @param caseSensitive  EReg 'i' flag if false.
   * @param matchDotfiles  If false, wildcards at segment starts won't match leading '.'.
   * @param wholeString    If true, anchors ^...$; otherwise emit an unanchored pattern.
   */
  public static function toEReg(
    glob:String,
    ?pathSep:String = "/",
    ?caseSensitive:Bool = true,
    ?matchDotfiles:Bool = false,
    ?wholeString:Bool = true
  ):EReg {
    final pattern = toERegString(glob, pathSep, caseSensitive, matchDotfiles, wholeString);
    final flags = caseSensitive ? "" : "i";
    return new EReg(pattern, flags);
  }

  /**
   * Convert a glob to a regex string (pattern only; flags like case-sensitivity are set when building EReg).
   * Note: `caseSensitive` is accepted for API symmetry but does not change the pattern text.
   */
  public static function toERegString(
    glob:String,
    ?pathSep:String = "/",
    ?caseSensitive:Bool = true,     // ignored in pattern text; used by toEReg
    ?matchDotfiles:Bool = false,
    ?wholeString:Bool = true
  ):String {
    if (glob == null) throw "glob cannot be null";
    if (pathSep == null || pathSep.length != 1) throw "pathSep must be a single character";
    final sep = pathSep;
    final notSep = "[^" + escapeForCharClass(sep) + "]";
    final anySeg = notSep + "*";
    final anyChars = "[\\s\\S]*"; // portable dotall

    var out = new StringBuf();
    if (wholeString) out.add("^");

    var i = 0;
    var inClass = false;
    var classNegated = false;
    var braceDepth = 0;
    var segmentStart = true; // at start of a path segment (after ^ or sep)

    while (i < glob.length) {
      var c = glob.charAt(i);

      // Inside [...]: pass through safely; support [!...] as negation.
      if (inClass) {
        if (c == "]") {
          inClass = false;
          out.add("]");
          i++;
          segmentStart = false;
          continue;
        }
        // first char after '[' may be '!' -> '^'
        if (!classNegated) {
          classNegated = true;
          if (c == "!") { out.add("^"); i++; continue; }
          else if (c == "^") { out.add("\\^"); i++; continue; }
        }
        // escape closing bracket and backslash, leave ranges intact (dash as-is)
        switch (c) {
          case "\\", "]": out.add("\\" + c);
          default: out.add(c);
        }
        i++;
        continue;
      }

      // Normal mode
      switch (c) {
        case "/":
          out.add(escapeRegexChar(sep));
          i++;
          segmentStart = true;

        case "\\":
          // treat literal backslash; still regex-escape
          out.add("\\\\");
          i++;
          segmentStart = false;

        case "[":
          inClass = true;
          classNegated = false;
          out.add("[");
          i++;
          segmentStart = false;

        case "{":
          braceDepth++;
          out.add("(?:");
          i++;
          segmentStart = false;

        case "}":
          if (braceDepth > 0) { braceDepth--; out.add(")"); }
          else { out.add("\\}"); } // unmatched, treat literal
          i++;
          segmentStart = false;

        case ",":
          if (braceDepth > 0) out.add("|"); else out.add("\\,");
          i++;
          segmentStart = false;

        case "?":
          if (!matchDotfiles && segmentStart) out.add("(?!\\.)");
          out.add(notSep);
          i++;
          segmentStart = false;

          case "*":
            // collapse run of stars
            var starCount = 1;
            while (i + starCount < glob.length && glob.charAt(i + starCount) == "*") starCount++;
          
            // Lookahead for next char after the stars
            var next = (i + starCount < glob.length) ? glob.charAt(i + starCount) : null;
          
            if (starCount >= 2) {
              // **  -> across separators
              if (next == pathSep) {
                // Handle "**/" as ZERO-OR-MORE segments. Consume the separator and make it optional.
                // Guard dotfiles at segment start if needed.
                var guard = (!matchDotfiles && segmentStart) ? "(?!\\.)" : "";
                out.add("(?:");                  // start optional group
                out.add(guard);
                out.add("[\\s\\S]*");           // cross-dir
                out.add(escapeRegexChar(pathSep));
                out.add(")?");                  // make the whole thing optional
                i += starCount + 1;             // consume the stars + the '/'
                segmentStart = true;            // we just emitted an optional '/', so we’re at a segment start logically
                continue;
              } else {
                // Bare "**" (not followed by a sep) — just match anything
                if (!matchDotfiles && segmentStart) out.add("(?!\\.)");
                out.add("[\\s\\S]*");
              }
            } else {
              // Single *: match within a segment
              if (!matchDotfiles && segmentStart) out.add("(?!\\.)");
              out.add("[^" + escapeForCharClass(pathSep) + "]*");
            }
          
            i += starCount;
            segmentStart = false;

        default:
          // Literal (including '.'): escape regex meta
          if (isRegexMeta(c)) out.add("\\" + c); else out.add(c);
          i++;
          segmentStart = false;
      }
    }

    if (inClass) throw "Unclosed character class '[' in glob";
    if (braceDepth != 0) throw "Unbalanced braces '{' '}' in glob";

    if (wholeString) out.add("$");
    return out.toString();
  }

  // ===== helpers =====

  static inline function isRegexMeta(c:String):Bool {
    return switch (c) {
      case ".", "^", "$", "+", "(", ")", "|", "{", "}", "[", "]", "?": true;
      default: false;
    }
  }

  static inline function escapeRegexChar(c:String):String {
    return isRegexMeta(c) ? ("\\" + c) : c;
  }

  static inline function escapeForCharClass(s:String):String {
    // Escape for inclusion inside [...]
    var b = new StringBuf();
    for (idx in 0...s.length) {
      final c = s.charAt(idx);
      switch (c) {
        case "\\", "]", "^", "-": b.add("\\" + c);
        default: b.add(c);
      }
    }
    return b.toString();
  }
}
