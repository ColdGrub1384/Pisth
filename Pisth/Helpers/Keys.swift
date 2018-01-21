// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Class hosting special keys as Unicode characters to be sent to SSH.
class Keys {
    
    /// Returns unicode character from given `Int`.
    ///
    /// - Parameters:
    ///     - dec: Decimal number from wich return unicode character.
    static func unicode(dec: Int) -> String {
        return String(describing: UnicodeScalar(dec)!)
    }
    
    // From https://en.wikipedia.org/wiki/C0_and_C1_control_codes
    
    // MARK: - Random keys
    
    /// ESC Key.
    static let esc = unicode(dec: 27)
    
    /// Delete Key.
    static let delete = unicode(dec: 127)
    
    
    // MARK: - Arrow keys
    
    /// Up Arrow Key.
    static let arrowUp = esc+"[A"
    
    /// Down Arrow Key.
    static let arrowDown = esc+"[B"
    
    /// Right Arrow Key.
    static let arrowRight = esc+"[C"
    
    /// Left Arrow Key.
    static let arrowLeft = esc+"[D"
    
    
    // MARK: - Control keys
    
    /// ^@
    static let ctrlAt = unicode(dec: 0)
    
    /// ^A
    static let ctrlA = unicode(dec: 1)
    
    /// ^B
    static let ctrlB = unicode(dec: 2)
    
    /// ^C
    static let ctrlC = unicode(dec: 3)
    
    /// ^D
    static let ctrlD = unicode(dec: 4)
    
    /// ^E
    static let ctrlE = unicode(dec: 5)
    
    /// ^F
    static let ctrlF = unicode(dec: 6)
    
    /// ^G
    static let ctrlG = unicode(dec: 7)
    
    /// ^H
    static let ctrlH = unicode(dec: 8)
    
    /// ^I
    static let ctrlI = unicode(dec: 9)
    
    /// ^J
    static let ctrlJ = unicode(dec: 10)
    
    /// ^K
    static let ctrlK = unicode(dec: 11)
    
    /// ^L
    static let ctrlL = unicode(dec: 12)
    
    /// ^M
    static let ctrlM = unicode(dec: 13)
    
    /// ^N
    static let ctrlN = unicode(dec: 14)
    
    /// ^O
    static let ctrlO = unicode(dec: 15)
    
    /// ^P
    static let ctrlP = unicode(dec: 16)
    
    /// ^Q
    static let ctrlQ = unicode(dec: 17)
    
    /// ^R
    static let ctrlR = unicode(dec: 18)
    
    /// ^S
    static let ctrlS = unicode(dec: 19)
    
    /// ^T
    static let ctrlT = unicode(dec: 20)
    
    /// ^U
    static let ctrlU = unicode(dec: 21)
    
    /// ^V
    static let ctrlV = unicode(dec: 22)
    
    /// ^W
    static let ctrlW = unicode(dec: 23)
    
    /// ^X
    static let ctrlX = unicode(dec: 24)
    
    /// ^Y
    static let ctrlY = unicode(dec: 25)
    
    /// ^Z
    static let ctrlZ = unicode(dec: 26)
    
    /// ^\
    static let ctrlBackslash = unicode(dec: 28)
    
    /// ^]
    static let ctrlCloseBracket = unicode(dec: 29)
    
    /// ^^
    static let ctrlCtrl = unicode(dec: 30)
    
    /// ^_
    static let ctrl_ = unicode(dec: 31)
    
    /// Returns Ctrl key from `String`.
    ///
    /// - Parameters:
    ///     - str: String from wich return the Ctrl key.
    static func ctrlKey(from str: String) -> String {
        switch str.lowercased() {
        case "a":
            return (Keys.ctrlA)
        case "b":
            return (Keys.ctrlB)
        case "c":
            return (Keys.ctrlC)
        case "d":
            return (Keys.ctrlD)
        case "e":
            return (Keys.ctrlE)
        case "f":
            return (Keys.ctrlF)
        case "g":
            return (Keys.ctrlG)
        case "h":
            return (Keys.ctrlH)
        case "i":
            return (Keys.ctrlI)
        case "j":
            return (Keys.ctrlJ)
        case "k":
            return (Keys.ctrlK)
        case "l":
            return (Keys.ctrlL)
        case "m":
            return (Keys.ctrlM)
        case "n":
            return (Keys.ctrlN)
        case "o":
            return (Keys.ctrlO)
        case "p":
            return (Keys.ctrlP)
        case "q":
            return (Keys.ctrlQ)
        case "r":
            return (Keys.ctrlR)
        case "s":
            return (Keys.ctrlS)
        case "t":
            return (Keys.ctrlT)
        case "u":
            return (Keys.ctrlU)
        case "v":
            return (Keys.ctrlV)
        case "w":
            return (Keys.ctrlW)
        case "x":
            return (Keys.ctrlX)
        case "y":
            return (Keys.ctrlY)
        case "z":
            return (Keys.ctrlZ)
        case "[":
            return (Keys.esc)
        case "\\":
            return (Keys.ctrlBackslash)
        case "]":
            return (Keys.ctrlCloseBracket)
        case "^":
            return (Keys.ctrlCtrl)
        case "_":
            return (Keys.ctrl_)
        default:
            return ""
        }
    }
}
