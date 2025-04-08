// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
#if canImport(FoundationXML)
    import FoundationXML
#endif

public struct Struct:Event.Value{
    
    public static var t:T{ fatalError("undefined type") }
    public let t : T
    private var _values = [String:any Event.Value]()
    
    public static func validate(_ name:String,_ values:[String:any Event.Value] = [:])->Bool{
        if let t = Struct.type(named:name){
            return validate(t,values)
        }
        return false
    }
    
    public init(_ name:String,_ values:[String:any Event.Value] = [:]){
        var t = Struct.type(named:name)
        if t == nil{
            var vs = [String:T]()
            for (k,v) in values{ vs[k] = v.t }
            t = T.STRUCT(name,vs)
        }
        self.init(t!,values)
    }
    
    public static func validate(_ t:T,_ values:[String:any Event.Value] = [:])->Bool{
        if case .STRUCT(_,let ivars) = t{
            for (s,v) in values{
                if v.t != ivars[s]{ return false }
            }
            return true
        }
        return false
    }
    
    public init(_ t:T,_ values:[String:any Event.Value] = [:]){
        if Struct.validate(t){
            self.t = t
            _values = values
        }else{ fatalError() }
    }
    
    public var isNIL:Bool{ return isa(NIL) }
    
    public func isa(_ t:T?)->Bool{
        if let t = t,  case .STRUCT(_,let ivars) = t{
            for (s,v) in _values{
                if v.t != ivars[s]{ return false }
            }
            return true
        }
        return false
    }
    public func isa(_ t:String)->Bool{
        return isa(Struct.type(named:t))
    }
    
    public subscript(_ s:String)->(any Event.Value)?{
        get{ return _values[s] }
    }
    
    public func ™()->Data{
        CIO.cached{ Ω in
            self.™(Ω)
            return Data(Ω.bytes)
        }
    }
    public func ™(_ Ω:IO){
        if case T.STRUCT(let name,_) = self.t{
            let bs = CIO.cached{ Ω2 in
                name.™(Ω2.clean)
                UInt8(_values.count).™(Ω2) // number of values != number of ivars
                for k in _values.keys.sorted(){ // order important for SKIN equality
                    k.™(Ω2) // write the key
                    _values[k]!.™(Ω2) // write the value
                }
                return Ω2.bytes
            }
            do{
                _ = try Struct.™(Data(bs))
            }catch let e{
                if let x = e as? IOError{
                    print("ERR: \(x.string)")
                }else{
                    print("ERR: \(e.localizedDescription)")
                }
            }
            Ω.write(bs)
        }else{ fatalError() }
    }
    
    public var s$:String{
        var s = t.s$ + "{"
        for (k,v) in _values{ s += "\n  " + k + " = " + v.s }
        return s + "\n}"
    }
    
    public static func ™(_ data:Data)throws->Struct{
        try CIO.cached_{
            Ω in Ω.write(Array(data))
            return try Struct.™(Ω)
        }
    }
    public static func ™(_ Ω:IO)throws->Struct{
        let name = try String.™(Ω)
        if let t = type(named:name), case .STRUCT(_,let ivars) = t{
            let n = try UInt8.™(Ω)
            var vs = [String:any Event.Value]()
            for i in 0..<n{
                do{
                    let k = try String.™(Ω)
                    if let _t = ivars[k]{
                        vs[k] = try _t.readEventValue(from:Ω)
                    }else{
                        throw IOError.DECODE("no value for ivar: \(k)")
                    }
                }catch let e{
                    // note: the i
                    let ks = ivars.keys.sorted()
                    __log__.err("STRUCT caught exception @ var \(i) [\(ks[Int(i)])]")
                    if let x = e as? IOError{
                        __log__.err("  > \(x.string)")
                    }else{
                        __log__.err("  > \(e.localizedDescription)")
                    }
                    throw e
                }
            }
            return Struct(t,vs)
        }else{ __log__.err("STRUCT unknown type-name = \(name)") }
        fatalError()
    }
    
    public static func == (a:Struct,b:Struct)->Bool{
        if a.t != b.t{ return false }
        for (s,_) in a._values{
            if (b[s] == nil) || (!a[s]!.equals(b[s]!)){ return false }
        }
        return true
    }
    public func equals(_ v:(any Event.Value)?)->Bool{ return self == (v as? Struct) }
    
}

// MARK: REGISTRY

public let NIL = T.STRUCT("nil",[:])
public let XY = T.STRUCT("XY",["x":.FLOAT(),"y":.FLOAT()])
public let XYZ = T.STRUCT("XYZ",["x":.FLOAT(),"y":.FLOAT(),"z":.FLOAT()])
public let EULER = T.STRUCT("Euler",["pitch":.FLOAT(),"yaw":.FLOAT(),"roll":.FLOAT()])
public let QUAT = T.STRUCT("Quat",["angle":.FLOAT(),"axis":XYZ])
public let DATE = T.STRUCT("Date",["year":.FLOAT(),"month":.FLOAT(),"day":.FLOAT(),
                            "hour":.FLOAT(),"min":.FLOAT(),"sec":.FLOAT()])

