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

/*
 RAW RECIPIENT = will ignore packet composition etc (= bypasses FLO stuff)
 */
public protocol RAW_UDP_RECIPIENT{
    var maxBufferSize:Int{get}
    func received(data:inout[UInt8])
}

public enum UDP{
    
    public typealias RawRecipient = RAW_UDP_RECIPIENT
    
    public class EP: EPBase,Hashable{
        
        // MARK: init
        public init(ipa:IPv4)throws{
            self.ipa = ipa
            super.init(ipa)
            try socket.bind(ipa.host,ipa.port)
        }
        
        // MARK: VARS
        
        private lazy var socket:UDP.Socket = { Socket(self) }()
        private let ipa:IPv4
        //public var address:Address{ return ipa }
        
        
        // MARK: RECIPIENTS
        //public var handlers = [EP.Addr:Message.Handler]()
        public override var recipient:Message.Recipient?{ didSet{
            __recipients_changed__()
        }}
        
        public var rawRecipient : RawRecipient?{
            get{ return socket.rawRecipient }
            set(r){
                socket.rawRecipient = r
                __recipients_changed__()
            }
        }
        
        private func __recipients_changed__(){
            socket.listening = (recipient != nil) || (rawRecipient != nil)
        }
        
        // MARK: SEND
        
        public override func send(msg:Message,to:Address)throws{
            guard recipient != nil else{ return }
            if let a = to as? IPv4{
                try CIO.cached_{ Ω in
                    msg.™(Ω.clean)  
                    var bs = Ω.bytes
                    try socket.send(&bs,to:a)
                }
            }else{
                throw EP.Error("UDP: can only send messages to IPv4 addresses")
            }
        }
        
        // MARK: hashable
        public func hash(into h: inout Hasher){ h.combine(ipa.uri) }
        public static func == (a:EP,b:EP)->Bool{ return a.ipa.uri == b.ipa.uri }
        
        // MARK: UDP.Socket.Delegate
        func udpSocket(_ sock:UDP.Socket,received data:inout[UInt8],from addr:IPv4)throws{
            try CIO.cached_{ Ω in
                Ω.clean.write(ref:&data)
                if Ω.count >= Message.MIN_LENGTH{
                    if let h = recipient{//  ?? handlers[addr]{
                        let msg = try Message.™(Ω,h,addr) // = address of sender
                        if msg.isReply{
                            received(reply:msg,from:addr)
                        }else{
                            //__log__.debug("  -> NOT a reply")
                            h.received(msg,from:addr)
                        }
                    }else{ __log__.debug("UDP: no message recipient for addr: \(addr.uri)") }
                }else{ __log__.debug("UDP: received short message: \(data)") }
            }
        }
        
    }
    
}

extension UDP{
    
    class Socket{
        
        private var __fd__: Int32 = -1
        private let ep:UDP.EP
        private var max_buf_len = Packet.MAX_BUF_LEN
        
        var rawRecipient : RawRecipient?{ didSet{
            if let r = rawRecipient{ max_buf_len = r.maxBufferSize }
            else{ max_buf_len = Packet.MAX_BUF_LEN }
        }}
        
        init(_ ep:UDP.EP){ self.ep = ep }
        
