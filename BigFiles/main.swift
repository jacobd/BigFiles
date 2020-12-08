//
//  main.swift
//  BigFiles
//
//  Created by Jacob DeHart on 12/5/20.
//

import Foundation
import ArgumentParser


// What we keep track of when indexing files
struct BigFile: Hashable {
    var name: String
    var size: Int
    var fileType: String
}
// Array of all files, limited to --number option


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

    let number = NSNumber(value: size)
    let formattedValue = formatter.string(from: number)!
    
    return "\(formattedValue)\(suffix[suffixIndex])"
    
}


func analyzePath(path: URL, human: Bool, number: Int) {
    let startTime = Date().timeIntervalSince1970
    let localFileManager = FileManager()
    
    let resourceKeys = Set<URLResourceKey>([.pathKey, .isDirectoryKey, .fileSizeKey, .fileResourceTypeKey])
    let directoryEnumerator = localFileManager.enumerator(at: path, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)
    
    var totalFiles = 0
    var totalFileSize = 0
    var allFiles: [BigFile] = []
    
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
    
    struct Summary {
        var type: String
        var count: Int
        var size: Int
    }
    var grouped: [String: Summary] = [:]
    
    for file in allFiles {
        let ext = file.fileType.isEmpty ? "No Extension" : file.fileType
        var summary = grouped[ext] ?? Summary(type: ext, count: 0, size: 0)
        summary.count += 1
        summary.size += file.size
        grouped[ext] = summary
    }
    

    
    let totalTime = Date().timeIntervalSince1970 - startTime
    print("Total File Checked: \(totalFiles) in \(String(format: "%.3f",totalTime)) seconds")
    print("Total Size in Path: \(humanReadable(totalFileSize))\n")
    
    print("Top \(number) file types")
    for summary in (grouped.sorted { $0.value.size > $1.value.size }).prefix(number) {
        let perc = Int(100 * Double(summary.value.size) / Double(totalFileSize))
        print("\(humanReadable(summary.value.size)) (\(perc)%)\t\(summary.value.type)\t\(summary.value.count) file(s) ")
    }
    print("\n")
    
    allFiles.sort { $0.size > $1.size }
    
    print("Top \(number) files")
    for file in allFiles.prefix(number) {
        var size: String
        if true || human {
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
        analyzePath(path: URL(fileURLWithPath: (path ?? FileManager.default.currentDirectoryPath)),
                   human: human,
                   number: number)
        
    }
}

BigFiles.main()