public extension Struct{
    static func type(named:String)->T?{
        __initialise_structs__()
        return __structs__[named]
    }
    static var types:[String:T]{
        __initialise_structs__()
        return __structs__
    }
    static func load(xml:URL){
        __initialise_structs__()
        do{
            let data = try Data(contentsOf:xml)
            let structs = XMLStructParser().parse(data)
            for (_,t) in structs{ _ = t.register() }
        }catch let e{
            __log__.err("Hub: unable to read XML file: \(e.localizedDescription)")
        }
    }
}
private var __initialised__ = false
private var __structs__ = [String:T]()
private func __initialise_structs__(){
    if __initialised__{ return }
    __initialised__ = true
    _ = NIL.register()
    _ = EULER.register()
    _ = QUAT.register()
    _ = XY.register()
    _ = XYZ.register()
    _ = DATE.register()
}
public extension T{
    func register()->Bool{
        __initialise_structs__()
        if case .STRUCT(let name, let ivars) = self {
            if let existing = __structs__[name], case .STRUCT(_,let d) = existing{
                guard ivars.count == d.count else{ return false }
                for (k,v) in ivars{ if v != d[k]{ return false } }
                // = already registered
            }else{ __structs__[name] = self }
        }
        return true
    }
    func instance()->Struct?{
        //__log__.info("instance ..")
        return instance([:])
    }
    func instance(_ known_values: [String:any Event.Value])->Struct?{
        if case .STRUCT(let name,let ts) = self {
            var vs = [String:any Event.Value]()
            for (n,t) in ts{
                var v = known_values[n]
                if v == nil{
                    switch t{
                    case .BOOL(let b): v = b ?? false
                    case .FLOAT(let f): v = f ?? Float32(0)
                    case .STRING(let s): v = s ?? "?"
                    case .STRUCT(_,_): v = t.instance([:])
                    case .DATA: v = Data()
                    default: break
                    }
                }
                if let v = v{ vs[n] = v }
                else{ return nil }
            }
            return Struct(name,vs)
        }
        return nil
    }
}

fileprivate class XMLStructParser : NSObject, XMLParserDelegate {
    
    /*
     EXAMPLE:
     <?xml version="1.0" encoding="UTF-8"?>
     <root>
         <struct name="Date">
             <ivar name="year" type="F"/>
             <ivar name="month" type="F"/>
             <ivar name="day" type="F"/>
             <ivar name="hour" type="F"/>
             <ivar name="min" type="F"/>
             <ivar name="sec" type="F"/>
         </struct>
         <struct name="XYZ">
             <ivar name="x" type="F"/>
             <ivar name="y" type="F"/>
             <ivar name="z" type="F"/>
         </struct>
         <struct name="Euler">
             <ivar name="pitch" type="F"/>
             <ivar name="yaw" type="F"/>
             <ivar name="roll" type="F"/>
         </struct>
     </root>
     */
    
    var _parsed_struct_types = [String:T]()
    
    func parse(_ data:Data)->[String:T]{
        _parsed_struct_types.removeAll()
        let xmlParser = XMLParser(data:data)
        xmlParser.delegate = self
        _ = xmlParser.parse()
        return _parsed_struct_types
    }
    
    var __n__ : String?{ didSet{ __v__.removeAll() }}
    var __v__ = [String:T]()
    
    func parser(
        _ parser: XMLParser,
        didStartElement eName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attrs: [String : String] = [:]
    ) {
        switch eName{
        case "struct": __n__ = attrs["name"] // may be nil
        case "ivar":
            if let n = attrs["name"], var t = attrs["type"]{
                var array = false
                if t.hasPrefix("[") || t.hasSuffix("]"){
                    t = t.trimmingCharacters(in:CharacterSet.SquareBrackets)
                    array = true
                }
                var _t:T?
                switch t{
                case "bool", T.BOOL().s$: _t = .BOOL()
                case "data", T.DATA.s$: _t = .DATA
                case "float", T.FLOAT().s$: _t = .FLOAT()
                case "string", T.STRING().s$: _t = .STRING()
                default: _t = Struct.type(named:t)
                }
                if let t = _t{ __v__[n] = array ? .ARRAY(t) : t }
                else{ __log__.err("no type  called '\(t)'") }
            }
        default: break
        }
    }
    
    func parser(
        _ parser: XMLParser,
        didEndElement eName: String,
        namespaceURI: String?,
        qualifiedName qName: String?){
            if eName == "struct", let n = __n__{
                let s = T.STRUCT(n, __v__)
                _parsed_struct_types[n] = s
                __n__ = nil
                __v__.removeAll()
                _ = s.register()
            }
    }

}

