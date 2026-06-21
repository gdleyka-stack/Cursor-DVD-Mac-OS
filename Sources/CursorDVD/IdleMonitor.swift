import Foundation
import IOKit

public struct IdleMonitor {
    /// Returns the system idle time (time since last user activity: mouse, keyboard) in seconds.
    public static func getSystemIdleTime() -> Double {
        var iterator: io_iterator_t = 0
        // In macOS, kIOMainPortValue is the modern equivalent of kIOMasterPortDefault
        let service = IOServiceGetMatchingService(0, IOServiceMatching("IOHIDSystem"))
        
        guard service != 0 else {
            return 0.0
        }
        
        defer {
            IOObjectRelease(service)
        }
        
        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &unmanagedDict, kCFAllocatorDefault, 0)
        
        guard result == KERN_SUCCESS, let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] else {
            return 0.0
        }
        
        if let idleTimeNs = dict["HIDIdleTime"] as? Int64 {
            return Double(idleTimeNs) / 1_000_000_000.0
        }
        
        return 0.0
    }
}