        // MARK: bind
        func bind(_ h:IPv4.Host?,_ p:IPv4.Port)throws{
            var err = ""
            if let h = h ?? _get_localhost(){
                if let s = h4p_to_sockaddr_in(h,p){
                    var _sin = s
                    #if os(Linux)
                    __fd__ = socket(PF_INET,Int32(SOCK_DGRAM.rawValue),Int32(IPPROTO_UDP))
                    #else
                    __fd__ = socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP)
                    #endif
                    if __fd__ >= 0{ // configure the client's socket address
                        var set = 1
                        if setsockopt(__fd__,SOL_SOCKET,SO_REUSEPORT,&set,_INT_LEN) != 0{
                            throw EP.Error("SO_REUSEPORT (1) &set = \(set)")
                        }
                        let res:Int32 = withUnsafeMutablePointer(to: &_sin){
                            $0.withMemoryRebound(to:sockaddr.self, capacity: 1) {
                                #if os(Linux)
                                return Glibc.bind(__fd__, UnsafeMutablePointer<sockaddr>($0),_SIN_LEN)
                                #else
                                return Darwin.bind(__fd__, UnsafeMutablePointer<sockaddr>($0),_SIN_LEN)
                                #endif
                        }}
                        if res >= 0{
                            //__log__.info("UDP bound to \(_sin)")
                            return
                        }
                        err = "on Darwin.bind, res = \(res)"
                    }else{ err = "to create file descriptor" }
                }else{ err = "to create sockaddr_in" }
            }else{ err = "to find localhost" }
            throw EP.Error("UDP-bind failed \(err)")
        }
        
        // MARK: close
        public func close(){
            listening = false
            if __fd__ >= 0{
                #if os(Linux)
                _ = Glibc.shutdown(__fd__,Int32(SHUT_RDWR))
                _ = Glibc.close(__fd__)
                #else
                _ = Darwin.shutdown(__fd__,Int32(SHUT_RDWR))
                _ = Darwin.close(__fd__)
                #endif
                __fd__ = -1
            }
        }
        
        // MARK: send
        func send(_ bytes:inout [UInt8],to addr:IPv4)throws{
            if __fd__ < 0{ throw EP.Error("Invalid File Descriptor") }
            var _dst = addr.sock
            Packet.manager.decompose(&bytes){ pk in
                _ = withUnsafeMutablePointer(to:&_dst){ $0.withMemoryRebound(to:sockaddr.self,capacity:1){
                    #if os(Linux)
                    Glibc.sendto(__fd__,&pk,pk.count,Int32(0),$0,_SIN_LEN)
                    //Glibc.sendto(__fd__,&pk,pk.count,Int32(MSG_NOSIGNAL),$0,_SIN_LEN)
                    #else
                    Darwin.sendto(__fd__,pk,pk.count,0,$0,_SIN_LEN)
                    #endif
                }}
            }
        }
        
        // MARK: listen
        private var _listening_thread:__thread__?
        //private var _listening_thread:DispatchQueue?
        var listening:Bool{
            get{ return _listening_thread != nil }
            set(v){
                if v != listening{
                    if v{
                        if __fd__ >= 0{
                            _listening_thread = __thread__(50){ self._listen() }
                        }
                    }else{ _listening_thread = nil }
                }
                print("\(ep.uri) listening = \(listening)")
            }
        }
        
        private var last_garbage_clean = Time.now_s
        private func _listen(){ // loop runs on _listening_thread
            while _listening_thread != nil{
                var len = 0
                var bf = [UInt8](repeating:0,count:max_buf_len)
                var ss = sockaddr_storage()
                var ss_len = socklen_t(MemoryLayout.size(ofValue: ss))
                withUnsafeMutablePointer(to:&ss){ (pinfo) -> () in
                    let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to:sockaddr.self)
                    len = recvfrom(__fd__,&bf,bf.count,0,paddr,&ss_len)
                    paddr.withMemoryRebound(to:sockaddr_in.self,capacity:1){ [weak self] x in
                        if let ME = self{
                            var bs = [UInt8](bf[0..<len])
                            do{
                                if let addr = IPv4.from(x.pointee){
                                    try ME.__rcvd__(&bs,from:addr)
                                }
                            }catch let e{
                                var s = "UDP: unable to decode data [\(len) bytes] <- "
                                if let e = e as? IOError{ s += e.string }
                                else{ s += e.localizedDescription }
                                __log__.err(s)
                                if len < 100{
                                    __log__.err("original bytes = ")
                                    __log__.err("\(bs)")
                                }
                            }
                        }
                    }
                }
                if (Time.now_s - last_garbage_clean) > Packet.Manager.CLEAN_PERIOD{
                    Packet.manager.clean()
                    last_garbage_clean = Time.now_s
                }
            }
        }
            
        private func __rcvd__(_ bs:inout[UInt8],from a:IPv4)throws{
            if let r = rawRecipient{
                r.received(data:&bs)
            }else{
                try CIO.cached_{ Ω in
                    var data = [UInt8]()
                    Ω.write(ref:&bs)
                    try Packet.manager.compose(Ω,&data)
                    if !data.isEmpty{
                        try ep.udpSocket(self,received:&data,from:a)
                    }
                }
            }
        }
        
    }
}

