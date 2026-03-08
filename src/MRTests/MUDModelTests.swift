import Testing
@testable import Wammer

// MARK: - MUDGag

@Suite struct GagTests {
    @Test func startOfLine() {
        let gag = MUDGag(gagType: .startOfLine, gag: "Hello")
        #expect(gag.matchesLine("Hello world"))
        #expect(!gag.matchesLine("Say Hello"))
    }

    @Test func lineContains() {
        let gag = MUDGag(gagType: .lineContains, gag: "secret")
        #expect(gag.matchesLine("This is a secret message"))
        #expect(gag.matchesLine("secret"))
        #expect(!gag.matchesLine("nothing here"))
    }

    @Test func lineEquals() {
        let gag = MUDGag(gagType: .lineEquals, gag: "exact match")
        #expect(gag.matchesLine("exact match"))
        #expect(!gag.matchesLine("exact match plus more"))
        #expect(!gag.matchesLine("not exact match"))
    }

    @Test func emptyPattern() {
        let gag = MUDGag(gagType: .lineContains, gag: "")
        #expect(gag.matchesLine(""))
        #expect(!gag.matchesLine("non-empty"))
    }

    @Test func emptyLine() {
        let gag = MUDGag(gagType: .lineContains, gag: "something")
        #expect(!gag.matchesLine(""))
    }

    @Test func trimsWhitespace() {
        let gag = MUDGag(gagType: .lineEquals, gag: "  hello  ")
        #expect(gag.matchesLine("hello"))
    }
}

// MARK: - MUDTrigger

@Suite struct TriggerTests {
    @Test func matchesSimple() {
        let trigger = MUDTrigger(trigger: "attacks you")
        #expect(trigger.matchesLine("The orc attacks you!"))
        #expect(!trigger.matchesLine("You attack the orc"))
    }

    @Test func emptyPattern() {
        let trigger = MUDTrigger(trigger: "")
        #expect(!trigger.matchesLine("anything"))
    }
}

// MARK: - MUDAlias

@Suite struct AliasTests {
    @Test func simple() {
        let alias = MUDAlias(name: "k", commands: "kill")
        let result = alias.aliasCommands(forInput: "k orc")
        #expect(result == ["kill orc"])
    }

    @Test func positionalArgs() {
        let alias = MUDAlias(name: "kk", commands: "kill $1$")
        let result = alias.aliasCommands(forInput: "kk orc")
        #expect(result == ["kill orc"])
    }

    @Test func starArg() {
        let alias = MUDAlias(name: "s", commands: "say $*$")
        let result = alias.aliasCommands(forInput: "s hello world")
        #expect(result == ["say hello world"])
    }

    @Test func noArgs() {
        let alias = MUDAlias(name: "k", commands: "kill")
        let result = alias.aliasCommands(forInput: "k")
        #expect(result == ["kill "])
    }

    @Test func multipleCommands() {
        let alias = MUDAlias(name: "prep", commands: "wield sword;cast shield")
        let result = alias.aliasCommands(forInput: "prep")
        #expect(result?.count == 2)
    }
}

// MARK: - MUDWorld aliases

@Suite struct WorldAliasTests {
    @Test func lookup() {
        let world = MUDWorld()
        world.aliases = [MUDAlias(name: "k", commands: "kill")]
        let result = world.commandsIfMatchingAlias(forInput: "k orc")
        #expect(result == ["kill orc"])
    }

    @Test func noMatch() {
        let world = MUDWorld()
        world.aliases = [MUDAlias(name: "k", commands: "kill")]
        #expect(world.commandsIfMatchingAlias(forInput: "flee") == nil)
    }

    @Test func emptyAliases() {
        let world = MUDWorld()
        #expect(world.commandsIfMatchingAlias(forInput: "k orc") == nil)
    }
}

// MARK: - MUDWorld gag filtering

@Suite struct GagFilteringTests {
    @Test func filtersMatchingLines() {
        let world = MUDWorld()
        world.gags = [MUDGag(gagType: .lineContains, gag: "spam")]
        let lines = ["hello", "this is spam", "goodbye"]
        let indexes = world.filteredIndexesByMatchingGags(inLines: lines)
        #expect(indexes.contains(0))
        #expect(!indexes.contains(1))
        #expect(indexes.contains(2))
    }

    @Test func noGagsPassesAll() {
        let world = MUDWorld()
        let lines = ["hello", "world"]
        let indexes = world.filteredIndexesByMatchingGags(inLines: lines)
        #expect(indexes == IndexSet(integersIn: 0..<2))
    }
}

// MARK: - MUDWorld triggers

