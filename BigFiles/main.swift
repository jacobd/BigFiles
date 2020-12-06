//
//  main.swift
//  BigFiles
//
//  Created by Jacob DeHart on 12/5/20.
//

import Foundation
import ArgumentParser

// counter of how many files we've counted
var totalFiles = 0
// What we keep track of when indexing files
struct BigFile {
    var path: String
    var size: Int
}
// Array of all files, limited to --number option
var allFiles: [BigFile] = []


struct BigFiles: ParsableCommand {
    
    @Flag(help: "Show each file analyzed")
    var verbose = false
    
    @Flag(help: "human readable format")
    var human = false

    @Option(name: .shortAndLong, help: "The number of directories to go deep.")
    var depth = 10
    
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
    
    
    func look_at_file(path: String, depthRemaining: Int) {
        if depthRemaining < 0 {
            return
        }
        vlog(msg: "Looking at \(path), depthRemaining: \(depthRemaining)")
        let url = URL(fileURLWithPath: path)
        
        guard (try? url.checkResourceIsReachable()) != nil else {
            return
        }
        
        let vals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
        
        
        if let islink = vals?.isSymbolicLink, islink {
            vlog(msg: "\t\tSkipping symbolic link")
        } else if let isdir = vals?.isDirectory, isdir {
            vlog(msg: "\t\tIt's a directory")
            if let items = try? FileManager.default.contentsOfDirectory(atPath: path) {
                for item in items {
                    look_at_file(path: "\(path)/\(item)", depthRemaining: depthRemaining - 1)
                }
            }
        } else { // its a file
            vlog(msg: "\t\tIt's a file")
            totalFiles = totalFiles + 1
            var fileSizeValue = 0
            try? fileSizeValue = (url.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Int?)!
            
            allFiles.append(BigFile(path: path, size: fileSizeValue))
            allFiles.sort { $0.size > $1.size }
            if allFiles.count > number {
                allFiles.removeLast()
            }
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
        path = path ?? cwd
        let startTime = Date().timeIntervalSince1970
        look_at_file(path: path!, depthRemaining: depth)
        print("Total File Checked: \(totalFiles)")
        print("Biggest Files: \(allFiles.count)")
        for file in allFiles {
            var size: String
            if human {
                size = humanReadable(file.size)
            } else {
                size = String(file.size)
            }
            print("\(size)\t\(file.path)")
        }
        let totalTime = Date().timeIntervalSince1970 - startTime
        print("\nTotal Time: \(totalTime)")
    }
}

BigFiles.main()
