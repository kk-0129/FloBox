// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import Collections

// MARK: Ports
/*
 The ONLY reason this is ordered is so that
 inputs/outputs appear 'ordered' in 2D boxes
 */
public typealias Ports = OrderedDictionary<String,T>

extension OrderedDictionary:IO™ where Key == String, Value == T{
    
    public static func from(_ ports:Ports)->Ports{ return ports } 
    
    public typealias ID = String
    
    public typealias IDX = Int8
    public func ™(_ Ω:IO){
        UInt8(count).™(Ω)
        for (k,v) in self{ k.™(Ω); v.™(Ω) }
    }
    public static func ™(_ Ω:IO)throws->Ports{
        var res = Ports()
        let n = try UInt8.™(Ω)
        for _ in 0..<n{ res[try Key.™(Ω)] = try Value.™(Ω) }
        return res
    }
    
}