@Suite struct WorldTriggerTests {
    @Test func triggersCommands() {
        let world = MUDWorld()
        world.triggers = [MUDTrigger(trigger: "attacks you", commands: "flee")]
        let result = world.runTriggers(forLines: ["The orc attacks you"])
        #expect(result.commands == ["flee"])
    }

    @Test func triggersHighlightColor() {
        let world = MUDWorld()
        world.triggers = [MUDTrigger(trigger: "danger", highlightColor: .red)]
        let result = world.runTriggers(forLines: ["danger ahead"])
        #expect(result.colors[0] != nil)
    }

    @Test func triggersSound() {
        let world = MUDWorld()
        world.triggers = [MUDTrigger(trigger: "ding", soundFileName: "bell.wav")]
        let result = world.runTriggers(forLines: ["ding ding"])
        #expect(result.soundName == "bell.wav")
    }

    @Test func triggersSoundNone() {
        let world = MUDWorld()
        world.triggers = [MUDTrigger(trigger: "ding", soundFileName: "None")]
        let result = world.runTriggers(forLines: ["ding ding"])
        #expect(result.soundName == nil)
    }
}

// MARK: - MUDWorld description

@Suite struct WorldDescriptionTests {
    @Test func withName() {
        let world = MUDWorld(name: "Test MUD")
        #expect(world.worldDescription == "Test MUD ")
    }

    @Test func withoutName() {
        let world = MUDWorld(hostname: "mud.example.com", port: 4000)
        #expect(world.worldDescription == "mud.example.com:4000")
    }
}

// MARK: - MUDWorld deepClone

@Suite struct DeepCloneTests {
    @Test func clonesAllFields() {
        let world = MUDWorld(
            hostname: "test.com", name: "Test", port: 23,
            isDefault: true, isSecure: true, connectCommand: "login",
            aliases: [MUDAlias(name: "k", commands: "kill")],
            triggers: [MUDTrigger(trigger: "hit", commands: "flee")],
            gags: [MUDGag(gagType: .lineContains, gag: "spam")],
            tickers: [MUDTicker(interval: 10, commands: "tick")]
        )

        let clone = world.deepClone()

        #expect(clone.identifier != world.identifier)
        #expect(clone.hostname == "test.com")
        #expect(clone.name == "Test")
        #expect(!clone.isDefault)
        #expect(clone.isSecure)
        #expect(clone.connectCommand == "login")
        #expect(clone.aliases.count == 1)
        #expect(clone.aliases[0].identifier != world.aliases[0].identifier)
        #expect(clone.aliases[0].name == "k")
        #expect(clone.triggers.count == 1)
        #expect(clone.gags.count == 1)
        #expect(clone.tickers.count == 1)
    }
}

// MARK: - MUDWorld cleanedHostName

@Suite struct CleanedHostNameTests {
    @Test func lowercases() {
        #expect(MUDWorld.cleanedHostName(for: "MUD.Example.Com") == "mud.example.com")
    }

    @Test func stripsTelnetScheme() {
        #expect(MUDWorld.cleanedHostName(for: "telnet://mud.com") == "mud.com")
    }

    @Test func emptyString() {
        #expect(MUDWorld.cleanedHostName(for: "") == "")
    }

    @Test func preservesHyphens() {
        #expect(MUDWorld.cleanedHostName(for: "mud-server.net") == "mud-server.net")
    }

    @Test func stripsInvalidChars() {
        #expect(MUDWorld.cleanedHostName(for: "bad host!@#") == "badhost")
    }
}

// MARK: - MUDWorld ordered accessors

@Suite struct OrderedAccessorTests {
    @Test func orderedAliases() {
        let world = MUDWorld()
        world.aliases = [
            MUDAlias(name: "z"),
            MUDAlias(name: "a"),
            MUDAlias(isHidden: true, name: "hidden"),
        ]
        let ordered = world.orderedAliases
        #expect(ordered.count == 2)
        #expect(ordered[0].name == "a")
        #expect(ordered[1].name == "z")
    }

    @Test func orderedTriggers() {
        let world = MUDWorld()
        world.triggers = [
            MUDTrigger(trigger: "zzz"),
            MUDTrigger(trigger: "aaa"),
            MUDTrigger(isHidden: true, trigger: "hidden"),
            MUDTrigger(isEnabled: false, trigger: "disabled"),
        ]
        let active = world.orderedTriggers(active: true)
        #expect(active.count == 2)
        #expect(active[0].trigger == "aaa")

        let inactive = world.orderedTriggers(active: false)
        #expect(inactive.count == 1)
        #expect(inactive[0].trigger == "disabled")
    }
}

// MARK: - Codable round-trip

