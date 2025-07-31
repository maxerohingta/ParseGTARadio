//
//  Converter.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 14.06.2025.
//

import Foundation

extension DumpsDTO.RadioData {
    func stationsSpeechTrackLists(
        _ simRadio: OldSimRadioDTO.GameSeries?
    ) -> [NewSimRadioDTO.TrackList] {
        let speeches = stations.compactMap { key, value in
            let simStation = simRadio?.stations.first { $0.tag == key }
            return value.speech.map { $0.trackLists(stationId: key, simStation: simStation) }
        }
        return speeches.flatMap(\.self)
    }

    func stationsTrackLists(
        _ simRadio: OldSimRadioDTO.GameSeries?
    ) -> [NewSimRadioDTO.TrackList] {
        var tracklistIntros: [NewSimRadioDTO.Track] = []
        let result: [[NewSimRadioDTO.TrackList]] = stationsTrackListsWithIDs.map { id, trackList in
            tracklistIntros = []
            let simTrackList: [NewSimRadioDTO.Track] = trackList.tracks.map { trackListItem in
                let simStations = simRadio?.stations ?? []
                let simStation = trackListItem.path?.split(separator: "/").first.flatMap { stationID in
                    simStations.first { $0.tag == stationID } ?? nil
                }
                let trackId = String(trackListItem.path?.split(separator: "/").last ?? "")
                let forcedDuration = simStation?.duration(trackId: trackId)

                let trackFileGroup = simStation?.fileGroups.first { $0.tag == "track" }

                let trackIntros = trackListItem
                    .intro?
                    .trackListItems(
                        trackID: trackListItem.id,
                        trackPath: trackListItem.path,
                        fileGroup: trackFileGroup
                    ) ?? []

                tracklistIntros.append(contentsOf: trackIntros)
                return NewSimRadioDTO.Track(
                    data: trackListItem,
                    forcedDuration: forcedDuration,
                    intro: !trackIntros.isEmpty ? trackIntros.map(\.id) : nil,
                    trackList: nil
                )
            }
            if tracklistIntros.isEmpty {
                return [
                    .init(id: .init(id), tracks: simTrackList)
                ]
            } else {
                return [
                    .init(id: .init(id), tracks: simTrackList),
                    .init(id: .init([id, "intro"].joined(separator: "_")), tracks: tracklistIntros)
                ]
            }
        }
        return result.flatMap(\.self)
    }

    var stationsTrackListsWithIDs: [(String, DumpsDTO.TrackList)] {
        let stationsTrackListIDs = trackLists
            .keys
            .filter { id in !["RADIO_NEWS_", "_adverts"].contains { id.lowercased().contains($0.lowercased()) } }
            .sorted()
        let result = stationsTrackListIDs.compactMap { id in
            trackLists[id].map {
                (
                    id,
                    DumpsDTO.TrackList(
                        dlcPath: $0.dlcPath,
                        flags: $0.flags,
                        tracks: Array(Set($0.tracks))
                    )
                )
            }
        }
        return result
    }
    
    func newsTrackLists(
        _ simRadio: OldSimRadioDTO.GameSeries?
    ) -> [NewSimRadioDTO.TrackList] {
        let durations = simRadio?
            .gameSeriesShared
            .fileGroups
            .first(where: { $0.tag == "news" })?.durations ?? [:]

        let news1 = trackLists["RADIO_NEWS_01"]?.tracks ?? []
        let news2 = trackLists["RADIO_NEWS_02"]?.tracks ?? []
        let radioNews = (news1 + news2)
            .map {
                let path = $0.path?.split(separator: "/").last ?? "--"
                let forcedDuration = durations[String(path)]

                return NewSimRadioDTO.Track(
                    data: $0,
                    forcedDuration: forcedDuration,
                    intro: nil,
                    trackList: nil
                )
            }
        let allNews = Set(radioNews).sorted { $0.id.value < $1.id.value }

        return [
            .init(id: .init("radio_news"), tracks: allNews)
        ]
    }

    func advertsTrackLists(
        _ simRadio: OldSimRadioDTO.GameSeries?
    ) -> [NewSimRadioDTO.TrackList] {
        let durations = simRadio?
            .gameSeriesShared
            .fileGroups
            .first(where: { $0.tag == "adverts" })?.durations ?? [:]
        let countryAdverts = trackLists["country_adverts"]?.tracks ?? []
        let generalAdverts = trackLists["general_adverts"]?.tracks ?? []
        let radioAdverts = (countryAdverts + generalAdverts)
            .map {
                let path = $0.path?.split(separator: "/").last ?? "--"
                let forcedDuration = durations[String(path)]
                return NewSimRadioDTO.Track(
                    data: $0,
                    forcedDuration: forcedDuration,
                    intro: nil,
                    trackList: nil
                )
            }
        let allAdverts = Set(radioAdverts).sorted { $0.id.value < $1.id.value }

        let convertedCountryAdverts = countryAdverts.map {
            NewSimRadioDTO.Track(
                id: .init($0.id), trackList: .init("radio_adverts")
            )
        }.sorted { $0.id.value < $1.id.value }

        let convertedGeneralAdverts = generalAdverts.map {
            NewSimRadioDTO.Track(
                id: .init($0.id), trackList: .init("radio_adverts")
            )
        }.sorted { $0.id.value < $1.id.value }

        return [
            .init(id: .init("radio_adverts"), tracks: allAdverts),
            .init(id: .init("country_adverts"), tracks: convertedCountryAdverts),
            .init(id: .init("general_adverts"), tracks: convertedGeneralAdverts)
        ]
    }
}

