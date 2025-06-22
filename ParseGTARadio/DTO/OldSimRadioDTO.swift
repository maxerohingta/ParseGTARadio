//
//  OldSimRadioDTO.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 07.06.2025.
//

import Foundation

enum OldSimRadioDTO {
    struct GameSeries: Codable, Sendable {
        let origin: String?
        let info: SeriesInfo
        let common: GameSeriesShared
        let stations: [Station]
    }

    struct SeriesInfo: Codable {
        let title: String
        let logo: String
    }

    struct GameSeriesShared: Codable, Sendable {
        let fileGroups: [FileGroup]
    }

    struct Station: Codable {
        let tag: String
        let info: StationInfo
        let fileGroups: [FileGroup]
        let playlist: Playlist
    }

    struct FileGroup: Codable, Sendable {
        let tag: String
        let files: [File]
    }

    struct File: Codable, Sendable {
        let tag: String?
        let path: String
        let duration: Double
        let audibleDuration: Double?
        let attachments: Attachments?
        let markers: TrackMarkers?
    }

    struct TrackMarkers: Codable {
        let track: [TrackMarker]?
        let dj: [TypeMarker]?
        let rockout: [TypeMarker]?
        let beat: [ValueMarker]?
    }

    struct ValueMarker: Codable {
        let offset: Int
        let value: Int
    }

    enum MarkerType: String, Codable {
        case start
        case end
        case introStart
        case introEnd
        case outroStart
        case outroEnd
    }

    struct TypeMarker: Codable {
        let offset: Int
        let value: MarkerType
    }

    struct TrackMarker: Codable {
        let offset: Int
        let id: Int
        let title: String?
        let artist: String?
    }

    struct Attachments: Codable {
        let files: [File]
    }

    struct StationInfo: Codable {
        let title: String
        let genre: String
        let logo: String
        let dj: String?
    }

    struct FirstFragment: Codable {
        let tag: String
    }

    struct FragmentRef: Codable {
        let fragmentTag: String
        let probability: Double?
    }

    struct Source: Codable {
        let type: SrcType
        let groupTag: String?
        let fileTag: String?
    }

    struct Position: Codable {
        let tag: String
        let relativeOffset: Double
    }

    struct PosVariant: Codable {
        let posTag: String
    }

    struct Condition: Codable {
        let type: ConditionType
        let fragmentTag: String?
        let probability: Double?
        let from: String?
        let to: String?
        let condition: [Condition]?
    }

    struct Mix: Codable {
        let tag: String
        let src: Source
        let condition: Condition
        let posVariant: [PosVariant]
    }

    struct Mixin: Codable {
        let pos: [Position]
        let mix: [Mix]
    }

    struct Fragment: Codable {
        let tag: String
        let src: Source
        let nextFragment: [FragmentRef]
        let mixins: Mixin?
    }

    struct Playlist: Codable {
        let firstFragment: FragmentRef
        let fragments: [Fragment]
    }

    enum SrcType: String, Codable {
        case group
        case attach
        case file
    }

    enum ConditionType: String, Codable {
        case nextFragment
        case random
        case groupAnd
        case groupOr
        case timeInterval
    }
}

extension OldSimRadioDTO.GameSeries {
    // alias
    var gameSeriesShared: OldSimRadioDTO.GameSeriesShared {
        common
    }

    init(
        origin: String?,
        info: OldSimRadioDTO.SeriesInfo,
        gameSeriesShared: OldSimRadioDTO.GameSeriesShared,
        stations: [OldSimRadioDTO.Station]
    ) {
        self.init(
            origin: origin,
            info: info,
            common: gameSeriesShared,
            stations:
            stations
        )
    }
}
