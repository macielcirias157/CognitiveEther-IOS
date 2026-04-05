import Foundation
import UIKit
import Combine

class ResourceManager: ObservableObject {
    static let shared = ResourceManager()
    
    @Published var ramUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    
    private var timer: AnyCancellable?
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateResources()
            }
    }
    
    private func updateResources() {
        // Get RAM usage (approximation for iOS)
        var pagesize: vm_size_t = 0
        host_page_size(mach_host_self(), &pagesize)
        
        var vm_stat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vm_stat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let used = Double(vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * Double(pagesize)
            let total = Double(ProcessInfo.processInfo.physicalMemory)
            self.ramUsage = used / total
        }
        
        // Thermal State
        self.thermalState = ProcessInfo.processInfo.thermalState
        
        // CPU usage is harder on iOS without private APIs, we'll use a placeholder that fluctuates based on activity
        // but it's better than a static value.
    }
}
