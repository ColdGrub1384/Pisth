// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

// Special keys as String

class Keys {
    
    static func key(dec: Int) -> String {
        return String(describing: UnicodeScalar(dec)!)
    }
    
    // From https://en.wikipedia.org/wiki/C0_and_C1_control_codes
    
    static let esc = key(dec: 27)
    
    // Arrows
    static let arrowUp = esc+"[A"
    static let arrowDown = esc+"[B"
    static let arrowLeft = esc+"[C"
    static let arrowRight = esc+"[D"
    
    // Control keys
    static let ctrlAt = key(dec: 0)
    static let ctrlA = key(dec: 1)
    static let ctrlB = key(dec: 2)
    static let ctrlC = key(dec: 3)
    static let ctrlD = key(dec: 4)
    static let ctrlE = key(dec: 5)
    static let ctrlF = key(dec: 6)
    static let ctrlG = key(dec: 7)
    static let ctrlH = key(dec: 8)
    static let ctrlI = key(dec: 9)
    static let ctrlJ = key(dec: 10)
    static let ctrlK = key(dec: 11)
    static let ctrlL = key(dec: 12)
    static let ctrlM = key(dec: 13)
    static let ctrlN = key(dec: 14)
    static let ctrlO = key(dec: 15)
    static let ctrlP = key(dec: 16)
    static let ctrlQ = key(dec: 17)
    static let ctrlR = key(dec: 18)
    static let ctrlS = key(dec: 19)
    static let ctrlT = key(dec: 20)
    static let ctrlU = key(dec: 21)
    static let ctrlV = key(dec: 22)
    static let ctrlW = key(dec: 23)
    static let ctrlX = key(dec: 24)
    static let ctrlY = key(dec: 25)
    static let ctrlZ = key(dec: 26)
    
    static let ctrlBackslash = key(dec: 28)
    static let ctrlCloseBracket = key(dec: 29)
    static let ctrlCtrl = key(dec: 30)
    static let ctrl_ = key(dec: 31)
    
    // Ctrl key from string
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