@Suite struct CodableTests {
    @Test func worldRoundTrip() throws {
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

        #expect(decoded.identifier == world.identifier)
        #expect(decoded.hostname == "test.com")
        #expect(decoded.port == 4000)
        #expect(decoded.isSecure)
        #expect(decoded.aliases.count == 1)
        #expect(decoded.triggers.count == 1)
        #expect(decoded.triggers[0].highlightColor != nil)
        #expect(decoded.gags.count == 1)
        #expect(decoded.gags[0].gagType == .lineEquals)
        #expect(decoded.tickers.count == 1)
    }
}

// MARK: - GMCPCharacterState

@Suite struct GMCPCharacterStateTests {
    @Test func vitalsUpdate() {
        let state = GMCPCharacterState()
        state.updateVitals(data: ["hp": 50, "maxhp": 100, "mana": 75, "maxmana": 150, "moves": 120, "maxmoves": 200])
        #expect(state.hp == 50)
        #expect(state.maxHP == 100)
        #expect(state.mana == 75)
        #expect(state.maxMana == 150)
        #expect(state.moves == 120)
        #expect(state.maxMoves == 200)
    }

    @Test func vitalsPartialUpdate() {
        let state = GMCPCharacterState()
        state.updateVitals(data: ["hp": 50, "maxhp": 100])
        #expect(state.hp == 50)
        #expect(state.mana == 0)

        state.updateVitals(data: ["hp": 30])
        #expect(state.hp == 30)
        #expect(state.maxHP == 100)
    }

    @Test func statusUpdate() {
        let state = GMCPCharacterState()
        state.updateStatus(data: ["level": 10, "align": 500, "gold": 1234, "tnl": 5000])
        #expect(state.level == 10)
        #expect(state.alignment == 500)
        #expect(state.gold == 1234)
        #expect(state.tnl == 5000)
    }

    @Test func reset() {
        let state = GMCPCharacterState()
        state.updateVitals(data: ["hp": 50, "maxhp": 100])
        state.updateStatus(data: ["level": 10])
        state.reset()
        #expect(state.hp == 0)
        #expect(state.maxHP == 0)
        #expect(state.level == 0)
    }

    @Test func postsNotification() async {
        let state = GMCPCharacterState()
        await confirmation { confirm in
            let observer = NotificationCenter.default.addObserver(
                forName: GMCPCharacterState.didUpdateNotification,
                object: state,
                queue: nil
            ) { _ in confirm() }
            state.updateVitals(data: ["hp": 50])
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - GMCPRoomState

@Suite struct GMCPRoomStateTests {
    @Test func roomInfoUpdate() {
        let state = GMCPRoomState()
        state.update(data: ["num": 3001, "exits": ["north": 3002, "south": 3000]])
        #expect(state.roomNumber == 3001)
        #expect(state.exits["north"] == 3002)
        #expect(state.exits["south"] == 3000)
    }

    @Test func reset() {
        let state = GMCPRoomState()
        state.update(data: ["num": 3001, "exits": ["north": 3002]])
        state.reset()
        #expect(state.roomNumber == 0)
        #expect(state.exits.isEmpty)
    }

    @Test func postsNotification() async {
        let state = GMCPRoomState()
        await confirmation { confirm in
            let observer = NotificationCenter.default.addObserver(
                forName: GMCPRoomState.didUpdateNotification,
                object: state,
                queue: nil
            ) { _ in confirm() }
            state.update(data: ["num": 3001])
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - GMCPHandler routing

@Suite struct GMCPHandlerTests {
    @Test func routesVitals() {
        let handler = GMCPHandler()
        handler.handleModule("char.vitals", data: ["hp": 42, "maxhp": 100])
        #expect(handler.characterState.hp == 42)
    }

    @Test func routesStatus() {
        let handler = GMCPHandler()
        handler.handleModule("char.status", data: ["level": 5])
        #expect(handler.characterState.level == 5)
    }

    @Test func routesRoomInfo() {
        let handler = GMCPHandler()
        handler.handleModule("room.info", data: ["num": 3001])
        #expect(handler.roomState.roomNumber == 3001)
    }

    @Test func caseInsensitive() {
        let handler = GMCPHandler()
        handler.handleModule("Char.Vitals", data: ["hp": 99])
        #expect(handler.characterState.hp == 99)
    }

    @Test func unknownModuleDoesNotCrash() {
        let handler = GMCPHandler()
        handler.handleModule("Unknown.Module", data: ["foo": "bar"])
    }

    @Test func reset() {
        let handler = GMCPHandler()
        handler.handleModule("char.vitals", data: ["hp": 50])
        handler.handleModule("room.info", data: ["num": 3001])
        handler.reset()
        #expect(handler.characterState.hp == 0)
        #expect(handler.roomState.roomNumber == 0)
    }
}
