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

// MARK: ■ Box
public protocol DeviceBox{ // BOX IMPLEMENTATION
    typealias Name = String
    var skin:Skin{get}
    func publish(_ inputs:[Ports.ID:Event])
    var callback:(([Ports.ID:Event])->())?{get set}
}

// MARK: Device
open class Device{
    
    /* CONVENIENCE */
    public static func async_init(_ name:Name, endpoint:EP, boxs:[any Box],_  completion:@escaping(Device)->()){
        DispatchQueue.global().async{
            completion( Device(name,endpoint:endpoint,boxs:boxs) )
        }
    }
    /* END CONVENIENCE */
    
    public static let TICK = "¶"
    
    public typealias Name = String
    public typealias Box = DeviceBox
    
    public let endpoint:EP
    public var address:EP.Address{ return endpoint.address }
    public let name:Name
    
    public var periodic:(()->())?
    
    public init(_ n:Name, endpoint:EP, boxs:[any Box]){
        name = n
        self.endpoint = endpoint
        for b in boxs{ _ = add(box:b) }
        __log__.info("Device '\(name)' started @ \(address.uri)")
        endpoint.recipient = self // auto starts listening
        _clock = __clock__(ms:50){ self._clock_cb_() }
        _clock.running = true
    }
    
    // MARK: Boxes
    private var __boxs__ = [String:Box](){ didSet{ updateClients() }}
    private var __clocks__ = [String:__clock__]()
    public func updateClients(){
        for (_,c) in _clients_{ c.update = true }
    }
    open func add(box:Device.Box)->Bool{
        let n = box.skin.name
        if __boxs__[n] == nil{
            var b = box
            __boxs__[n] = b
            b.callback = { o in self.callback(n,o) }
            return true
        }else{
            __log__.err("Duplicate Box name '\(n)' - will ignore the new box!")
            return false
        }
    }
    public func publishable(box:Device.Box)->Bool{
        return __boxs__[box.skin.name] == nil
    }
    open func remove(box:Device.Box)->Bool{
        if var b = __boxs__[box.skin.name],b.skin == box.skin{
            b.callback = nil
            let n = box.skin.name
            __boxs__[n] = nil
            __clocks__[n] = nil
            return true
        }
        return false
    }
    
    // MARK: ➤ clock
    private var _clock:__clock__!
    private var _clock_mux_ = __mutex__()
    private var _events_to_publish_ = [Device.Box.Name:[Ports.ID:Event]]()
    private func _clock_cb_(){
        let nes = _clock_mux_.sync{
            let x = _events_to_publish_
            _events_to_publish_.removeAll()
            return x
        }
        for (box_name,es) in nes{
            if let box = __boxs__[box_name]{
                box.publish(es)
            }
        }
        self.periodic?() // hook for subclassing periodic events
    }
    
    // MARK: ➤ waitForExit
    public func waitForExit(){
        while let s = readLine(), !["q","quit","end","close"].contains(s){}
        shutdown()
    }
    public func shutdown(){
        for (_,v) in __boxs__{ var b = v; b.callback = nil }
        endpoint.recipient = nil // auto stops listening
        usleep(100_000)
    }
    
    // MARK: callback
    private var _clients_ = [String:_Client]() // who has sent messages to me ?
    let _clients_mutex = __mutex__()
    func callback(_ box:String,_ outputs:[Ports.ID:Event]){
        __q__.async{ self.__queued_callback__(box,outputs) }
    }
    let __q__ = DispatchQueue.global(qos:.userInitiated)
    private func __queued_callback__(_ box:String,_ outputs:[Ports.ID:Event]){
        for (i,e) in outputs{
            _clients_mutex.sync{
                for (_,c) in _clients_{
                    for g in c.gets.values.filter({$0.b == box && $0.i == i}){
                        g.event = e
                    }
                }
            }
        }
    }
    
    // MARK: ■ _Client
    private class _Client{
        let addr:EP.Address
        var update = true
        var time = Time.now_s
        var gets = [Message.Token:Get]()
        init(_ addr:EP.Address){ self.addr = addr }
        class Get{
            let b:String // name of box
            let i:String // name of output
            var paused = false
            var event:Event?{ didSet{
                cb(event)
                //if !__equal_valued_events__(oldValue,event){ cb(event) }
            }}
            private let cb:(Event?)->()
            init(_ b:String,_ i:String,_ cb:@escaping(Event?)->()){
                self.b = b
                self.i = i
                self.cb = cb
            }
        }
    }
    
