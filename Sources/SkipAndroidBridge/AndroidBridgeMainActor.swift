// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP
#if os(Android)
import AndroidLooper

// this mechanism overrides the MainActor with an AndroidMainActor that uses the Looper API to enqueue events
public typealias MainActor = AndroidMainActor

#endif
#endif
