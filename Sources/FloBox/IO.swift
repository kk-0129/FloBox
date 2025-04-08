// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation

// MARK: IO
public protocol IO™{
    func ™(_ to:IO)
    static func ™(_ from:IO)throws->Self
}
public enum IOError : Error{
    case READ(_ c:String)
    case ENCODE(_ c:String)
    case DECODE(_ c:String)
    var string:String{
        switch self{
        case .READ(let s): return s
        case .ENCODE(let s): return s
        case .DECODE(let s): return s
        }
    }
}
public protocol IO{
    var count:Int{get}
    //var rest_count:Int{get}
    func write(_ bytes:[UInt8])
    func write(ref bytes:inout[UInt8])
    func read(_ n:Int,_ caller:String)throws->[UInt8]
    var rest:[UInt8]{get}
    //var status:String{get} // for debugging
    var bytes:[UInt8]{get}
    //var ridx:Int{ get }
}
public class CIO : IO{
    
    /// IO
    public func write(_ bytes:[UInt8]){
        mx.sync{ _bytes += bytes }
    }
    public func write(ref bytes:inout[UInt8]){
        mx.sync{ _bytes += bytes }
    }
    public func read(_ n:Int,_ caller:String)throws->[UInt8]{
        if n == 0{ return [] }
        if n < 0{ throw IOError.READ("[\(caller)] n = \(n) is negative") }
        let m = _read_index + n
        if m > count{ throw IOError.READ("[\(caller)] n = \(n) is too big \(_read_index):\(count)") }
        return mx.sync{
            let x = _bytes[_read_index..<m]
            _read_index = m
            return [UInt8](x)
        }
    }
    public var rest:[UInt8]{
        return [UInt8](_bytes[_read_index..<(_bytes.count)])
    }
    /*public var status:String{
        let x = _bytes[0..<_read_index]
        let y = _bytes[_read_index...]
        return "\(_read_index)@\(x)\(y)"
    }*/
    // other
    public var bytes:[UInt8]{ return _bytes }
    public var count:Int{ return mx.sync{ _bytes.count } }
    //public var rest_count:Int{ return mx.sync{ _bytes.count - _read_index } }
    private let mx = __mutex__()
    //public var ridx:Int{ return _read_index }
    private var _read_index = 0
    private var _bytes = [UInt8]()
    public var clean:CIO{
        return mx.sync{
            _bytes.removeAll()
            _read_index = 0
            return self
        }
    }
    
    // CACHING
    static private let _cache_mx_ = __mutex__()
    private static var _cache_ = [CIO]()
    public static func cached<R>(_ cb:(CIO)->R)->R{
        let Ω = _cache_mx_.sync{ _cache_.isEmpty ? CIO() : _cache_.removeLast() }
        defer{ _cache_mx_.sync{ CIO._cache_.append(Ω.clean) } }
        return cb(Ω)
    }
    public static func cached_<R>(_ cb:(CIO)throws->R)throws->R{
        let Ω = _cache_mx_.sync{ _cache_.isEmpty ? CIO() : _cache_.removeLast() }
        defer{ _cache_mx_.sync{ CIO._cache_.append(Ω.clean) } }
        return try cb(Ω) 
    }
    
}

extension Set:IO™ where Element:IO™{
    public func ™(_ Ω:IO){ ([Element](self)).™(Ω) }
    public static func ™(_ Ω:IO)throws->Set<Element>{
        return try Set<Element>( [Element].™(Ω) )
    }
}

extension Array:IO™ where Element:IO™{
    public func ™(_ Ω:IO){
        UInt32(count).™(Ω)
        for v in self{ v.™(Ω) }
    }
    public static func ™(_ Ω:IO)throws->[Element]{
        var res = [Element]()
        let n = try UInt32.™(Ω)
        for _ in 0..<n{ res.append(try Element.™(Ω)) }
        return res
    }
}
