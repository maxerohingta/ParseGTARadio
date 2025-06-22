import Foundation

enum DumpsDTO {
    struct RadioData: Decodable {
        let stations: [String: Station]
        let trackLists: [String: TrackList]
        enum CodingKeys: String, CodingKey {
            case stations = "Stations"
            case trackLists = "TrackLists"
        }
    }

    struct TrackList: Decodable {
        let dlcPath: String?
        let flags: [String]?
        let tracks: [TrackListItem]
        enum CodingKeys: String, CodingKey {
            case dlcPath = "DlcPath"
            case flags = "Flags"
            case tracks = "Tracks"
        }

        init(
            dlcPath: String?,
            flags: [String]?,
            tracks: [TrackListItem]
        ) {
            self.dlcPath = dlcPath
            self.flags = flags
            self.tracks = tracks
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            dlcPath = try container.decodeIfPresent(String.self, forKey: .dlcPath)
            tracks = try container.decode([TrackListItem].self, forKey: .tracks)

            if let flagsArray = try? container.decode([String].self, forKey: .flags) {
                flags = flagsArray
            } else if let flagsString = try? container.decode(String.self, forKey: .flags) {
                flags = [flagsString]
            } else {
                flags = nil
            }
        }
    }

    struct TrackListItem: Decodable, Hashable {
        let id: String
        let path: String?
        let duration: Int?
        let intro: TrackIntro?
        let markers: TrackMarkers?
        let trackList: String?
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case path = "Path"
            case duration = "Duration"
            case intro = "Intro"
            case markers = "Markers"
            case trackList = "TrackList"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            path = try container.decodeIfPresent(String.self, forKey: .path)
            duration = try container.decodeIfPresent(Int.self, forKey: .duration)
            markers = try container.decodeIfPresent(TrackMarkers.self, forKey: .markers)
            intro = try? container.decode(TrackIntro.self, forKey: .intro)
            trackList = try? container.decode(String.self, forKey: .trackList)
        }
    }

    struct TrackIntro: Codable, Hashable {
        let variations: Int
        let containerPath: String
        enum CodingKeys: String, CodingKey {
            case variations = "Variations"
            case containerPath = "ContainerPath"
        }
    }

    struct TrackMarkers: Codable, Hashable {
        let track: [TrackMarker]?
        let dj: [TypeMarker]?
        let rockout: [TypeMarker]?
        let beat: [ValueMarker]?
        enum CodingKeys: String, CodingKey {
            case track = "Track"
            case dj = "DJ"
            case rockout = "Rockout"
            case beat = "Beat"
        }
    }

    struct ValueMarker: Codable, Hashable {
        let offset: Int
        let value: Int
        enum CodingKeys: String, CodingKey {
            case offset = "Offset"
            case value = "Value"
        }
    }

    enum MarkerType: String, Codable {
        case start
        case end
        case introStart = "intro_start"
        case introEnd = "intro_end"
        case outroStart = "outro_start"
        case outroEnd = "outro_end"
    }

    struct TypeMarker: Codable, Hashable {
        let offset: Int
        let value: MarkerType
        enum CodingKeys: String, CodingKey {
            case offset = "Offset"
            case value = "Value"
        }
    }

    struct TrackMarker: Codable, Hashable {
        let offset: Int
        let id: Int
        let title: String?
        let artist: String?
        enum CodingKeys: String, CodingKey {
            case offset = "Offset"
            case id = "Id"
            case title = "Title"
            case artist = "Artist"
        }
    }

    struct Station: Decodable {
        let flagsValue: String
        let flags: [StationFlag]
        let genre: String
        let ambientRadioVol: String
        let radioName: String
        let trackLists: [String]
        let speech: Speech?
        enum CodingKeys: String, CodingKey {
            case flagsValue = "FlagsValue"
            case flags = "Flags"
            case genre = "Genre"
            case ambientRadioVol = "AmbientRadioVol"
            case radioName = "RadioName"
            case trackLists = "TrackLists"
            case speech = "Speech"
        }
    }

    enum StationFlag: String, Codable {
        case noBack2BackMusic = "NOBACK2BACKMUSIC"
        case playNews = "PLAYNEWS"
        case playsUsersMusic = "PLAYSUSERSMUSIC"
        case isMixStation = "ISMIXSTATION"
        case back2BackAds = "BACK2BACKADS"
        case sequentialMusic = "SEQUENTIALMUSIC"
        case identsInsteadOfAds = "IDENTSINSTEADOFADS"
        case locked = "LOCKED"
        case useRandomizedStrideSelection = "USERANDOMIZEDSTRIDESELECTION"
        case playWeather = "PLAYWEATHER"
    }

    struct Speech: Codable {
        let general: SpeechCategory?
        let ddGeneral: SpeechCategory?
        let plGeneral: SpeechCategory?
        let time: TimeCategory?
        let to: ToCategory?
        enum CodingKeys: String, CodingKey {
            case general = "GENERAL"
            case ddGeneral = "DD_GENERAL"
            case plGeneral = "PL_GENERAL"
            case time = "TIME"
            case to = "TO"
        }
    }

    struct SpeechCategory: Codable {
        let variations: Int
        let containerPath: String
        enum CodingKeys: String, CodingKey {
            case variations = "Variations"
            case containerPath = "ContainerPath"
        }
    }

    struct TimeCategory: Codable {
        let morning: SpeechCategory?
        let afternoom: SpeechCategory?
        let evening: SpeechCategory?
        let night: SpeechCategory?
        enum CodingKeys: String, CodingKey {
            case morning = "MORNING"
            case afternoom = "AFTERNOON"
            case evening = "EVENING"
            case night = "NIGHT"
        }
    }

    struct ToCategory: Codable {
        let toAd: SpeechCategory?
        let toNews: SpeechCategory?
        let toWeather: SpeechCategory?
        enum CodingKeys: String, CodingKey {
            case toAd = "TO_AD"
            case toNews = "TO_NEWS"
            case toWeather = "TO_WEATHER"
        }
    }
}
