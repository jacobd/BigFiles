//
//  main.swift
//  BigFiles
//
//  Created by Jacob DeHart on 12/5/20.
//

import Foundation
import ArgumentParser

protocol FileProperty: Comparable {
    var size: Int { get set }
}
struct BigFile: FileProperty {
    var name: String
    var size: Int
    var fileType: String
}
struct TypeSummary: FileProperty {
    var type: String
    var count: Int
    var size: Int
}
extension FileProperty {
    static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.size > rhs.size
    }
}

func humanReadable(_ bytes: Int) -> String {
    let suffix = ["B", "K", "M", "G", "T", "P", "E"]
    var suffixIndex = 0
    var size = Double(bytes)
    for _ in 0..<suffix.count - 1 {
        if size > 1024 {
            suffixIndex += 1
            size = size / 1024
        }
    }

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1

    let formattedValue = formatter.string(from: NSNumber(value: size)) ?? "0"
    
    return "\(formattedValue)\(suffix[suffixIndex])"
    
}


func analyzePath(path: URL) -> (
        totalFiles: Int,
        totalTime: Double,
        totalFileSize: Int,
        summary: Array<TypeSummary>,
        files: Array<BigFile>) {
    
    let startTime = CFAbsoluteTimeGetCurrent()
    var totalFiles = 0
    var totalFileSize = 0
    var allFiles: [BigFile] = []
    
    let localFileManager = FileManager()
    let resourceKeys = Set<URLResourceKey>([.pathKey, .isDirectoryKey, .fileSizeKey, .fileResourceTypeKey])
    let directoryEnumerator = localFileManager.enumerator(at: path, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)
    
    while let fileURL = directoryEnumerator?.nextObject() as? URL {
        guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
            let isDirectory = resourceValues.isDirectory,
            let name = resourceValues.path,
            let size = resourceValues.fileSize
            else {
                continue
        }
        
        if isDirectory {
            if name == "_extras" {
                directoryEnumerator?.skipDescendants()
            }
        } else {
            totalFiles += 1
            totalFileSize += size
            allFiles.append(BigFile(name: name, size: size, fileType: fileURL.pathExtension))
        }
    }
    allFiles.sort()
    
    var grouped: [String: TypeSummary] = [:]
    for file in allFiles {
        let ext = file.fileType.isEmpty ? "No Extension" : file.fileType
        var summary = grouped[ext] ?? TypeSummary(type: ext, count: 0, size: 0)
        summary.count += 1
        summary.size += file.size
        grouped[ext] = summary
    }
    
    let totalTime = CFAbsoluteTimeGetCurrent() - startTime
    let summary = Array(grouped.values.sorted())

    return (totalFiles, Double(totalTime), totalFileSize, summary, allFiles)
}


func renderAnalysis(totalFiles: Int, totalTime: Double, totalFileSize: Int, summary: Array<TypeSummary>, files: Array<BigFile>, human: Bool, number: Int) {
    
    let files = files.prefix(number)
    let summary = summary.prefix(number)
    
    print("Total File Checked: \(totalFiles) in \(String(format: "%.3f",totalTime)) seconds")
    print("Total Size in Path: \(humanReadable(totalFileSize))\n")
    print("Top \(summary.count) file types")
    
    for summ in summary {
        let perc = Int(100 * Double(summ.size) / Double(totalFileSize))
        print("\(humanReadable(summ.size)) (\(perc)%)\t\(summ.type)\t\(summ.count) file(s) ")
    }
    print("\n")

    print("Top \(files.count) files")
    for file in files {
        var size: String
        if human {
            size = humanReadable(file.size)
        } else {
            size = String(file.size)
        }
        let perc = Int(100 * Double(file.size) / Double(totalFileSize))
        print("\(size) (\(perc)%)\t\(file.fileType)\t\(file.name)")
    }
}

struct BigFiles: ParsableCommand {
    
    @Flag(help: "human readable format")
    var human = false
    
    @Option(name: .shortAndLong, help: "The number of files to display.")
    var number = 10
    
    @Argument(help: "The path to search")
    var path: String?
    
    mutating func run() throws {
        let analysis = analyzePath(path: URL(fileURLWithPath: (path ?? FileManager.default.currentDirectoryPath)))
        
        renderAnalysis(
            totalFiles: analysis.totalFiles,
            totalTime: analysis.totalTime,
            totalFileSize: analysis.totalFileSize,
            summary: analysis.summary,
            files: analysis.files,
            human: human,
            number: number
        )
    }
}

BigFiles.main()
