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

// MARK: __log__
public func __FLOG__(_ s:String){ Swift.print(s) } // forced log
public var __log__: Logger{
    get{ return __log_mx__.sync{ __the_log__ } }
    set(v){ __log_mx__.sync{ __the_log__ = v } }
}
private let __log_mx__ = __mutex__()
private var __the_log__: Logger = _DefaultLog()

/// Abstract logging functions
public protocol Logger{
    var on:Bool{get set}
    func info(_ m:String)
    func debug(_ m:String)
    func warn(_ m:String)
    func err(_ m:String)
}

private struct _DefaultLog:Logger{
    var on:Bool = true
    func info(_ m:String){ __print("<info>",m) }
    func debug(_ m:String){ __print("<debug>",m) }
    func warn(_ m:String){ __print("<warn>",m) }
    func err(_ m:String){ __print("<err>",m) }
    private func __print(_ s:String,_ m:String){ print("\(s) \(m)") }
}

// MARK: ■ __mutex__
public struct __mutex__{
    public init(){}
    private let semaphore = DispatchSemaphore(value:1) // only one process allowed
    public func sync<R>(_ b:()->R)->R{
        semaphore.wait()
        defer{ semaphore.signal() }
        return b()
    }
}

// MARK: Time
extension timespec: @retroactive Equatable{
    public static func ==(a:timespec,b:timespec)->Bool{
        return a.tv_sec == b.tv_sec && a.tv_nsec == b.tv_nsec
    }
}
private var __t__ = timespec(tv_sec:0,tv_nsec:0)
public enum Time{
    public typealias Interval = Float64
    public typealias Stamp = Float64
    public static var now_s:Stamp{ // seconds
        let t = now_t
        return Float64(t.tv_sec) + (Float64(t.tv_nsec) * 0.000000001)
    }
    public static var now_t:timespec{
        clock_gettime(CLOCK_REALTIME,&__t__)
        return __t__
    }
    public static var now_n:Int64{ // nano-seconds
        let t = now_t
        return (Int64(t.tv_sec) * Int64(1_000_000_000)) + Int64(t.tv_nsec)
    }
}

// MARK: ■ __thread__
/// Posix thread wrapper
public class __thread__{
    //public enum Priority: Int32{ case CLOCK = 99, SEND = 75, LISTEN = 50 }
    #if os(Linux)
    private static let PCD = Int32(PTHREAD_CREATE_DETACHED)
    private var pthread: pthread_t = 0
    #else
    private static let PCD = PTHREAD_CREATE_DETACHED
    private var pthread: pthread_t
    #endif
    // old priorities: CLOCK = 99, SEND = 75, LISTEN = 50
    /*
     The @escaping closure, c (passed to the initialiser), can contain any code, which
     will be executed once only, within a unique POSIX thread, immediately upon instantiation.
     */
    public init(_ priority:UInt8,_ c: @escaping ()->()){
        let h = Unmanaged.passRetained(__thread__.Closure(c))
        let p = UnsafeMutableRawPointer(h.toOpaque())
        var attr = pthread_attr_t()
        pthread_attr_init(&attr)
        pthread_attr_setdetachstate(&attr,__thread__.PCD)
        pthread_attr_setschedpolicy(&attr, SCHED_RR)
        #if os(Linux)
        var schedule = sched_param(sched_priority: Int32(priority))
        pthread_attr_setschedparam(&attr, &schedule)
        guard pthread_create(&pthread,&attr,_LINUX_PTR_,p) == 0 else{ h.release(); abort() }
        #else
        var schedule = sched_param(sched_priority: Int32(priority), __opaque:(0,0,0,0))
        pthread_attr_setschedparam(&attr, &schedule)
        var pt: pthread_t?
        guard pthread_create(&pt,&attr,_PTR_,p) == 0 && pt != nil else{ h.release(); abort() }
        pthread = pt!
        #endif
    }
    func kill(){ pthread_cancel(pthread) }
    deinit{ _ = pthread_detach(pthread) }
    fileprivate class Closure{ let c:()->(); init(_ c:@escaping ()->()){ self.c = c } }
}
#if os(Linux)
private func _LINUX_PTR_(arg:UnsafeMutableRawPointer?)->UnsafeMutableRawPointer?{
    return arg != nil ? _PTR_(arg!) : nil
}
#endif
private func _PTR_(_ arg:UnsafeMutableRawPointer)->UnsafeMutableRawPointer?{
    let h = Unmanaged<__thread__.Closure>.fromOpaque(arg)
    h.takeUnretainedValue().c()
    h.release()
    return nil
}

// MARK: ■ __parallel__
public func __parallel__(_ n:Int,_ f:(Int)->()){
    if n > 10{ DispatchQueue.concurrentPerform(iterations:n){ i in f(i) } }
    else{ for i in 0..<n{ f(i) } }
}

// MARK: __clock__
public class __clock__{
    
    private let _interval:Int64 // in micro seconds = 0.000,001
    private let _callback: ()->()
    /*
    Similar to a `__thread__` (above), except that clocks execute the @escaping closure, c, at regular
    periodic intervals. Clocks can be started, paused and resumed as needed (by toggling the running variable).
    */
    public convenience init(ms:UInt64,_ cb: @escaping ()->()){ self.init(µs:ms*1000,cb) }
    public init(µs:UInt64,_ cb: @escaping ()->()){ // in micro seconds = 0.000,001
        _interval = Int64(µs) * 1000
        _callback = cb
        pthread_mutex_init(&_mutex, nil)
        pthread_cond_init(&_cond, nil)
    }
    private var _mutex = pthread_mutex_t()
    private var _cond = pthread_cond_t()
    private var _millisecond_clock_thread, _responder_thread: __thread__?
    private var _tick = false
    public var running = false{ didSet{ if running != oldValue{
        if running{ // SIMPLE CLOCK - TICKS ONCE EVERY MILLISECOND (MORE OR LESS)
            _millisecond_clock_thread = __thread__(99){ [weak self] in
                var next = Time.now_n
                while let ME = self, ME.running{
                    pthread_mutex_lock(&ME._mutex)
                    next += (((Time.now_n - next)/ME._interval) + 1) * ME._interval
                    ME._tick = true
                    pthread_cond_signal(&ME._cond)
                    pthread_mutex_unlock(&ME._mutex)
                    usleep( useconds_t(max(0,Float32(next - Time.now_n) * 0.001)) )
            }} // RESPONDER THREAD LOOP ITERATES ONCE FOR EACH CLOCK TICK ..
            _responder_thread = __thread__(75){ [weak self] in
                while let ME = self, ME.running{
                    pthread_mutex_lock(&ME._mutex)
                    while !ME._tick{ pthread_cond_wait(&ME._cond,&ME._mutex) }
                    ME._callback()
                    ME._tick = false
                    pthread_mutex_unlock(&ME._mutex)
            }}
        }else{
            _millisecond_clock_thread?.kill()
            _millisecond_clock_thread = nil
            _responder_thread?.kill()
            _responder_thread = nil
        }
    }}}
    
}
