//
//  main.swift
//  BigFiles
//
//  Created by Jacob DeHart on 12/5/20.
//

import Foundation
import ArgumentParser


var totalFiles = 0

struct BigFile {
    var path: String
    var size: Double
}
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
    
    func vlog(msg: String) {
        if verbose {
            print(msg)
        }
    }
    
    func look_at_file(path: String, depth: Int) {
        if depth < 0 {
            return
        }
        
        vlog(msg: "Looking at \(path), depth: \(depth)")
        
        let url = URL(fileURLWithPath: path)
        if let ok = try? url.checkResourceIsReachable(), ok {
            let vals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
            if let islink = vals?.isSymbolicLink, islink {
                vlog(msg: "\t\tSkipping symbolic link")
            } else if let isdir = vals?.isDirectory, isdir {
                
                vlog(msg: "\t\tIt's a directory")
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: path)
                    for item in items {
                        look_at_file(path: "\(path)/\(item)", depth: depth - 1)
                    }
                } catch {
                    vlog(msg: "Couldn't read data of \(path)")
                }
            } else { // its a file
                vlog(msg: "\t\tIt's a file")
                totalFiles = totalFiles + 1
                var fileSizeValue = 0.0
                try? fileSizeValue = (url.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
                
                allFiles.append(BigFile(path: path, size: fileSizeValue))
                allFiles.sort { $0.size > $1.size }
                if allFiles.count > number {
                    allFiles.removeLast()
                }
                
            }
            
        } else {
            vlog(msg: "\t\tUnreachable")
        }
        
    }
    
    

    func humanReadable(_ bytes: Double) -> String {
        let suffix = ["B", "K", "M", "G"]
        var suffixIndex = 0
        var size = bytes
        for _ in 0..<suffix.count {
            if size > 1024 {
                suffixIndex += 1
                size = size / 1024
            }
        }
        size.round()
        return "\(size)\(suffix[suffixIndex])"
    }
    
    mutating func run() throws {
        let cwd = FileManager.default.currentDirectoryPath
        path = path ?? cwd
        let startTime = Date().timeIntervalSince1970
        look_at_file(path: path!, depth: depth)
        print("Total File Checked: \(totalFiles)")
        print("Biggest Files:")
        for file in allFiles {
            var size: String
            if human {
                size = humanReadable(file.size)
            } else {
                size = "\(file.size)"
            }
            print("\(size)\t\t\(file.path)")
        }
        let totalTime = Date().timeIntervalSince1970 - startTime
        print("\nTotal Time: \(totalTime)")
    }
}

BigFiles.main()