extension DumpsDTO.TrackIntro {
    func trackListItems(
        trackID _: String,
        trackPath: String?,
        fileGroup: OldSimRadioDTO.FileGroup?
    ) -> [NewSimRadioDTO.Track] {
        let trackFileName = String(trackPath?.split(separator: "/").last ?? "")
        let names = generateFileList(count: variations, prefix: trackFileName, exension: "")

        let trackFile = fileGroup?.files.first { $0.path.dropLast(4) == trackFileName }
        return names.map { name in
            let forcedDuration = trackFile?.attachments?.files.first {
                let attachmentName = String($0.path.split(separator: "/").last?.dropLast(4) ?? "")
                return attachmentName == name
            }?.duration ?? -1

            if trackFile != nil, forcedDuration == -1 {
                print("❌ error: \(name) duration not found")
            }
            let path = [containerPath, name].joined(separator: "/")
            let id = path.replacingOccurrences(of: "/", with: "_")
            return .init(
                id: .init(id),
                path: path,
                duration: forcedDuration,
                intro: nil,
                markers: nil,
                trackList: nil
            )
        }
    }
}

extension DumpsDTO.Speech {
    func trackLists(stationId: String, simStation: OldSimRadioDTO.Station?) -> [NewSimRadioDTO.TrackList] {
        let generalList = general?.trackLists(
            stationId: stationId,
            prefix: "general",
            fileGroup: simStation?.fileGroups.first { $0.tag == "general" }
        )
        let ddGeneralList = ddGeneral?.trackLists(
            stationId: stationId,
            prefix: "dd_general",
            fileGroup: nil
        )
        let plGeneralList = plGeneral?.trackLists(
            stationId: stationId,
            prefix: "pl_general",
            fileGroup: nil
        )
        let morningList = time?.morning?.trackLists(
            stationId: stationId,
            prefix: "morning",
            fileGroup: simStation?.fileGroups.first { $0.tag == "time_morning" }
        )
        let afternoomList = time?.afternoom?.trackLists(
            stationId: stationId,
            prefix: "afternoom",
            fileGroup: simStation?.fileGroups.first { $0.tag == "time_afternoom" }
        )
        let eveningList = time?.evening?.trackLists(
            stationId: stationId,
            prefix: "evening",
            fileGroup: simStation?.fileGroups.first { $0.tag == "time_evening" }
        )
        let nightList = time?.night?.trackLists(
            stationId: stationId,
            prefix: "night",
            fileGroup: simStation?.fileGroups.first { $0.tag == "time_night" }
        )
        let newsList = to?.toNews?.trackLists(
            stationId: stationId,
            prefix: "news",
            fileGroup: simStation?.fileGroups.first { $0.tag == "to_news" }
        )
        let adList = to?.toAd?.trackLists(
            stationId: stationId,
            prefix: "ad",
            fileGroup: simStation?.fileGroups.first { $0.tag == "to_adverts" }
        )

        return [
            generalList,
            ddGeneralList,
            plGeneralList,
            morningList,
            afternoomList,
            eveningList,
            nightList,
            newsList,
            adList
        ].compactMap(\.self)
    }
}

extension DumpsDTO.SpeechCategory {
    func trackLists(
        stationId: String,
        prefix: String,
        fileGroup: OldSimRadioDTO.FileGroup?
    ) -> NewSimRadioDTO.TrackList {
        let names = generateFileList(count: variations, prefix: prefix, exension: "")
        let path = containerPath.split(separator: "/").suffix(2).joined(separator: "/")
        let baseTrackListID = path.replacingOccurrences(of: "/", with: "_")
        let trackListID = baseTrackListID.hasSuffix(prefix) ? baseTrackListID : "\(baseTrackListID)_\(prefix)"

        let hardcodedSkip15 = stationId == "radio_16_silverlake" && prefix == "general"

        return .init(
            id: .init(trackListID),
            tracks: names.compactMap { name in
                if hardcodedSkip15, name.hasSuffix("_15") {
                    return nil
                }
                let searchName: String = if name.hasPrefix("news_") || name.hasPrefix("ad_") {
                    "to_" + name
                } else {
                    name
                }

                let forcedDuration = fileGroup?.files.first {
                    let attachmentName = String($0.path.split(separator: "/").last?.dropLast(4) ?? "")
                    return attachmentName == searchName
                }?.duration ?? -1

                if fileGroup != nil, forcedDuration == -1 {
                    print("❌ error: \(name) duration not found, station: \(stationId)")
                }

                let isSubstringDuplicated = name.prefix(prefix.count) == trackListID.suffix(prefix.count)
                let itemID = trackListID
                    + (isSubstringDuplicated ? "" : "_")
                    + name.dropFirst(isSubstringDuplicated ? prefix.count : 0)
                let itemPath = [path, searchName].joined(separator: "/")

                return .init(
                    id: .init(itemID),
                    path: itemPath,
                    duration: forcedDuration,
                    intro: nil,
                    markers: nil,
                    trackList: nil
                )
            }
        )
    }
}

