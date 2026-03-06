import Foundation
import UIKit

// MARK: - String Matching Helpers

private let kPatternRandom = "\\#(\\d{1,6})\\#"
private let kPatternCommandIndex = "\\$\\d{1,2}(\\$)?"
private let kPatternWord = "\\b(\\w)+(\\$)?\\b"

private let randomRegex = try! NSRegularExpression(
    pattern: kPatternRandom,
    options: [.useUnixLineSeparators, .useUnicodeWordBoundaries]
)

private let patternLocationMatcher = try! NSRegularExpression(
    pattern: kPatternCommandIndex,
    options: [.useUnixLineSeparators, .useUnicodeWordBoundaries]
)

private let nonDecimalCharacterSet = CharacterSet.decimalDigits.inverted

private extension String {
    /// Split input by semicolons/newlines and expand #N# random syntax.
    var commandsFromUserInput: [String] {
        guard !isEmpty else { return [] }

        var matchString = self as NSString
        let splitChars = CharacterSet(charactersIn: ";").union(.newlines)

        // Find all #N# matches
        let rangeMatches = randomRegex.matches(
            in: matchString as String,
            range: NSRange(location: 0, length: matchString.length)
        ).map { $0.range }

        // Replace in reverse order to preserve ranges
        for range in rangeMatches.reversed() {
            guard NSMaxRange(range) <= matchString.length else { continue }
            let match = matchString.substring(with: range).replacingOccurrences(of: "#", with: "")
            guard let matchValue = UInt32(match), matchValue > 0, matchValue <= 999999 else { continue }
            let replacement = "\(1 + arc4random_uniform(matchValue))"
            matchString = matchString.replacingCharacters(in: range, with: replacement) as NSString
        }

        return (matchString as String)
            .components(separatedBy: splitChars)
            .filter { !$0.isEmpty }
    }

    /// Find $N command index locations in this pattern string.
    /// Returns [wordIndex: commandIndex].
    var commandLocationsForPattern: [Int: Int] {
        guard !isEmpty else { return [:] }

        var result: [Int: Int] = [:]
        let words = components(separatedBy: .whitespacesAndNewlines)

        for (index, word) in words.enumerated() {
            let matches = patternLocationMatcher.numberOfMatches(
                in: word, range: NSRange(location: 0, length: (word as NSString).length)
            )
            if matches > 0 {
                let digits = (word as NSString)
                    .components(separatedBy: nonDecimalCharacterSet)
                    .joined()
                guard let intVal = Int(digits), intVal >= 1, intVal <= 99 else { continue }
                result[index] = intVal
            }
        }

        return result
    }

    /// Build a regex for the given pattern by replacing $N placeholders with word matchers.
    static func regex(forPattern pattern: String) -> NSRegularExpression? {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let commandLocations = trimmed.commandLocationsForPattern
        var words = trimmed.components(separatedBy: .whitespacesAndNewlines)

        for (wordIndex, _) in commandLocations {
            guard wordIndex < words.count else { continue }
            words[wordIndex] = kPatternWord
        }

        return try? NSRegularExpression(
            pattern: words.joined(separator: " "),
            options: [.useUnixLineSeparators, .useUnicodeWordBoundaries]
        )
    }

    /// Check if this string matches the given trigger/alias pattern.
    func matchesPattern(_ pattern: String) -> Bool {
        let commandLocations = pattern.commandLocationsForPattern

        // Simple case: no $N indexes, just check substring containment
        if commandLocations.isEmpty {
            return (self as NSString).range(of: pattern).location != NSNotFound
        }

        guard let lineMatcher = String.regex(forPattern: pattern) else { return false }

        return lineMatcher.numberOfMatches(
            in: self, range: NSRange(location: 0, length: (self as NSString).length)
        ) > 0
    }

    /// Perform command substitution: replace $N in command with words captured from input line.
    func commandForUserCommand(_ command: String, inputLine line: String) -> String? {
        let patternLocations = self.commandLocationsForPattern

        if patternLocations.isEmpty {
            return command
        }

        let commandLocations = command.commandLocationsForPattern

        guard let lineMatcher = String.regex(forPattern: self) else { return nil }

        let matches = lineMatcher.matches(
            in: line, range: NSRange(location: 0, length: (line as NSString).length)
        )

        var commandWords = command.components(separatedBy: .whitespacesAndNewlines)

        for result in matches.reversed() {
            let substr = (line as NSString).substring(with: result.range)
            let matchWords = substr.components(separatedBy: .whitespacesAndNewlines)

            for (wordIndex, cmdIndex) in patternLocations {
                for (wordCmdIndex, cmdCmdIndex) in commandLocations {
                    guard cmdIndex == cmdCmdIndex else { continue }
                    guard wordCmdIndex < commandWords.count else { continue }

                    let commandWord = commandWords[wordCmdIndex]
                    guard !commandWord.isEmpty else { continue }

                    guard let firstMatch = patternLocationMatcher.firstMatch(
                        in: commandWord,
                        range: NSRange(location: 0, length: (commandWord as NSString).length)
                    ), firstMatch.range.location != NSNotFound else { continue }

                    guard wordIndex < matchWords.count else { continue }

                    let newCommand = (commandWord as NSString)
                        .replacingCharacters(in: firstMatch.range, with: matchWords[wordIndex])
                    guard !newCommand.isEmpty else { continue }

                    commandWords[wordCmdIndex] = newCommand
                }
            }
        }

        return commandWords.joined(separator: " ")
    }
}