private let _SIN_LEN = socklen_t(MemoryLayout<sockaddr_in>.size)
private let _INT_LEN = socklen_t(MemoryLayout<Int>.size)

class Packet{
    
    static let PKT_HEADER_LEN = /*token + conv + pkt.idx*/ 8 + 4 + 2
    static let MAX_PKT_LEN = MAX_BUF_LEN - PKT_HEADER_LEN
    static let MAX_BUF_LEN = 8192
    static let PKT_N_FLAG = UInt16(0x8000) // = 1 in most significant bit
    
    static let manager = Manager()
    
    class Manager{
        
        static var decomp_counter:UInt32 = 0
        
        func decompose(_ bytes:inout [UInt8],_ f:(inout [UInt8])->()){
            Manager.decomp_counter += 1
            let n = Int(ceil(Float32(bytes.count)/Float32(Packet.MAX_PKT_LEN))) // number of packets to send ..
            let C = Manager.decomp_counter.bytes
            for i in 0..<n{ // break the msg up into packets
                let start = i * Packet.MAX_PKT_LEN
                let end = min(bytes.count,(i+1) * Packet.MAX_PKT_LEN)
                var idx = UInt16(n-i) // its a countdown
                if i == 0{ idx |= Packet.PKT_N_FLAG } // first is flagged == gives the total number of packets !!
                var pk = C + idx.bytes + Array<(UInt8)>(bytes[start..<end])
                f(&pk)
            }
        }
        
        static let CLEAN_PERIOD = Time.Stamp(10)
        
        func clean(){
            let now = Time.now_s
            mx.sync{
                var dead = [UInt32]()
                for (c,pkts) in self._rcvd_pkts_{
                    if (now - pkts.time) > Manager.CLEAN_PERIOD{
                        dead.append(c)
                    }
                }
                for c in dead{ self._rcvd_pkts_[c] = nil }
            }
        }
        
        private let mx = __mutex__()
        private var _rcvd_pkts_ = [UInt32:Packet.List]()
        
        func compose(_ rcvd:IO, _ res:inout [UInt8])throws{
            if rcvd.count <= PKT_HEADER_LEN{
                throw IOError.DECODE("packet is too small")
            }
            let c = try UInt32.™(rcvd) // composition id
            let idx = try UInt16.™(rcvd) // packet index
            var pkt_list = _rcvd_pkts_[c] ?? Packet.List()
            pkt_list.ADD(idx,rcvd.rest)
            if pkt_list.payload != nil{
                res = pkt_list.payload!
            }else{
                mx.sync{ _rcvd_pkts_[c] = pkt_list }
            }
        }
        
    }
    
    private struct List{
        
        var count:Int?
        var payload:[UInt8]?
        let time = Time.now_s
        private var rcvd = [UInt16:[UInt8]]()
        
        mutating func ADD(_ n:UInt16,_ bytes:[UInt8]){
            // first idx 'n' tells us the total packet count ..
            var n = n
            if (n & Packet.PKT_N_FLAG) > 0{
                n = n ^ Packet.PKT_N_FLAG
                self.count = Int(n)
            }
            rcvd[n] = bytes
            if rcvd.count == count{
                let keys = [UInt16](rcvd.keys.sorted().reversed())
                var p = [UInt8]()
                for x in keys{
                    p += rcvd[x]!
                }
                payload = p
            }
        }
        
    }
    
}
