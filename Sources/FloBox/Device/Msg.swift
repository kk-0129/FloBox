// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation

// MARK: Message
public protocol MessageRecipient{
    func type(ep:EP.Address,box:Device.Box.Name,port:Ports.ID,input:Bool)->T? // Bool = input?
    func received(_ msg:Message,from:EP.Address) // from = device or proxy
}
public extension MessageRecipient{
    func type(ep:EP.Address,box:Device.Box.Name,input:Ports.ID)->T?{
        return type(ep:ep,box:box,port:input,input:true)
    }
    func type(ep:EP.Address,box:Device.Box.Name,output:Ports.ID)->T?{
        return type(ep:ep,box:box,port:output,input:false)
    }
}

public typealias Events = [UInt8:[UInt8:Event]]

private let HANDSHAKE_OP_CODE = UInt8(0)
private let PING_OP_CODE = UInt8(1)
private let PING_UPDATE_OP_CODE = UInt8(2)
private let SUBSCRIBE_OP_CODE = UInt8(3)
private let END_SUBSCRIBE_OP_CODE = UInt8(4)
private let PUBLISH_OP_CODE = UInt8(5)
private let ERROR_OP_CODE = UInt8(6)

public struct Message:IO™{
    
    public static let MIN_LENGTH = 4 + 1 + 1 // token+reply+ping
    
    public typealias Recipient = MessageRecipient
    
    public enum Payload:IO™{
        
        case HANDSHAKE
        case PING
        case PING_UPDATE(Device.Name,[Skin])
        case SUBSCRIBE(Device.Box.Name,Ports.ID,Event) // box,output,event
        case END_SUBSCRIBE
        case PUBLISH(Device.Box.Name,[Ports.ID:Event]) // box,[input,event]
        case ERROR
        
        public var s$:String{
            switch self{
            case .HANDSHAKE: return "HANDSHAKE"
            case .PING: return "PING"
            case .PING_UPDATE: return "PING_UPDATE"
            case .SUBSCRIBE: return "SUBSCRIBE"
            case .END_SUBSCRIBE: return "END_SUBSCRIBE"
            case .PUBLISH: return "PUBLISH"
            case .ERROR: return "ERROR"
            }
        }
        
        public func ™(_ Ω:IO){
            switch self{
            case .HANDSHAKE:
                HANDSHAKE_OP_CODE.™(Ω)
            case .PING:
                PING_OP_CODE.™(Ω)
            case .PING_UPDATE(let name,let skins):
                PING_UPDATE_OP_CODE.™(Ω)
                name.™(Ω)
                skins.™(Ω)
            case .SUBSCRIBE(let box,let out,let event):
                SUBSCRIBE_OP_CODE.™(Ω)
                box.™(Ω)
                out.™(Ω)
                event.™(Ω)
            case .END_SUBSCRIBE: // uses the message token to identify the subscription!
                END_SUBSCRIBE_OP_CODE.™(Ω)
            case .PUBLISH(let box,let events):
                PUBLISH_OP_CODE.™(Ω)
                box.™(Ω)
                events.™(Ω)
            case .ERROR:
                ERROR_OP_CODE.™(Ω)
            }
        }
        
        public static func ™(_ Ω:IO)throws->Payload{ fatalError() }
        
        public static func ™(_ Ω:IO,_ h:Recipient?,_ ep:EP.Address)throws->Payload{
            let id = try UInt8.™(Ω)
            switch id{
            case HANDSHAKE_OP_CODE: return .HANDSHAKE
            case PING_OP_CODE: return .PING
            case PING_UPDATE_OP_CODE:
                let name = try Device.Name.™(Ω)
                let skins = try [Skin].™(Ω)
                return .PING_UPDATE(name,skins)
            case SUBSCRIBE_OP_CODE:
                let b = try Device.Box.Name.™(Ω)
                let o = try String.™(Ω)
                if let t = h?.type(ep:ep,box:b,output:o){
                    return .SUBSCRIBE(b,o,try Event.™(Ω,t))
                }else{
                    __log__.err("can't find type for \(ep.uri).\(b).\(o)")
                    return .ERROR
                }
            case END_SUBSCRIBE_OP_CODE:
                return .END_SUBSCRIBE
            case PUBLISH_OP_CODE:
                let b = try Device.Box.Name.™(Ω)
                let events = try [Ports.ID:Event].™(Ω,b,h,ep,true)
                return .PUBLISH(b,events)
            default:
                __log__.err("payload id = \(id)")
                return .ERROR
            }
        }
        
    }
    
    public typealias Token = UInt64
    
    public let token:Token
    public let payload:Payload
    public let isReply:Bool
    
    public init(_ o:Payload){
        self.init(Message.Token.next,o,false)
    }
    public init(_ t:Token,_ o:Payload){
        self.init(t,o,false)
    }
    init(_ t:Token,_ o:Payload,_ r:Bool){
        token = t
        payload = o
        isReply = r
    }
    
    func reply(_ payload:Payload)->Message{
        return Message(token,payload,true)
    }
    
    public func ™(_ Ω: IO){
        token.™(Ω)
        isReply.™(Ω)
        payload.™(Ω)
    }
    
    public static func ™(_ Ω:IO)throws->Message{ fatalError() }
    
    public static func ™(_ Ω:IO,_ h:Recipient?,_ ep:EP.Address)throws->Message{
        let t = try Token.™(Ω)
        let r = try Bool.™(Ω)
        let o = try Payload.™(Ω,h,ep)
        return Message(t,o,r)
    }
    
}

public extension Message.Token{
    //private static var q = Message.Token(0)
    static var next:Message.Token{
        return Message.Token.random(in:0..<Message.Token.max)
        //return Message.Token(Time.now_s)
        //q = q==Message.Token.max ? 0 : q+1; return q
    }
}

extension Dictionary where Key == Ports.ID, Value == Event{
    func ™(_ Ω:IO){
        UInt8(count).™(Ω)
        for (k,e) in self{
            k.™(Ω)
            e.™(Ω)
        }
    }
    static func ™(_ Ω:IO)throws->[UInt8:Event]{ fatalError() }
    static func ™(_ Ω:IO,_ b:Device.Box.Name,_ h:Message.Recipient?,_ ep:EP.Address,_ input:Bool)throws->[Ports.ID:Event]{
        var res = [Ports.ID:Event]()
        let n = try UInt8.™(Ω)
        for _ in 0..<n{
            let p = try String.™(Ω)
            if let t = h?.type(ep:ep,box:b,port:p,input:input){
                res[p] = try Event.™(Ω,t)
            }
        }
        return res
    }
}
