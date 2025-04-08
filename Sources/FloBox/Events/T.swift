/*
 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄
 MIT License

 Copyright (c) 2025 kk-0129

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */
import Foundation

// MARK: T
public indirect enum T:IO™,Hashable,Equatable{
    
    case UNKNOWN
    case BOOL(Bool?=nil)
    case DATA
    case FLOAT(Float32?=nil)
    case STRING(String?=nil)
    case ARRAY(T)
    case STRUCT(String,[String:T])
    
    public var dv:(any Event.Value)?{
        switch self{ // default value => param
        case .BOOL(let b): return b
        case .FLOAT(let f): return f
        case .STRING(let s): return s
        default: return nil
        }
    }
    
    public func copy(dv:(any Event.Value)?)->T{
        switch self{
        case .BOOL(_): return .BOOL((dv as! Bool))
        case .FLOAT(_): return .FLOAT((dv as! Float32))
        case .STRING(_): return .STRING((dv as! String))
        default: fatalError()
        }
    }
    
    public var s$:String{
        switch self{
        case .UNKNOWN: return "?"
        case .BOOL: return "B"
        case .DATA: return "D"
        case .FLOAT: return "F"
        case .STRING: return "S"
        case .ARRAY(let t): return "[" + t.s$ + "]"
        case .STRUCT(let name,_): return name
        }
    }
    
    public static func type(named s:String)->T?{
        let s = s.trimmingCharacters(in:.whitespacesAndNewlines)
        switch s{
        case "?": return .UNKNOWN
        case "B": return Bool.t
        case "D": return Data.t
        case "F": return Float.t
        case "S": return String.t
        default:
            if s.hasPrefix("[") && s.hasSuffix("]"){
                let s = s.trimmingCharacters(in:.SquareBrackets)
                if let t = type(named:s){
                    return .ARRAY(t)
                }
            }
            return Struct.type(named:s)
        }
    }
    
    // MARK: Hash
    public func hash(into h: inout Hasher){
        CIO.cached{ Ω in
            self.™(Ω)
            h.combine(Ω.bytes)
        }
    }
    public static func ==(a:T,b:T)->Bool{ return a.s$ == b.s$ }
    
    // MARK: IO™
    public func ™(_ Ω:IO){
        switch self{
        case .UNKNOWN:
            _UNKNOWN_ID_.™(Ω)
        case .BOOL(let v):
            _BOOL_ID_.™(Ω)
            if let v = v{ true.™(Ω); v.™(Ω)}else{ false.™(Ω) }
        case .DATA:
            _DATA_ID_.™(Ω)
        case .FLOAT(let v):
            _FLOAT_ID_.™(Ω)
            if let v = v{ true.™(Ω); v.™(Ω)}else{ false.™(Ω) }
        case .STRING(let v):
            _STRING_ID_.™(Ω) 
            if let v = v{ true.™(Ω); v.™(Ω)}else{ false.™(Ω) }
        case .ARRAY(let t):
            _ARRAY_ID_.™(Ω)
            t.™(Ω)
        case .STRUCT(let n,let d):
            _STRUCT_ID_.™(Ω)
            n.™(Ω)
            UInt8(d.count).™(Ω)
            for s in d.keys.sorted(){
                s.™(Ω)
                d[s]!.™(Ω)
            }
        }
    }
    
    public static func ™(_ Ω:IO)throws->T{
        let id = try UInt8.™(Ω)
        switch id{
        case _UNKNOWN_ID_: return .UNKNOWN
        case _BOOL_ID_:
            return .BOOL(try Bool.™(Ω) ? try Bool.™(Ω) : nil)
        case _DATA_ID_:
            return .DATA
        case _FLOAT_ID_:
            return .FLOAT(try Bool.™(Ω) ? try Float32.™(Ω) : nil)
        case _STRING_ID_:
            return .STRING(try Bool.™(Ω) ? try String.™(Ω) : nil)
        case _ARRAY_ID_: return .ARRAY( try T.™(Ω) )
        case _STRUCT_ID_:
            let name = try String.™(Ω)
            var d = [String:T]()
            let n = try UInt8.™(Ω)
            for _ in 0..<n{
                d[ try String.™(Ω) ] = try T.™(Ω)
            }
            return .STRUCT(name,d)
        default: fatalError()
        }
    }
    
}

public extension CharacterSet{
    static let SquareBrackets = CharacterSet(charactersIn:"[]")
}
