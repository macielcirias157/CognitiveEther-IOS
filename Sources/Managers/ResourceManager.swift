import Foundation
import UIKit
import Combine
import Darwin

final class ResourceManager: ObservableObject {
    static let shared = ResourceManager()

    @Published var ramUsage: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var inferenceSamples: [Double] = []
    @Published var lastInference: AIResponseMetrics = .empty

    private var timer: AnyCancellable?

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateResources()
            }
    }

    func recordInference(_ metrics: AIResponseMetrics) {
        lastInference = metrics
        inferenceSamples.append(metrics.estimatedTokensPerSecond)
        if inferenceSamples.count > 12 {
            inferenceSamples.removeFirst(inferenceSamples.count - 12)
        }
    }

    private func updateResources() {
        ramUsage = currentRAMUsage()
        cpuUsage = currentCPUUsage()
        thermalState = ProcessInfo.processInfo.thermalState
    }

    private func currentRAMUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )

        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard status == KERN_SUCCESS else { return ramUsage }

        let used = Double(info.resident_size)
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return 0 }
        return min(max(used / total, 0), 1)
    }

    private func currentCPUUsage() -> Double {
        var threadsList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let taskResult = task_threads(mach_task_self_, &threadsList, &threadCount)
        guard taskResult == KERN_SUCCESS, let threadsList else { return cpuUsage }

        defer {
            let size = vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), size)
        }

        var totalUsage: Double = 0

        for index in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(
                        threadsList[index],
                        thread_flavor_t(THREAD_BASIC_INFO),
                        $0,
                        &threadInfoCount
                    )
                }
            }

            guard infoResult == KERN_SUCCESS else { continue }
            if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE)
            }
        }

        return min(max(totalUsage, 0), 1)
    }
}
