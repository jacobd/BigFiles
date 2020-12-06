//
//  main.swift
//  BigFiles
//
//  Created by Jacob DeHart on 12/5/20.
//

import Foundation
import ArgumentParser


// What we keep track of when indexing files
struct BigFile {
    var name: String
    var size: Int
}
// Array of all files, limited to --number option



struct BigFiles: ParsableCommand {
    
    @Flag(help: "Show each file analyzed")
    var verbose = false
    
    @Flag(help: "human readable format")
    var human = false
    
    @Option(name: .shortAndLong, help: "The number of files to display.")
    var number = 10
    
    @Argument(help: "The path to search")
    var path: String?
    
    // Verbose logger helper function to only print when verbsose is on
    func vlog(msg: String) {
        if verbose {
            print(msg)
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

        let number = NSNumber(value: size)
        let formattedValue = formatter.string(from: number)!
        
        return "\(formattedValue)\(suffix[suffixIndex])"
        
    }
    
    mutating func run() throws {
        let cwd = FileManager.default.currentDirectoryPath
        let startTime = Date().timeIntervalSince1970
         
        let directoryURL = URL(fileURLWithPath: (path ?? cwd))
        let localFileManager = FileManager()
         
        let resourceKeys = Set<URLResourceKey>([.pathKey, .isDirectoryKey, .fileSizeKey])
        let directoryEnumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
        
        var totalFiles = 0
        var allFiles: [BigFile] = []
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let isDirectory = resourceValues.isDirectory,
                let name = resourceValues.path,
                let size = resourceValues.fileSize
                else {
                    continue
            }
            
            if isDirectory {
                if name == "_extras" {
                    directoryEnumerator.skipDescendants()
                }
            } else {
                totalFiles += 1
                allFiles.append(BigFile(name: name, size: size))
            }
        }
         
        let totalTime = Date().timeIntervalSince1970 - startTime
        print("Total File Checked: \(totalFiles) in \(String(format: "%.3f",totalTime)) seconds\n")
        
        allFiles.sort { $0.size > $1.size }
        
        for file in allFiles.prefix(number) {
            var size: String
            if human {
                size = humanReadable(file.size)
            } else {
                size = String(file.size)
            }
            print("\(size)\t\(file.name)")
        }
        
    }
}

BigFiles.main()
