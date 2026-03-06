import XCTest
@testable import Wammer

final class MUDModelTests: XCTestCase {

    // MARK: - MUDGag matchesLine

    func testGagStartOfLine() {
        let gag = MUDGag(gagType: .startOfLine, gag: "Hello")
        XCTAssertTrue(gag.matchesLine("Hello world"))
        XCTAssertFalse(gag.matchesLine("Say Hello"))
    }

    func testGagLineContains() {
        let gag = MUDGag(gagType: .lineContains, gag: "secret")
        XCTAssertTrue(gag.matchesLine("This is a secret message"))
        XCTAssertTrue(gag.matchesLine("secret"))
        XCTAssertFalse(gag.matchesLine("nothing here"))
    }

    func testGagLineEquals() {
        let gag = MUDGag(gagType: .lineEquals, gag: "exact match")
        XCTAssertTrue(gag.matchesLine("exact match"))
        XCTAssertFalse(gag.matchesLine("exact match plus more"))
        XCTAssertFalse(gag.matchesLine("not exact match"))
    }

    func testGagEmptyPattern() {
        let gag = MUDGag(gagType: .lineContains, gag: "")
        XCTAssertTrue(gag.matchesLine(""))
        XCTAssertFalse(gag.matchesLine("non-empty"))
    }

    func testGagEmptyLine() {
        let gag = MUDGag(gagType: .lineContains, gag: "something")
        XCTAssertFalse(gag.matchesLine(""))
    }

    func testGagTrimsWhitespace() {
        let gag = MUDGag(gagType: .lineEquals, gag: "  hello  ")
        XCTAssertTrue(gag.matchesLine("hello"))
    }

    // MARK: - MUDTrigger matchesLine

    func testTriggerMatchesSimple() {
        let trigger = MUDTrigger(trigger: "attacks you")
        XCTAssertTrue(trigger.matchesLine("The orc attacks you!"))
        XCTAssertFalse(trigger.matchesLine("You attack the orc"))
    }

    func testTriggerEmptyPattern() {
        let trigger = MUDTrigger(trigger: "")
        XCTAssertFalse(trigger.matchesLine("anything"))
    }

    // MARK: - MUDAlias aliasCommands

    func testAliasSimple() {
        let alias = MUDAlias(name: "k", commands: "kill")
        let result = alias.aliasCommands(forInput: "k orc")
        XCTAssertEqual(result, ["kill orc"])
    }

    func testAliasWithPositionalArgs() {
        let alias = MUDAlias(name: "kk", commands: "kill $1$")
        let result = alias.aliasCommands(forInput: "kk orc")
        XCTAssertEqual(result, ["kill orc"])
    }

    func testAliasWithStar() {
        let alias = MUDAlias(name: "s", commands: "say $*$")
        let result = alias.aliasCommands(forInput: "s hello world")
        XCTAssertEqual(result, ["say hello world"])
    }

    func testAliasNoMatch() {
        let alias = MUDAlias(name: "k", commands: "kill")
        let result = alias.aliasCommands(forInput: "k")
        XCTAssertEqual(result, ["kill "])
    }

    func testAliasMultipleCommands() {
        let alias = MUDAlias(name: "prep", commands: "wield sword;cast shield")
        let result = alias.aliasCommands(forInput: "prep")
        XCTAssertEqual(result?.count, 2)
    }

    // MARK: - MUDWorld commandsIfMatchingAlias

    func testWorldAliasLookup() {
        let world = MUDWorld()
        world.aliases = [
            MUDAlias(name: "k", commands: "kill"),
        ]
        let result = world.commandsIfMatchingAlias(forInput: "k orc")
        XCTAssertEqual(result, ["kill orc"])
    }

    func testWorldAliasNoMatch() {
        let world = MUDWorld()
        world.aliases = [
            MUDAlias(name: "k", commands: "kill"),
        ]
        XCTAssertNil(world.commandsIfMatchingAlias(forInput: "flee"))
    }

    func testWorldAliasEmpty() {
        let world = MUDWorld()
        XCTAssertNil(world.commandsIfMatchingAlias(forInput: "k orc"))
    }

    // MARK: - MUDWorld filteredIndexesByMatchingGags

    func testGagFiltering() {
        let world = MUDWorld()
        world.gags = [
            MUDGag(gagType: .lineContains, gag: "spam"),
        ]
        let lines = ["hello", "this is spam", "goodbye"]
        let indexes = world.filteredIndexesByMatchingGags(inLines: lines)
        XCTAssertTrue(indexes.contains(0))
        XCTAssertFalse(indexes.contains(1))
        XCTAssertTrue(indexes.contains(2))
    }

    func testGagFilteringNoGags() {
        let world = MUDWorld()
        let lines = ["hello", "world"]
        let indexes = world.filteredIndexesByMatchingGags(inLines: lines)
        XCTAssertEqual(indexes, IndexSet(integersIn: 0..<2))
    }

    // MARK: - MUDWorld runTriggers

