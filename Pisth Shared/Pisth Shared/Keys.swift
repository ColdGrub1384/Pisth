// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Class hosting special keys as Unicode characters to be sent to SSH.
open class Keys {
    
    /// Returns unicode character from given `Int`.
    ///
    /// - Parameters:
    ///     - dec: Decimal number from wich return unicode character.
    open static func unicode(dec: Int) -> String {
        return String(describing: UnicodeScalar(dec)!)
    }
    
    // From https://en.wikipedia.org/wiki/C0_and_C1_control_codes
    
    // MARK: - Random keys
    
    /// ESC Key.
    open static let esc = unicode(dec: 27)
    
    /// Delete Key.
    open static let delete = unicode(dec: 127)
    
    // MARK: - Function keys
    
    /// F1
    open static let f1 = esc+"OP"
    
    /// F2
    open static let f2 = esc+"OQ"
    
    /// F3
    open static let f3 = esc+"OR"
    
    /// F4
    open static let f4 = esc+"OS"
    
    /// F5
    open static let f5 = esc+"[15~"
    
    /// F6
    open static let f6 = esc+"[17~"
    
    /// F7
    open static let f7 = esc+"[18~"
    
    /// F8
    open static let f8 = esc+"[19~"
    
    /// F9
    open static let f9 = esc+"[20~"
    
    /// F10
    open static let f10 = esc+"[21~"
    
    /// F11
    open static let f11 = esc+"[23~"
    
    /// F12
    open static let f12 = esc+"[24~"
    
    // MARK: - Arrow keys
    
    /// Up Arrow Key.
    open static let arrowUp = esc+"[A"
    
    /// Down Arrow Key.
    open static let arrowDown = esc+"[B"
    
    /// Right Arrow Key.
    open static let arrowRight = esc+"[C"
    
    /// Left Arrow Key.
    open static let arrowLeft = esc+"[D"
    
    
    // MARK: - Control keys
    
    /// ^@
    open static let ctrlAt = unicode(dec: 0)
    
    /// ^A
    open static let ctrlA = unicode(dec: 1)
    
    /// ^B
    open static let ctrlB = unicode(dec: 2)
    
    /// ^C
    open static let ctrlC = unicode(dec: 3)
    
    /// ^D
    open static let ctrlD = unicode(dec: 4)
    
    /// ^E
    open static let ctrlE = unicode(dec: 5)
    
    /// ^F
    open static let ctrlF = unicode(dec: 6)
    
    /// ^G
    open static let ctrlG = unicode(dec: 7)
    
    /// ^H
    open static let ctrlH = unicode(dec: 8)
    
    /// ^I
    open static let ctrlI = unicode(dec: 9)
    
    /// ^J
    open static let ctrlJ = unicode(dec: 10)
    
    /// ^K
    open static let ctrlK = unicode(dec: 11)
    
    /// ^L
    open static let ctrlL = unicode(dec: 12)
    
    /// ^M
    open static let ctrlM = unicode(dec: 13)
    
    /// ^N
    open static let ctrlN = unicode(dec: 14)
    
    /// ^O
    open static let ctrlO = unicode(dec: 15)
    
    /// ^P
    open static let ctrlP = unicode(dec: 16)
    
    /// ^Q
    open static let ctrlQ = unicode(dec: 17)
    
    /// ^R
    open static let ctrlR = unicode(dec: 18)
    
    /// ^S
    open static let ctrlS = unicode(dec: 19)
    
    /// ^T
    open static let ctrlT = unicode(dec: 20)
    
    /// ^U
    open static let ctrlU = unicode(dec: 21)
    
    /// ^V
    open static let ctrlV = unicode(dec: 22)
    
    /// ^W
    open static let ctrlW = unicode(dec: 23)
    
    /// ^X
    open static let ctrlX = unicode(dec: 24)
    
    /// ^Y
    open static let ctrlY = unicode(dec: 25)
    
    /// ^Z
    open static let ctrlZ = unicode(dec: 26)
    
    /// ^\
    open static let ctrlBackslash = unicode(dec: 28)
    
    /// ^]
    open static let ctrlCloseBracket = unicode(dec: 29)
    
    /// ^^
    open static let ctrlCtrl = unicode(dec: 30)
    
    /// ^_
    open static let ctrl_ = unicode(dec: 31)
    
    /// Returns Ctrl key from `String`.
    ///
    /// - Parameters:
    ///     - str: String from wich return the Ctrl key.
    open static func ctrlKey(from str: String) -> String {
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
