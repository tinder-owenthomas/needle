
//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Basic
import Foundation
import NeedleFramework
import QuartzCore
import Utility
import SourceKittenFramework

private func scanFile(atURL url: Foundation.URL) {
    let fileScanner = FileScanner(url: url)
    if fileScanner.shouldScan() {
        print("Parse:", url.path)
        if let contents = fileScanner.contents {
            let parser = FileParser(contents: contents, path: url.path)
            if let (c, d) = parser.parse() {
                print(c.count, d.count)
            }
        }
    }
}

private func scanFiles(atPath folderPath: String, withoutSuffixes suffixes: [String]?) {
    let scanner = DirectoryScanner(path: folderPath, withoutSuffixes: suffixes)
    scanner.scan { url in
        scanFile(atURL: url)
    }
}

protocol Command {
    var name: String { get }
    init(parser: ArgumentParser)
    func run(with arguments: ArgumentParser.Result)
}

struct ScanCommand: Command {
    let name = "scan"

    private let overview = "Scan's all swift files in the directory specified"
    private let dir: PositionalArgument<String>
    private let suffixes: OptionArgument<[String]>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: name, overview: overview)
        dir = subparser.add(positional: "directory", kind: String.self)
        suffixes = subparser.add(option: "--suffixes", shortName: "-s", kind: [String].self, usage: "Filename suffix(es) to skip (not including extension)", completion: .filename)
    }

    func run(with arguments: ArgumentParser.Result) {
        if let path = arguments.get(dir) {
            let suffixes = arguments.get(self.suffixes)
            scanFiles(atPath: path, withoutSuffixes: suffixes)
        }
    }
}

func main() {
    let parser = ArgumentParser(usage: "<command> <options>", overview: "needle DI code generator")
    let commandsTypes = [ScanCommand.self]
    let commands = commandsTypes.map { $0.init(parser: parser) }
    let arguments = Array(CommandLine.arguments.dropFirst())
    let result = try? parser.parse(arguments)
    if let result = result {
        let subparserName = result.subparser(parser)
        for command in commands {
            if subparserName == command.name {
                command.run(with: result)
            }
        }
    }
}

main()