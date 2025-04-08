import XCTest
@testable import FloBox

final class FloBoxTests: XCTestCase {
    
    func testEvenetSerialisation(){
        print("TESTING Event.™")
        let bytes = [UInt8](repeating:12,count:10_000)
        let d1 = Data(bytes)
        let e1 = Event(d1)
        CIO.cached{ Ω in
            e1.™(Ω) // serialises the event
            do{
                _ = try Event.™(Ω,.DATA)
            }catch let e{
                XCTFail()
            }
        }
    }
    
    func testPacketDecomp() throws {
        for _ in 0..<2{
            XCTAssert(try __pkt_decomp__())
        }
    }
    
    func __pkt_decomp__()throws->Bool{
        var input = __rnd_data__()
        print("generated input data with \(input.count) bytes")
        var pkts = [[UInt8]]()
        var output = [UInt8]()
        Packet.manager.decompose(&input,0){ pkt in pkts.append(pkt) }
        print("decomposed to \(pkts.count) packets")
        for var pkt in pkts{
            try CIO.cached_{ Ω in
                Ω.clean.write(ref:&pkt)
                try Packet.manager.compose(Ω,&output,"TEST")
            }
        }
        print("output has \(output.count) bytes")
        if !output.isEmpty{
            return output == input
        }
        return false
    }
    
    func __rnd_data__()->[UInt8]{
        var data = [UInt8]()
        for i in 0..<15000{
            data.append(UInt8.random(in:0..<UInt8.max))
        }
        return data
    }
    
}
