// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation

public struct Combo : EP.Address{
    public static let kind = "COMBO"
    public init(_ x:[EP.Address]){
        let s = x.isEmpty ? "‹unknown uri›" : x[0].uri
        uri = x.count > 1 ? s + "…" : s
        eps = x
    }
    public let eps:[EP.Address]
    public let uri:String
}