    // MARK: ➤ send
    private func __send__(_ m:Message,to a:EP.Address){
        do{
            try endpoint.send(msg:m,to:a)
        }catch let e{ __log__.err(e.localizedDescription) }
    }
    
    //
    private var _Ω_cache = [IO]()
    
}

extension Device: Message.Recipient{
    
    // MARK: ➤ box
    public func type(ep:EP.Address,box:Device.Box.Name,port:Ports.ID,input:Bool)->T?{
        if let skin = __boxs__[box]?.skin{
            return input ? skin.inputs[port] : skin.outputs[port]
        }
        return nil
    }
    
    // MARK: ➤ receive
    public func received(_ msg:Message,from:EP.Address){
        if case .HANDSHAKE = msg.payload{ __received_handshake__(msg,from) }
        else if let client = _clients_[from.uri]{
            client.time = Time.now_s
            switch msg.payload{
            case .PING: __received_ping__(client,msg,from)
            case .SUBSCRIBE: __received_subscribe__(client,msg,from)
            case .END_SUBSCRIBE: __received_subscribe_update__(client,msg,from)
            case .PUBLISH: __received_publish__(client,msg,from)
            default: break
            }
        }//else{ __log__.warn("\(self.name) received \(msg.payload) msg from unknown client \(from)") }
    }
    
    // MARK: SHK
    private func __received_handshake__(_ m:Message,_ sender:EP.Address){
        __log__.debug("dev: rcvd handshake: \(sender) -> \(endpoint.uri)")
        var c = _clients_[sender.uri]
        //if c == nil{
            c = _Client(sender)
            c!.update = true
            _clients_[sender.uri] = c
        //}
        //c!.update = true
        __send__(m.reply(.HANDSHAKE),to:sender)
    }
    
    // MARK: PNG
    private func __received_ping__(_ c:_Client,_ m:Message,_ sender:EP.Address){
        if c.update{
            let skins = __boxs__.map({$1.skin})
            __send__(m.reply(.PING_UPDATE(name,skins)),to:sender)
        }else{
            __send__(m.reply(.PING),to:sender)
        }
        c.update = false
    }
    
    // MARK: SUB
    private func __received_subscribe__(_ c:_Client,_ m:Message,_ sender:EP.Address){
        if case Message.Payload.SUBSCRIBE(let box_name,let out_name,_) = m.payload{
            __log__.info("SUB: \(box_name).\(out_name)")
            if let box = __boxs__[box_name]{
                if box.skin.outputs[out_name] != nil{
                    if (_clients_mutex.sync{ return c.gets[m.token] == nil }){
                        let g = _Client.Get(box_name,out_name){ [weak self] event in
                            //__log__.info("SUB.callback: \(box_name).\(out_name) -> \(event?.value)")
                            if let ME = self{
                                let e = event ?? Event()
                                let m = m.reply(.SUBSCRIBE(box_name,out_name,e))
                                ME.__send__(m,to:sender)
                            }
                        }
                        _clients_mutex.sync{ c.gets[m.token] = g }
                    }
                }else{ __log__.err("Device.SUBSCRIBE bad out_index (\(out_name))") }
            }else{ __log__.err("Device.SUBSCRIBE bad box-index (\(box_name))") }
        }
    }
    
    // MARK: END
    private func __received_subscribe_update__(_ c:_Client,_ m:Message,_ sender:EP.Address){
        if case Message.Payload.END_SUBSCRIBE = m.payload{
            _clients_mutex.sync({ c.gets[m.token] = nil })
            __send__(m.reply(.END_SUBSCRIBE),to:sender) // ACK
        }
    }
    
    // MARK: PUB
    private func __received_publish__(_ c:_Client,_ m:Message,_ sender:EP.Address){
        if case Message.Payload.PUBLISH(let box_name,let events) = m.payload{
            if __boxs__[box_name] != nil{
                _clock_mux_.sync{
                    var es = _events_to_publish_[box_name] ?? [Ports.ID:Event]()
                    for (i,e) in events{ es[i] = e }
                    _events_to_publish_[box_name] = es
                }
            }else{ __log__.err("Device.PUBLISH no box named '\(box_name)'") }
        }
    }
    
}
private func __equal_valued_events__(_ a:Event?,_ b:Event?)->Bool{
    if let a = a{
        if let b = b{
            if let v = a.value{ return v.equals(b.value) }
            else{ return b.value == nil }
        }else{ return false }
    }else{ return b == nil }
}
