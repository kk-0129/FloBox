**[FLO - Distributed Hierarchical Dataflow](https://github.com/kk-0129/Flo)**

Swift package:
# FloBox

The FloBox package contains the most common, low-level data structures and
utilities of the Flo software stack.

The package is divided into 3 functional groups (described in the sections below):
1. [Low-Level Logging, Serialisation, Threads and Timing](#logging)
2. [Basic Data-Type and Box Definitions](#basics)
3. [Remote Device Servers](#devices)

<h2 id="logging">1) Low-Level Logging, Serialisation, Threads and Timing</h2>

The following subsections briefly describe low-level utilities for logging, data serialisation,
threads, clocks and timing - all of which are used extensively throughout the Flo application stack.

### 1.1) Logging

Logging functions throughout the Flo stack are implemented with the Logger protocol, which just comprises 4 methods for printing errors, warnings, debugging or generic information. A default implementation of this protocol, which simply prints all messages to the standard console output, is provided as a global variable `__log__ : Logger` (in `Util.swift`). Developers can replace the default with their own custom implementations.

### 1.2) Data Serialisation

Data serialisation throughout the Flo stack relies on the `IO` protocol (in `IO.swift`), which just defines methods to write and read bytes to/from a byte sequence (`[UInt8]`). Serialisable structs and classes then implement the associated `IO™` protocol (also in `IO.swift`) to serialise themselves to/from an IO byte stream. Note that the `static` deserialisation method does not throw any errors, with the supplied `IO` argument assumed to be always contain well-formed data. This may change in future versions.

### 1.3) Threads

The `__thread__` class (in `Util.swift`), is a convenient wrapper for a low-level POSIX 3 thread. Swift Foundation GCD threading classes are also used throughout the application stack, the `__thread__` class oﬀers more scheduling predictability and is used for time-critical operations.

### 1.4) Clock

The `__clock__` class (in `Util.swift`), is similar to a `__thread__` (above), except that it 
executes its @escaping closure, c, at regular periodic intervals. Clocks can be started, paused
and resumed as needed (by toggling the `running` variable).

### 1.5) Times

The `Time` enum (in `Util.swift`) provides access to the current time in diﬀerent forms (seconds, nano-seconds or a timespec combination). It also defines the type-aliases `Interval` (for an interval of time) and `Stamp` (for an instant in time) just to provide some semantic clarity throughout the code.

<h2 id="basics">2) Basic Data-Type and Box Definitions</h2>

The subsections below define the types of data that can passed along arcs, the events that
encapsulate this data, ports that send and receive events, and the boxes - or rather their outward
facing interface, or "skin" - that exposes these ports.

### 2.1) Data-Types
Flo supports 6 data types:
* `BOOL` : for Boolean (true or false) values
* `FLOAT` : for 32-bit floating point numeric values
* `STRING` : for unicode character sequences
* `DATA` : an opaque (i.e. uninterpreted) sequence of bytes
* `ARRAY`: an array of a specific primitive (BOOL, FLOAT or STRING) or STRUCT type
* `STRUCT`: a user-specified (key-value) dictionary of named types.

These data types are defined as cases in an `enum` called `T` (in `Events`/`T.swift`, where "T" stands for "type", but abbreviated to avoid any confusion with the built-in Swift type `Type`). Instances of `BOOL`, `DATA`, `FLOAT`, `STRING` and `ARRAY` are respectively instances of the corresponding Swift
language types `Bool`, `Data`, `Float`, `String` and `Array`. A `STRUCT` instance, however, must be
an instance of the FLo-defined struct `Struct` (in  `Events`/`Struct.swift`) - which can be constructed by supplying the name of the `STRUCT` type together with values for all its data members, e.g. 

    let s = Struct("XY",["x":2.3,"y":4.5])
.. will create the following STRUCT instance:

    s = XY{
          x = 2.3,
          y = 4.5
        }

The `Struct` struct provides subscript access to the values of its data members, e.g. (with `s`
defined as above):
* `s["x"]` returns the value `2.3`
* `s["y"]` returns the value `4.5`

The following `Struct` instances are predefined: 

    // a null struct    
    public let NIL = T.STRUCT("nil",[:]) 
    // for 2D (x,y) coordinates
    public let XY = T.STRUCT("XY",["x":.FLOAT(),"y":.FLOAT()])
    // for 3D (x,y,z) coordinates
    public let XYZ = T.STRUCT("XYZ",["x":.FLOAT(),"y":.FLOAT(),"z":.FLOAT()])
    // for Euler angles
    public let EULER = T.STRUCT("Euler",["pitch":.FLOAT(),"yaw":.FLOAT(),"roll":.FLOAT()])
    // for quaternions
    public let QUAT = T.STRUCT("Quat",["angle":.FLOAT(),"axis":XYZ])
    // for Date/Time values
    public let DATE = T.STRUCT("Date",["year":.FLOAT(),"month":.FLOAT(),"day":.FLOAT(),
                                "hour":.FLOAT(),"min":.FLOAT(),"sec":.FLOAT()])

All `STRUCT` types are automatically (on construction) added to a global registry, which can be accessed through `static` variable on type `Struct`:

    extension Struct{
        static var types:[String:T] // returns all registered Struct types
    }

### 2.2) Events
The preceding section described the types of data that can be sent along dataflow arcs. For a
couple of reasons (explained below), this data is not sent 'raw', but is instead wrapped inside a
struct called an `Event` (defined in [Events/Event.swift](Sources/FloBox/Events/Event.swift))

### 2.3) Ports and Box Skins
TODO

<h2 id="devices">3) Remote Device Servers</h2>

### Boxes
TODO

### Endpoints
TODO

### Messages
TODO

### Devices
TODO





