
import Foundation

extension String {
    
    /// Returns a literal JavaScript `String` from `String`.
    ///
    /// ## Example
    ///
    ///     "Hello\nWorld!".javasScriptEscapedString
    ///     // Returns: "\"Hello\\nWorld!\""
    var javaScriptEscapedString: String {
        // Because JSON is not a subset of JavaScript, the LINE_SEPARATOR and PARAGRAPH_SEPARATOR unicode
        // characters embedded in (valid) JSON will cause the webview's JavaScript parser to error. So we
        // must encode them first. See here: http://timelessrepo.com/json-isnt-a-javascript-subset
        // Also here: http://media.giphy.com/media/wloGlwOXKijy8/giphy.gif
        let str = self
            .replacingOccurrences(of:"\u{2028}", with: "\\u2028")
            .replacingOccurrences(of:"\u{2029}", with: "\\u2029")
        // Because escaping JavaScript is a non-trivial task (https://github.com/johnezang/JSONKit/blob/master/JSONKit.m#L1423)
        // we proceed to hax instead:
        let data = try! JSONSerialization.data(withJSONObject: [str], options: [])
        let encodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!
        return encodedString.substring(with: NSMakeRange(1, encodedString.length - 2))
    }
    
    /// Returns `self` as `NSString`.
    var nsString: NSString {
        return self as NSString
    }
    
    /// Returns a file path removing unnecessaries slashes.
    ///
    /// ## Example
    ///
    ///     "/long/path//to//file///inside folder".removingUnnecessariesSlashes.
    ///     // Returns: "/long/path/to/file/inside folder".
    var removingUnnecessariesSlashes: String {
        var newString = self
        while newString.contains("//") {
            newString = newString.replacingOccurrences(of: "//", with: "/")
        }
        
        return newString
    }
    
    /// Returns a new string in which the first occurrence of a target string are replaced by another given string.
    ///
    /// - Parameters:
    ///     - target: `String` to be replaced.
    ///     - replacement: `String` by wich replace `target``.
    func replacingFirstOccurrence(of target: String, with replacement: String) -> String {
        let range = self.range(of: target)
        if let range = range {
            return replacingCharacters(in: range, with: replacement)
        }
        
        return self
    }
    
    /// Returns random String with these characters:
    ///  !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~
    ///
    /// - Parameters:
    ///     - length: Length of returned String.
    static func random(length: Int = 20) -> String {
        let base = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}
