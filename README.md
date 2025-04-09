**[FLO - Distributed Hierarchical Dataflow](https://github.com/kk-0129/Flo)**

Swift package:
# FloBox

The FloBox package contains the most common, low-level data structures and
utilities of the Flo software stack.

The package is divided into 3 functional groups (described in the sections below):
* [Low-Level Logging, Serialisation, Threads and Timing](#logging)
* [Basic Data-Type and Box Definitions](#basics)
* [Remote Device Servers](#devices)

<h2 id="logging"> Low-Level Logging, Serialisation, Threads and Timing</h2>

The following subsections briefly describe low-level utilities for logging, data serialisation,
threads, clocks and timing - all of which are used extensively throughout the Flo application stack.

### Logging

Logging functions throughout the Flo stack are implemented with the Logger protocol, which just comprises 4 methods for printing errors, warnings, debugging or generic information. A default implementation of this protocol, which simply prints all messages to the standard console output, is provided as a global variable `__log__ : Logger` (in `Util.swift`). Developers can replace the default with their own custom implementations.

### Data Serialisation

Data serialisation throughout the Flo stack relies on the `IO` protocol (in `IO.swift`), which just defines methods to write and read bytes to/from a byte sequence (`[UInt8]`). Serialisable structs and classes then implement the associated `IO™` protocol (also in `IO.swift`) to serialise themselves to/from an IO byte stream. Note that the `static` deserialisation method does not throw any errors, with the supplied `IO` argument assumed to be always contain well-formed data. This may change in future versions.

### Threads

The `__thread__` class (in `Util.swift`), is a convenient wrapper for a low-level POSIX 3 thread. Swift Foundation GCD threading classes are also used throughout the application stack, the `__thread__` class oﬀers more scheduling predictability and is used for time-critical operations.

### Clock

The `__clock__` class (in `Util.swift`), is similar to a `__thread__` (above), except that it 
executes its @escaping closure, c, at regular periodic intervals. Clocks can be started, paused
and resumed as needed (by toggling the running variable).

### Times

The `Time` enum (in `Util.swift`) provides access to the current time in diﬀerent forms (seconds, nano-seconds or a timespec combination). It also defines the type-aliases `Interval` (for an interval of time) and `Stamp` (for an instant in time) just to provide some semantic clarity throughout the code.

<h2 id="basics">Basic Data-Type and Box Definitions</h2>

The subsections below define the types of data that can passed along arcs, the events that
encapsulate this data, ports that send and receive events, and the boxes - or rather their outward
facing interface, or "skin" - that exposes these ports.

### Data-Types
TODO

### Events
TODO

### Ports and Box Skins
TODO

<h2 id="devices">Remote Device Servers</h2>

### Boxes
TODO

### Endpoints
TODO

### Messages
TODO

### Devices
TODO





