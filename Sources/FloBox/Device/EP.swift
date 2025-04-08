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

public protocol EPAddress{
    typealias URI = String
    static var kind:String{get}
    var uri:URI{get}
}
public extension EPAddress{
    var kind:String{ return Self.kind }
}

public protocol EP : AnyObject{
    typealias Error = EPError
    typealias Address = EPAddress
    typealias Base = EPBase
    var address:Address{get}
    var recipient:Message.Recipient?{ get set } // & start/stop listening
    func send(msg:Message,to:Address,_ cb:@escaping(Message)->(Bool))throws
    func send(msg:Message,to:Address)throws
}

public extension EP{
    var uri:String{ return address.uri }
}

public struct EPError: Error{
    public let description:String
    public init(_ s:String){ description = s }
    public var localizedDescription:String{ return description }
}

open class EPBase : EP{
    
    public let address:Address
    public var recipient:Message.Recipient?// & start/stop listening
    
    public init(_ a:Address){ self.address = a }
    
    private let _mutex = __mutex__()
    private let hmx = __mutex__()
    private var ___reply_handlers___ = [Message.Token:(Message)->(Bool)]()
    private subscript(handler tk:Message.Token)->((Message)->(Bool))?{
        get{ return hmx.sync({ ___reply_handlers___[tk] }) }
        set(h){ hmx.sync({ ___reply_handlers___[tk] = h }) }
    }
    
    public func send(msg:Message,to:EP.Address,_ cb:@escaping(Message)->(Bool))throws{
        guard recipient != nil else{ return }
        if !msg.isReply{
            self[handler:msg.token] = cb
        }
        try send(msg:msg,to:to)
    }
    open func send(msg:Message,to:Address)throws{
        /* override me */
    }
    
    public func received(reply msg:Message,from sender:Address) {
        if msg.isReply{
            if let cb = self[handler:msg.token]{
                if cb(msg){ self[handler:msg.token] = nil }
            }else{
                do{ // could be from an old subscribe, so:
                    try send(msg:Message(msg.token,.END_SUBSCRIBE),to:sender)
                }catch let e{
                    __log__.err(e.localizedDescription)
                }
            }
        }
    }
    
}
