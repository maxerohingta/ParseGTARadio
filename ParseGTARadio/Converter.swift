//
//  Converter.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 14.06.2025.
//

import Foundation

extension DumpsDTO.RadioData {
    func stationsSpeechTrackLists() -> [NewSimRadioDTO.TrackList] {
        let speeches = stations.compactMap { key, value in
            return value.speech.map { $0.trackLists(stationId: key) }
        }
        return speeches.flatMap(\.self)
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
    
    func stationTrackList(id: String, trackList: DumpsDTO.TrackList) -> [NewSimRadioDTO.TrackList] {
        var tracklistIntros: [NewSimRadioDTO.Track] = []
        let simTrackList: [NewSimRadioDTO.Track] = trackList.tracks.map { trackListItem in
            let trackIntros = trackListItem
                .intro?
                .trackListItems(
                    trackID: trackListItem.id,
                    trackPath: trackListItem.path
                ) ?? []

            tracklistIntros.append(contentsOf: trackIntros)
            return NewSimRadioDTO.Track(
                data: trackListItem,
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

    func stationsTrackLists() -> [NewSimRadioDTO.TrackList] {
        let result: [[NewSimRadioDTO.TrackList]] = stationsTrackListsWithIDs.map { id, trackList in
            return stationTrackList(id: id, trackList: trackList)
        }
        return result.flatMap(\.self)
    }

    func newsTrackLists() -> [NewSimRadioDTO.TrackList] {
        let news1 = trackLists["RADIO_NEWS_01"]?.tracks ?? []
        let news2 = trackLists["RADIO_NEWS_02"]?.tracks ?? []
        let radioNews = (news1 + news2)
            .map {
                return NewSimRadioDTO.Track(
                    data: $0,
                    intro: nil,
                    trackList: nil
                )
            }
        let allNews = Set(radioNews).sorted { $0.id.value < $1.id.value }

        return [
            .init(id: .init("radio_news"), tracks: allNews)
        ]
    }

    func advertsTrackLists() -> [NewSimRadioDTO.TrackList] {
        let countryAdverts = trackLists["country_adverts"]?.tracks ?? []
        let generalAdverts = trackLists["general_adverts"]?.tracks ?? []
        let radioAdverts = (countryAdverts + generalAdverts)
            .map {
                return NewSimRadioDTO.Track(
                    data: $0,
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
        trackPath: String?
    ) -> [NewSimRadioDTO.Track] {
        let trackFileName = String(trackPath?.split(separator: "/").last ?? "")
        let names = generateFileList(count: variations, prefix: trackFileName, exension: "")

        return names.map { name in
            let path = [containerPath, name].joined(separator: "/")
            let id = path.replacingOccurrences(of: "/", with: "_")
            return .init(
                id: .init(id),
                path: path,
                duration: -1,
                intro: nil,
                markers: nil,
                trackList: nil
            )
        }
    }
}

extension DumpsDTO.Speech {
    func trackLists(stationId: String) -> [NewSimRadioDTO.TrackList] {
        let generalList = general?.trackLists(
            stationId: stationId,
            prefix: "general"
        )
        let ddGeneralList = ddGeneral?.trackLists(
            stationId: stationId,
            prefix: "dd_general"
        )
        let plGeneralList = plGeneral?.trackLists(
            stationId: stationId,
            prefix: "pl_general"
        )
        let morningList = time?.morning?.trackLists(
            stationId: stationId,
            prefix: "morning"
        )
        let afternoomList = time?.afternoom?.trackLists(
            stationId: stationId,
            prefix: "afternoom"
        )
        let eveningList = time?.evening?.trackLists(
            stationId: stationId,
            prefix: "evening"
        )
        let nightList = time?.night?.trackLists(
            stationId: stationId,
            prefix: "night"
        )
        let newsList = to?.toNews?.trackLists(
            stationId: stationId,
            prefix: "news"
        )
        let adList = to?.toAd?.trackLists(
            stationId: stationId,
            prefix: "ad"
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
        prefix: String
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

                let isSubstringDuplicated = name.prefix(prefix.count) == trackListID.suffix(prefix.count)
                let itemID = trackListID
                    + (isSubstringDuplicated ? "" : "_")
                    + name.dropFirst(isSubstringDuplicated ? prefix.count : 0)
                let itemPath = [path, searchName].joined(separator: "/")

                return .init(
                    id: .init(itemID),
                    path: itemPath,
                    duration: -1,
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
            duration: dataDuration,
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
    init(
        id: String,
        data: DumpsDTO.Station,
        trackLists: [NewSimRadioDTO.TrackList.ID: [NewSimRadioDTO.Track]]
    ) {
        let speechIDs = (
            data.speech
                .map { $0.trackLists(stationId: id) } ?? []
        )
        .map(\.id)
        
        let tracklistIDs: [NewSimRadioDTO.TrackList.ID] = data.trackLists.map { .init(value: $0) }
        let needNews = (data.speech?.to?.toNews?.variations ?? 0) > 1
        let newsTracklist: [NewSimRadioDTO.TrackList.ID] =  needNews
        ? [.init("radio_news")] : []
        
        let introTracklists: [NewSimRadioDTO.TrackList.ID] = tracklistIDs.compactMap { trackListID in
            let hasIntro = (trackLists[trackListID] ?? []).contains { $0.intro?.isEmpty == false }
            return hasIntro ? .init(trackListID.value + "_intro")  : nil
        }

        self.init(
            id: .init(id),
            genre: data.genre,
            trackLists: (tracklistIDs + newsTracklist + introTracklists + speechIDs).sorted { $0.value < $1.value }
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
