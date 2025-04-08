// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation

public typealias HOST_AND_PORT = String
public typealias IPv4Host = (UInt8,UInt8,UInt8,UInt8)

public struct IPv4:EP.Address,Hashable{
    
    public static var kind = "ipv4"
    
    public typealias Port = UInt16
    public typealias Host = (UInt8,UInt8,UInt8,UInt8)
    
    init(_ h:Host,_ p:Port,_ s:sockaddr_in){
        host = h
        port = p
        sock = s
    }
    
    // MARK: VARS
    public let host:Host
    public let port:Port
    let sock:sockaddr_in
    public var islocal : Bool{ return IPv4.localhost != nil && host == IPv4.localhost! }
    
    private static var __local__ : (Bool,IPv4.Host?)?
    private static var localhost:IPv4.Host?{
        if __local__ == nil{ __local__ = (true,_get_localhost()) }
        return __local__?.1
    }
    
    public static func from(_ s:String)->IPv4?{
        let xs = s.components(separatedBy:":")
        if xs.count == 2,let p = UInt16(xs[1]){
            if xs[0] == "local"{ return local(port:p) }
            return from(xs[0],p)
        }else{ return nil }
    }
    
    public static func from(_ h:String,_ p:Port)->IPv4?{
        if let h = h.ip4host{ return from(h,p) }
        else{ return nil }
    }
    
    public static func local(port:Port)->IPv4?{ return from(nil,port) }
    private static func __from__(_ h:Host?,_ p:Port,_ l:Bool)->IPv4?{
        if let h = h ?? _get_localhost(), let s = h4p_to_sockaddr_in(h,p){
            return IPv4(h,p,s)
        }else{ return nil }
    }
    public static func from(_ h:Host?,_ p:Port)->IPv4?{
        if let h = h ?? localhost, let s = h4p_to_sockaddr_in(h,p){
            return IPv4(h,p,s)
        }else{ return nil }
    }
    static func from(_ s:sockaddr_in)->IPv4?{
        if let (h,p) = sockaddr_in_to_h4p(s){
            return IPv4(h,p,s)
        }else{ return nil }
    }
    
    public var uri:String{
        return islocal ? "local:\(port)" : "\(host.0).\(host.1).\(host.2).\(host.3):\(port)"
    }
    
    public func hash(into h: inout Hasher){ h.combine(uri) }
    public static func == (a:IPv4,b:IPv4)->Bool{ return a.uri == b.uri }
    
}

// MARK: HELPERS
private extension String{
    var ip4host:IPv4.Host?{
        if self == "local"{ return _get_localhost() }
        let xs = components(separatedBy:".").compactMap({UInt8($0)})
        return xs.count == 4 ? (xs[0],xs[1],xs[2],xs[3]) : nil
    }
}

func h4p_to_sockaddr_in(_ h:IPv4.Host,_ p:IPv4.Port)->sockaddr_in?{
    var sa = sockaddr_in()
    sa.sin_family = sa_family_t(AF_INET)
    sa.sin_port = in_port_t( p.byteSwapped )
    var buffer:[Int8] = Array("\(h.0).\(h.1).\(h.2).\(h.3)".utf8CString)
    return inet_aton(&buffer,&sa.sin_addr) > 0 ? sa : nil
}

func sockaddr_in_to_h4p(_ s:sockaddr_in)->(IPv4.Host,IPv4.Port)?{
    var a = s
    let n = Int(INET_ADDRSTRLEN)
    var bf = [CChar](repeating:0,count:n)
    inet_ntop(Int32(a.sin_family),&a.sin_addr,&bf,socklen_t(n))
    let p = IPv4.Port( a.sin_port.byteSwapped )
    let s = String(validatingUTF8:bf)!.components(separatedBy:".")
    return ((UInt8(s[0])!,UInt8(s[1])!,UInt8(s[2])!,UInt8(s[3])!),p)
}


// MARK: ■ LocalHost
#if os(Linux)
func _get_localhost()->(UInt8,UInt8,UInt8,UInt8)?{ return nil }
#else
func _get_localhost()->IPv4.Host?{
    var addresses = [String]()
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil  }
    guard let firstAddr = ifaddr else { return nil  }
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        let addr = ptr.pointee.ifa_addr.pointee
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING){
            if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6){
                var hostname = [CChar](repeating: 0, count:Int(NI_MAXHOST))
                if (getnameinfo(ptr.pointee.ifa_addr,socklen_t(addr.sa_len),&hostname,socklen_t(hostname.count),nil,socklen_t(0),NI_NUMERICHOST) == 0) {
                    let address = String(cString: hostname)
                    addresses.append(address)
                }}}}
    freeifaddrs(ifaddr)
    for a in addresses{ if let h = a.ip4host{ return h } }
    return nil
}
#endif
