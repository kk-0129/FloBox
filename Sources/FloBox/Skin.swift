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

// MARK: ■ Skin
public struct Skin:IO™,Hashable,Equatable{
    
    public let name:String
    public let inputs,outputs:Ports
    public let metadata:Struct
    private var __bytes__:[UInt8]
    //public var bytes:[UInt8]{ return __bytes__ }
    
    public init(_ n:String,_ i:Ports,_ o:Ports){
        self.init(n,i,o,meta:NIL.instance()!)
    }
    
    public init(_ n:String,_ i:Ports,_ o:Ports,meta m:Struct){
        name = n
        inputs = i
        outputs = o
        metadata = m
        __bytes__ = CIO.cached{ Ω in
            n.™(Ω)
            i.™(Ω)
            o.™(Ω)
            m.™(Ω)
            return Ω.bytes
        }
    }
    
    public var s:String{
        var s = "SKIN: \(name):"
        for (k,v) in inputs{ s += "\n  in: \(k):\(v)" }
        for (k,v) in outputs{ s += "\n  out: \(k):\(v)" }
         s += "\n  \(metadata.s$)"
        return s
    }
    
    public func hash(into h: inout Hasher){ h.combine(__bytes__) }
    public static func ==(a:Skin,b:Skin)->Bool{ return a.__bytes__ == b.__bytes__ }
    
    public func ™(_ Ω:IO){ Ω.write(__bytes__) }
    public static func ™(_ Ω:IO)throws->Skin{
        let n = try String.™(Ω)
        let i = try Ports.™(Ω)
        let o = try Ports.™(Ω)
        let m = try Struct.™(Ω)
        return Skin(n,i,o,meta:m)
    }
    
}