    func testRunTriggersCommands() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "attacks you", commands: "flee"),
        ]
        let result = world.runTriggers(forLines: ["The orc attacks you"])
        XCTAssertEqual(result.commands, ["flee"])
    }

    func testRunTriggersHighlightColor() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "danger", highlightColor: .red),
        ]
        let result = world.runTriggers(forLines: ["danger ahead"])
        XCTAssertNotNil(result.colors[0])
    }

    func testRunTriggersSound() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "ding", soundFileName: "bell.wav"),
        ]
        let result = world.runTriggers(forLines: ["ding ding"])
        XCTAssertEqual(result.soundName, "bell.wav")
    }

    func testRunTriggersSoundNone() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "ding", soundFileName: "None"),
        ]
        let result = world.runTriggers(forLines: ["ding ding"])
        XCTAssertNil(result.soundName)
    }

    // MARK: - MUDWorld worldDescription

    func testWorldDescriptionWithName() {
        let world = MUDWorld(name: "Test MUD")
        XCTAssertEqual(world.worldDescription, "Test MUD ")
    }

    func testWorldDescriptionWithoutName() {
        let world = MUDWorld(hostname: "mud.example.com", port: 4000)
        XCTAssertEqual(world.worldDescription, "mud.example.com:4000")
    }

    // MARK: - MUDWorld deepClone

    func testDeepClone() {
        let world = MUDWorld(
            hostname: "test.com", name: "Test", port: 23,
            isDefault: true, isSecure: true, connectCommand: "login",
            aliases: [MUDAlias(name: "k", commands: "kill")],
            triggers: [MUDTrigger(trigger: "hit", commands: "flee")],
            gags: [MUDGag(gagType: .lineContains, gag: "spam")],
            tickers: [MUDTicker(interval: 10, commands: "tick")]
        )

        let clone = world.deepClone()

        XCTAssertNotEqual(clone.identifier, world.identifier)
        XCTAssertEqual(clone.hostname, "test.com")
        XCTAssertEqual(clone.name, "Test")
        XCTAssertFalse(clone.isDefault)
        XCTAssertTrue(clone.isSecure)
        XCTAssertEqual(clone.connectCommand, "login")
        XCTAssertEqual(clone.aliases.count, 1)
        XCTAssertNotEqual(clone.aliases[0].identifier, world.aliases[0].identifier)
        XCTAssertEqual(clone.aliases[0].name, "k")
        XCTAssertEqual(clone.triggers.count, 1)
        XCTAssertEqual(clone.gags.count, 1)
        XCTAssertEqual(clone.tickers.count, 1)
    }

    // MARK: - MUDWorld cleanedHostName

    func testCleanedHostName() {
        XCTAssertEqual(MUDWorld.cleanedHostName(for: "MUD.Example.Com"), "mud.example.com")
        XCTAssertEqual(MUDWorld.cleanedHostName(for: "telnet://mud.com"), "mud.com")
        XCTAssertEqual(MUDWorld.cleanedHostName(for: ""), "")
        XCTAssertEqual(MUDWorld.cleanedHostName(for: "mud-server.net"), "mud-server.net")
        XCTAssertEqual(MUDWorld.cleanedHostName(for: "bad host!@#"), "badhost")
    }

    // MARK: - MUDWorld ordered accessors

    func testOrderedAliases() {
        let world = MUDWorld()
        world.aliases = [
            MUDAlias(name: "z"),
            MUDAlias(name: "a"),
            MUDAlias(isHidden: true, name: "hidden"),
        ]
        let ordered = world.orderedAliases
        XCTAssertEqual(ordered.count, 2)
        XCTAssertEqual(ordered[0].name, "a")
        XCTAssertEqual(ordered[1].name, "z")
    }

    func testOrderedTriggers() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "zzz"),
            MUDTrigger(trigger: "aaa"),
            MUDTrigger(isHidden: true, trigger: "hidden"),
            MUDTrigger(isEnabled: false, trigger: "disabled"),
        ]
        let active = world.orderedTriggers(active: true)
        XCTAssertEqual(active.count, 2)
        XCTAssertEqual(active[0].trigger, "aaa")

        let inactive = world.orderedTriggers(active: false)
        XCTAssertEqual(inactive.count, 1)
        XCTAssertEqual(inactive[0].trigger, "disabled")
    }

    // MARK: - Codable round-trip

    func testWorldCodableRoundTrip() throws {
        let world = MUDWorld(
            hostname: "test.com", name: "Test", port: 4000,
            isSecure: true, connectCommand: "login",
            aliases: [MUDAlias(name: "k", commands: "kill")],
            triggers: [MUDTrigger(trigger: "hit", highlightColor: .red)],
            gags: [MUDGag(gagType: .lineEquals, gag: "spam")],
            tickers: [MUDTicker(interval: 30, commands: "look")]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(world)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(MUDWorld.self, from: data)

        XCTAssertEqual(decoded.identifier, world.identifier)
        XCTAssertEqual(decoded.hostname, "test.com")
        XCTAssertEqual(decoded.port, 4000)
        XCTAssertTrue(decoded.isSecure)
        XCTAssertEqual(decoded.aliases.count, 1)
        XCTAssertEqual(decoded.triggers.count, 1)
        XCTAssertNotNil(decoded.triggers[0].highlightColor)
        XCTAssertEqual(decoded.gags.count, 1)
        XCTAssertEqual(decoded.gags[0].gagType, .lineEquals)
        XCTAssertEqual(decoded.tickers.count, 1)
    }
}