extension OldSimRadioDTO.Station {
    func duration(trackId: String) -> Double? {
        let durations = fileGroups.flatMap {
            $0.files.compactMap {
                $0.path.split(separator: "/")
                    .last?
                    .dropLast(4) ?? "" == trackId ? ($0.audibleDuration ?? $0.duration) : nil
            }
        }

        if durations.count == 1 {
            return durations[0]
        } else {
            print("❌ error: duration not found for track \(trackId), station \(tag)")
            return nil
        }
    }
}

extension NewSimRadioDTO.Track {
    init(
        data: DumpsDTO.TrackListItem,
        forcedDuration: Double?,
        intro: [ID]?,
        trackList: NewSimRadioDTO.TrackList.ID? = nil
    ) {
        if data.path == nil, data.trackList == nil {
            print("❌ error: no path for track \(data.id)")
        }
        let dataDuration = data.duration.map { Double($0) / 1000 }
        self.init(
            id: .init(data.id),
            path: data.path,
            duration: forcedDuration ?? dataDuration,
            intro: intro,
            markers: data.markers.map { .init(data: $0) },
            trackList: trackList ?? data.trackList.map { .init($0) }
        )
    }

    init(
        id: NewSimRadioDTO.Track.ID,
        trackList: NewSimRadioDTO.TrackList.ID?
    ) {
        self.init(
            id: id,
            path: nil,
            duration: nil,
            intro: nil,
            markers: nil,
            trackList: trackList
        )
    }
}

extension NewSimRadioDTO.TrackMarkers {
    init(
        data: DumpsDTO.TrackMarkers
    ) {
        self.init(
            track: data.track.map { $0.map {
                .init(offset: Double($0.offset) / 1000, id: $0.id, title: $0.title, artist: $0.artist)
            } },
            dj: data.dj.map { $0.map {
                .init(
                    offset: Double($0.offset) / 1000,
                    value: .init(data: $0.value)
                )
            } },
            rockout: data.rockout.map { $0.map {
                .init(
                    offset: Double($0.offset) / 1000,
                    value: .init(data: $0.value)
                )
            } },
            beat: data.beat.map { $0.map {
                .init(
                    offset: Double($0.offset) / 1000,
                    value: $0.value
                )
            } }
        )
    }
}

extension OldSimRadioDTO.FileGroup {
    var durations: [String: Double] {
//        let durationTupples = (simRadio
//            .gameSeriesShared
//            .fileGroups
//            .first(where: { $0.tag == "adverts" })?.files ?? [])

        let durationTupples = files.map {
            (
                String($0.path.split(separator: "/").last?.dropLast(4) ?? ""),
                $0.audibleDuration ?? $0.duration
            )
        }

        return Dictionary(uniqueKeysWithValues: durationTupples)
    }
}

extension NewSimRadioDTO.MarkerType {
    init(data: DumpsDTO.MarkerType) {
        switch data {
        case .start:
            self = .start
        case .end:
            self = .end
        case .introStart:
            self = .introStart
        case .introEnd:
            self = .introEnd
        case .outroStart:
            self = .outroStart
        case .outroEnd:
            self = .outroEnd
        }
    }
}

extension NewSimRadioDTO.Station {
    init(id: String, data: DumpsDTO.Station) {
        let speechIDs = (
            data.speech
                .map { $0.trackLists(stationId: id, simStation: nil) } ?? []
        )
        .map(\.id)

        let tracklistIDs: [NewSimRadioDTO.TrackList.ID] = data.trackLists.map { .init(value: $0) }

        self.init(
            id: .init(id),
            genre: data.genre,
            trackLists: (tracklistIDs + speechIDs).sorted { $0.value < $1.value }
        )
    }
}

extension NewSimRadioDTO.StationFlag {
    init(data: DumpsDTO.StationFlag) {
        self =
            switch data {
            case .noBack2BackMusic: .noBack2BackMusic
            case .playNews: .playNews
            case .playsUsersMusic: .playsUsersMusic
            case .isMixStation: .isMixStation
            case .back2BackAds: .back2BackAds
            case .sequentialMusic: .sequentialMusic
            case .identsInsteadOfAds: .identsInsteadOfAds
            case .locked: .locked
            case .useRandomizedStrideSelection: .useRandomizedStrideSelection
            case .playWeather: .playWeather
            }
    }
}
