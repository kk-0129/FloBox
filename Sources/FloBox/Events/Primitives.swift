// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
//  scp Primitives.swift dasher@10.99.1.223:Swift/FloBox/Sources/FloBox/Events

let _UNKNOWN_ID_ = UInt8(0)
let _BOOL_ID_ = UInt8(1)
let _DATA_ID_ = UInt8(2)
let _FLOAT_ID_ = UInt8(3)
let _STRING_ID_ = UInt8(4)
let _ARRAY_ID_ = UInt8(5)
let _STRUCT_ID_ = UInt8(6)

// MARK: Bool
extension Bool:Event.Value{ 
    public static var t:T{ return T.BOOL() }
    public func ™(_ Ω:IO){ Ω.write([self ? 1 : 0]) }
    public static func ™(_ Ω:IO)throws->Bool{ return try Ω.read(1,"Bool")[0] > 0 }
    public func equals(_ v:(any Event.Value)?)->Bool{ return self == (v as? Bool) }
}

// MARK: UInt8
extension UInt8:IO™{
    public func ™(_ Ω:IO){ Ω.write([self]) }
    public static func ™(_ Ω:IO)throws->UInt8{ return try Ω.read(1,"UInt8")[0] }
}

// MARK: Int8
extension Int8:IO™{
    public func ™(_ Ω:IO){
        let neg = self < 0
        let u = UInt8(abs(self))
        Ω.write([neg ? u | 0b10000000 : u])
    }
    public static func ™(_ Ω:IO)throws->Int8{
        let u = try UInt8.™(Ω)
        if (u & 0b10000000) > 0{ // negative
            return -Int8(u & 0b01111111)
        }else{ return Int8(u) }
    }
}

// MARK: Data
extension Data:Event.Value{
    public static var t:T{ return T.DATA }
    public func ™(_ Ω:IO){
        UInt32(count).™(Ω)
        var bytes = Array(self)
        Ω.write(ref:&bytes)
        //if (Ω.count - n) != N{ __log__.err("DATA serialisation error: data len = \(N) bytes, but wrote \(Ω.count - n) bytes") }
    }
    public static func ™(_ Ω:IO)throws->Data{
        let I = try UInt32.™(Ω)
        //__log__.info("Data.len : Ω#=\(Ω.ridx), len = \(I), rest = \(Ω.rest_count)")
        let n = Int( I )
        return Data( try Ω.read(n,"Data") )
    }
    public func equals(_ v:(any Event.Value)?)->Bool{
        return self == (v as? Data)
    }
}

// MARK: UInt16
private let _shift16 = [0,8]
extension UInt16:IO™{
    public func ™(_ Ω:IO){ Ω.write(bytes) }
    public var bytes:[UInt8]{
        return _shift16.map{ UInt8(truncatingIfNeeded:self>>$0) }
    }
    public static func ™(_ Ω:IO)throws->UInt16{
        var i = -1
        return try Ω.read(2,"UInt16").reduce(UInt16(0),{
            i += 1
            return $0 | UInt16($1)<<_shift16[i]
        })
    }
}

// MARK: UInt32
private let _shift32 = [0,8,16,24]
extension UInt32:IO™{
    public func ™(_ Ω:IO){ Ω.write(bytes) }
    public var bytes:[UInt8]{ return _shift32.map{ UInt8(truncatingIfNeeded:self>>$0) } }
    public static func ™(_ bytes:[UInt8])throws->UInt32{
        var i = -1
        return bytes.reduce(UInt32(0),{ i += 1; return $0 | UInt32($1)<<_shift32[i] })
    }
    public static func ™(_ Ω:IO)throws->UInt32{ return try ™(try Ω.read(4,"UInt32")) }
}

// MARK: UInt64
private let _shift64 = [0,8,16,24,32,40,48,56]
extension UInt64:IO™{
    public func ™(_ Ω:IO){ Ω.write(bytes) }
    public var bytes:[UInt8]{ return _shift64.map{ UInt8(truncatingIfNeeded:self>>$0) } }
    public static func ™(_ bytes:[UInt8])throws->UInt64{
        var i = -1
        return bytes.reduce(UInt64(0),{ i += 1; return $0 | UInt64($1)<<_shift64[i] })
    }
    public static func ™(_ Ω:IO)throws->UInt64{ return try ™(try Ω.read(8,"UInt64")) }
}

// MARK: Float32
extension Float32:Event.Value{
    public static var t:T{ return T.FLOAT() }
    public func ™(_ Ω:IO){ self.bitPattern.™(Ω) }
    public var bytes:[UInt8]{ return self.bitPattern.bytes }
    public static func ™(_ bytes:[UInt8])throws->Float32{
        Float32(bitPattern:try UInt32.™(bytes))
    }
    public static func ™(_ Ω:IO)throws->Float32{
        Float32(bitPattern:try UInt32.™(Ω))
    }
    public func clip(_ lo:Float32,_ hi:Float32)->Float32{
        return max(min(lo,hi),min(self,max(lo,hi)))
    }
    public func equals(_ v:(any Event.Value)?)->Bool{ return self == (v as? Float32) }
}

// MARK: String
extension String:Event.Value{
    public static var t:T{ return T.STRING() }
    public var bytes:[UInt8]{ return [UInt8](self.data(using:.utf8)!) }
    public func ™(_ Ω:IO){
        var q = bytes
        UInt32(q.count).™(Ω)
        Ω.write(ref:&q)
    }
    public static func ™(_ data:Data)throws->String{
        if let s = String(data:data,encoding:.utf8){ return s }
        throw IOError.DECODE("invalid .UTF8 data")
    }
    public static func ™(_ Ω:IO)throws->String{
        return try ™(Data(try Ω.read(try Int(UInt32.™(Ω)),"String")))
    }
    public func equals(_ v:(any Event.Value)?)->Bool{ return self == (v as? String) }
}

// MARK: URL
extension URL:IO™{
    public var s$:String{ return absoluteString }
    public func ™(_ Ω:IO){ s$.™(Ω) }
    public static func ™(_ Ω:IO)throws->URL{
        return try URL(string:String.™(Ω))!
    }
}