// MARK: - Validation

extension MUDWorld {
    @objc var canSave: Bool {
        !hostname.isEmpty && port > 0 && port <= Int16.max
    }
}

extension MUDAlias {
    @objc var canSave: Bool {
        !name.isEmpty && !commands.isEmpty
    }
}

extension MUDTrigger {
    @objc var canSave: Bool {
        !trigger.isEmpty
    }

    @objc static var triggerTypeLabelArray: [String] {
        [
            NSLocalizedString("START_OF_LINE", comment: "Start of Line"),
            NSLocalizedString("LINE_CONTAINS", comment: "Line contains"),
        ]
    }
}

extension MUDGag {
    @objc var canSave: Bool {
        true
    }

    @objc static var gagTypeLabelArray: [String] {
        [
            NSLocalizedString("START_OF_LINE", comment: "Start of Line"),
            NSLocalizedString("LINE_CONTAINS", comment: "Line contains"),
            NSLocalizedString("LINE_EQUALS", comment: "Line equals"),
        ]
    }
}

extension MUDTicker {
    @objc var canSave: Bool {
        interval > 0
            && (!commands.isEmpty || (soundFileName != nil && soundFileName != "None" && !(soundFileName?.isEmpty ?? true)))
    }
}

// MARK: - MUDAlias Logic

extension MUDAlias {
    @objc func aliasCommands(forInput input: String) -> [String]? {
        let commands = self.commands.commandsFromUserInput
        var inputWords = input.components(separatedBy: .whitespaces)

        inputWords.removeAll { $0.lowercased() == self.name.lowercased() }

        let targetInput = inputWords.isEmpty ? "" : inputWords.joined(separator: " ")

        let commandIndexer = try! NSRegularExpression(
            pattern: "\\$..?\\$",
            options: [.caseInsensitive, .useUnixLineSeparators]
        )

        var result: [String] = []

        for command in commands {
            var outString = command
            var maxCommandIndex = 0
            var didApplyMatching = false

            let matches = commandIndexer.matches(
                in: command,
                range: NSRange(command.startIndex..., in: command)
            )

            for match in matches.reversed() {
                guard let range = Range(match.range, in: command) else { continue }
                let marker = String(command[range])
                let aIndex = marker.replacingOccurrences(of: "$", with: "")

                let replaceWith: String
                if aIndex == "*" {
                    if inputWords.count > maxCommandIndex {
                        replaceWith = inputWords[maxCommandIndex...].joined(separator: " ")
                    } else {
                        replaceWith = ""
                    }
                } else if let intVal = Int(aIndex), intVal >= 1 {
                    let idx = intVal - 1
                    if inputWords.count > idx {
                        replaceWith = inputWords[idx]
                        if idx >= maxCommandIndex {
                            maxCommandIndex = idx + 1
                        }
                    } else {
                        replaceWith = ""
                    }
                } else {
                    continue
                }

                outString = outString.replacingOccurrences(of: marker, with: replaceWith)
                didApplyMatching = true
            }

            if !didApplyMatching {
                outString += " \(targetInput)"
            }

            result.append(outString)
        }

        return result.isEmpty ? nil : result
    }
}

// MARK: - MUDGag Logic

extension MUDGag {
    @objc func matchesLine(_ line: String) -> Bool {
        let toMatch = gag.trimmingCharacters(in: .whitespaces)

        if toMatch.isEmpty {
            return line.isEmpty
        }
        if line.isEmpty {
            return false
        }

        switch gagType {
        case .startOfLine:
            return line.hasPrefix(toMatch)
        case .lineContains:
            return (line as NSString).range(of: toMatch).location != NSNotFound
        case .lineEquals:
            return line == toMatch
        }
    }
}

// MARK: - MUDTrigger Logic

