// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation

// MARK: Event
public struct Event:IO™{
    public typealias Value = EventValue
    public let value: (any Value)?
    public let metadata: Struct?
    public init(ref v:inout (any Value),meta m:Struct? = nil){ value = v; metadata = m }
    public init(_ v:(any Value)? = nil,meta m:Struct? = nil){ value = v; metadata = m }
    public func equals(_ e:Event?)->Bool{
        return value?.equals(e?.value) ?? false
    }
    public func ™(_ Ω:IO){
        if let v = value{
            true.™(Ω)
            v.™(Ω)
        }else{ false.™(Ω) }
        if let m = metadata{
            true.™(Ω)
            m.™(Ω)
        }else{ false.™(Ω) }
    }
    public static func ™(_ Ω:IO)throws->Event{
        if try Bool.™(Ω){ throw IOError.DECODE("requires a type") } // <-- needs a type
        return Event()
    }
    public static func ™(_ Ω:IO,_ t:T)throws->Event{
        let v = try Bool.™(Ω) ? t.readEventValue(from:Ω) : nil
        let m = try Bool.™(Ω) ? Struct.™(Ω) : nil
        return Event(v,meta: m)
    }
}

infix operator =!=
public func =!=(_ v:Event?, _ w:Event?)->Bool{
    if let v = v{
        if let ve = v.value{
            if let w = w, let we = w.value{ return !ve.equals(we) }
            return true
        }else{ return w?.value != nil }
    }else{ return w != nil }
}

public protocol EventValue:IO™,Equatable{
    static var t:T{get}
    var t:T{get}
    var s:String{get}
    func equals(_ v:(any Event.Value)?)->Bool
}
public extension Event.Value{ // defaults ..
    var t:T{ return Self.t }
    var s:String{ return "\(self)" }
    static func ==(a:Self,b:any Event.Value)->Bool{ return a.equals(b) }
}

extension Array:Event.Value where Element:Event.Value{
    public static var t:T { return .ARRAY(Element.t) }
    public var s: String{
        var s = ""
        for e in self{
            s += s.isEmpty ? "[" : ","
            s += e.s
        }
        return s + "]"
    }
    public static func read(from Ω:IO,t:T)throws->Array<Element>{
        return try t.readEventValue(from:Ω) as! Array<Element>
    }
    public static func == (a:Array<Element>,b:Array<Element>)->Bool{
        let n = a.count
        if b.count != n{ return false }
        // TODO: __parallel?
        for i in 0..<n{ if a[i] != b[i]{ return false } }
        return true
    }
    public func equals(_ v:(any Event.Value)?)->Bool{
        if let xs = v as? [any Event.Value], count == xs.count{
            // TODO: __parallel?
            for i in 0..<count{
                if !self[i].equals( xs[i] ){ return false }
            }
            return true
        }
        return false
    }
}

public extension T{ 
    func readEventValue(from Ω:IO)throws->any Event.Value{
        switch self{
        case .UNKNOWN: fatalError()
        case .BOOL: return try Bool.™(Ω)
        case .DATA: return try Data.™(Ω)
        case .FLOAT: return try Float32.™(Ω)
        case .STRING: return try String.™(Ω)
        case .ARRAY(let t):
            var res = [any Event.Value]()
            let n = try UInt32.™(Ω)
            for _ in 0..<n{ res.append( try t.readEventValue(from:Ω) ) }
            switch t{
            case .UNKNOWN: fatalError()
            case .BOOL: return res as! [Bool]
            case .DATA: fatalError()
            case .FLOAT: return res as! [Float32]
            case .STRING: return res as! [String]
            case .ARRAY: fatalError()
            case .STRUCT: return res as! [Struct]
            }
        case .STRUCT: return try Struct.™(Ω)
        }
    }
}