extension MUDTrigger {
    @objc func matchesLine(_ line: String) -> Bool {
        guard !trigger.isEmpty else { return false }
        return line.matchesPattern(trigger)
    }

    @objc func triggerCommands(forLine line: String) -> [String] {
        let userCommands = commands.commandsFromUserInput
        var output: [String] = []

        for userCommand in userCommands where !userCommand.isEmpty {
            let cmd = trigger.commandForUserCommand(userCommand, inputLine: line) ?? ""
            if !cmd.isEmpty {
                output.append(cmd)
            }
        }

        return output
    }
}

// MARK: - MUDWorld Logic

extension MUDWorld {
    @objc var worldDescription: String {
        if !name.isEmpty {
            return name + " "
        }
        var ret = hostname
        ret += ":\(port)"
        return ret
    }

    @objc var orderedAliases: [MUDAlias] {
        aliases
            .filter { !$0.isHidden }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @objc func orderedTriggers(active: Bool) -> [MUDTrigger] {
        triggers
            .filter { !$0.isHidden && $0.isEnabled == active }
            .sorted { $0.trigger.localizedCaseInsensitiveCompare($1.trigger) == .orderedAscending }
    }

    @objc var orderedGags: [MUDGag] {
        gags
            .filter { !$0.isHidden }
            .sorted { $0.gag.localizedCaseInsensitiveCompare($1.gag) == .orderedAscending }
    }

    @objc var orderedTickers: [MUDTicker] {
        tickers
            .filter { !$0.isHidden }
            .sorted { $0.commands.localizedCaseInsensitiveCompare($1.commands) == .orderedAscending }
    }

    @objc func commandsIfMatchingAlias(forInput userInput: String) -> [String]? {
        guard !aliases.isEmpty, !userInput.isEmpty else { return nil }

        let words = userInput.components(separatedBy: .whitespaces)
        guard let command = words.first else { return nil }

        let match = aliases.first {
            !$0.name.isEmpty && $0.name.lowercased() == command.lowercased()
        }

        return match?.aliasCommands(forInput: userInput)
    }

    @objc func filteredIndexesByMatchingGags(inLines lines: [String]) -> IndexSet {
        var indexes = IndexSet(integersIn: 0..<lines.count)

        guard !gags.isEmpty else { return indexes }

        for (index, line) in lines.enumerated() {
            for gag in gags where gag.matchesLine(line) {
                indexes.remove(index)
                break
            }
        }

        return indexes
    }

    struct TriggerResult {
        var commands: [String] = []
        var colors: [Int: UIColor] = [:]
        var soundName: String?
    }

    func runTriggers(forLines lines: [String]) -> TriggerResult {
        let activeTriggers = orderedTriggers(active: true)
        var result = TriggerResult()

        guard !activeTriggers.isEmpty, !lines.isEmpty else { return result }

        for (index, line) in lines.enumerated() {
            guard !line.isEmpty else { continue }

            for trigger in activeTriggers {
                guard !trigger.trigger.isEmpty, trigger.matchesLine(line) else { continue }

                result.commands.append(contentsOf: trigger.triggerCommands(forLine: line))

                if let color = trigger.highlightColor {
                    result.colors[index] = color
                }

                if let sound = trigger.soundFileName, !sound.isEmpty, sound != "None" {
                    result.soundName = sound
                }
            }
        }

        return result
    }

    @objc func deepClone() -> MUDWorld {
        MUDWorld(
            hostname: hostname,
            name: name,
            port: port,
            isDefault: false,
            isSecure: isSecure,
            connectCommand: connectCommand,
            aliases: aliases.map {
                MUDAlias(isEnabled: $0.isEnabled, name: $0.name, commands: $0.commands)
            },
            triggers: triggers.map {
                MUDTrigger(
                    isEnabled: $0.isEnabled, trigger: $0.trigger,
                    commands: $0.commands, soundFileName: $0.soundFileName,
                    triggerType: $0.triggerType, highlightColor: $0.highlightColor,
                    vibrate: $0.vibrate
                )
            },
            gags: gags.map {
                MUDGag(isEnabled: $0.isEnabled, gagType: $0.gagType, gag: $0.gag)
            },
            tickers: tickers.map {
                MUDTicker(
                    isEnabled: $0.isEnabled, interval: $0.interval,
                    commands: $0.commands, soundFileName: $0.soundFileName
                )
            }
        )
    }

    @objc static func cleanedHostName(for host: String) -> String {
        guard !host.isEmpty else { return "" }

        var str = host.lowercased()

        if let range = str.range(of: "://") {
            str.removeSubrange(str.startIndex..<range.upperBound)
        }

        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: ".-"))

        return str.unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
    }
}
