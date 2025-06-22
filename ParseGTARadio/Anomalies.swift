//
//  Anomalies.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 18.06.2025.
//

func detectAnomalies(_ data: NewSimRadioDTO.RadioData, printInfo: Bool = false) {
    let groupByTarckList = data.trackLists.duplicateTracksGroupByTarckList
    let groupByTarckListDescription = groupByTarckList.map { trackListID, files in
        let fileList = Set(files)
            .map { "  id: \($0.id.value), path: \($0.path ?? "---")" }
            .sorted()
            .joined(separator: "\n")

        return "\(trackListID.value): [\n\(fileList)\n]"
    }

    let duplicateTracks = data.trackLists.duplicateTracks
    for (trackListID, files) in duplicateTracks {
        let markers = Set(files.compactMap(\.markers))
        if markers.count > 1 {
            print("❌ Error: Found multiple marker variants (\(markers)) for file(s) in tracklist \(trackListID.value)")
        }
    }

    if printInfo {
        print(
            "ℹ️ Files with repeating path grouped by tracklist:\n",
            groupByTarckListDescription.joined(separator: "\n")
        )
    }

    let updatedTrackLists = extractCommonTrackLists(trackLists: data.trackLists)

    if updatedTrackLists.duplicateTracks.count != 0 {
        print("❌ Error: failed to remove duplicate tracklists")
    }
}

struct NewSimTrack: Hashable {
    let id: NewSimRadioDTO.Track.ID
    let path: String?
}

func extractCommonTrackLists(
    trackLists: [NewSimRadioDTO.TrackList]
) -> [NewSimRadioDTO.TrackList] {
    let groupByTarckList = trackLists.duplicateTracksGroupByTarckList
    let commonPaths = trackLists.commonPathsForDuplicates

    let commonTracks = trackLists.commonTracks
    var result = trackLists

    let commonTrackLists: [NewSimRadioDTO.TrackList] = commonPaths.map { commonPath in
        let tracks = Array(commonTracks.values).filter { $0.path?.hasPrefix(commonPath) == true }
        return .init(
            id: .init([commonPath, "common"].joined(separator: "_")),
            tracks: tracks
        )
    }

    for (trackListID, _) in groupByTarckList {
        guard let trackListIndex = trackLists.firstIndex(where: { $0.id == trackListID }) else {
            print("❌ ERROR: No track list with ID \(trackListID)")
            continue
        }
        let trackList = trackLists[trackListIndex]
        var updatedTrackList: [NewSimRadioDTO.Track] = []
        for track in trackList.tracks {
            if commonTracks.keys.contains(track.id), let path = track.path {
                let trackListID: String = [path.split(separator: "/").first, "common"]
                    .compactMap(\.self)
                    .joined(separator: "_")
                let validTrackListID = commonTrackLists.contains { trackListID == $0.id.value }
                if !validTrackListID {
                    print("❌ ERROR: No common track list found for track \(track.id) in path \(path)")
                }
                updatedTrackList.append(
                    .init(
                        id: track.id,
                        path: nil,
                        duration: nil,
                        intro: track.intro,
                        markers: nil,
                        trackList: .init(trackListID)
                    )
                )
            } else {
                updatedTrackList.append(track)
            }
        }

        result[trackListIndex] = .init(id: trackList.id, tracks: updatedTrackList)
    }

    return result + commonTrackLists
}

extension [NewSimRadioDTO.TrackList] {
    var commonPathsForDuplicates: [String] {
        let paths = duplicateTracksGroupByTarckList.flatMap { id, files in
            files.map {
                let containerPath = $0.path?.split(separator: "/").first
                if containerPath == nil {
                    print("❌ ERROR: No path in \(id.value)")
                }
                if let containerPath {
                    return String(containerPath)
                } else {
                    return ""
                }
            }
        }
        return Set(paths).map(\.self)
    }

    var duplicateTrackIDs: [NewSimRadioDTO.Track.ID] {
        var allTracks: [NewSimRadioDTO.Track.ID: [NewSimRadioDTO.Track]] = [:]

        for trackList in self {
            for track in trackList.tracks {
                allTracks[track.id, default: []].append(track)
            }
        }

        let repeats = Set(allTracks
            .filter { $0.value.compactMap(\.path).count > 1 }
            .map(\.key))
        return repeats.map(\.self)
    }

    var duplicateTracks: [NewSimRadioDTO.Track.ID: [NewSimRadioDTO.Track]] {
        let repeats = Set(duplicateTrackIDs)
        var result: [NewSimRadioDTO.Track.ID: [NewSimRadioDTO.Track]] = [:]
        for trackList in self {
            for track in trackList.tracks where repeats.contains(track.id) {
                result[track.id, default: []].append(track)
            }
        }
        return result
    }

    var commonTracks: [NewSimRadioDTO.Track.ID: NewSimRadioDTO.Track] {
        var result: [NewSimRadioDTO.Track.ID: NewSimRadioDTO.Track] = [:]
        for (trackID, tracks) in duplicateTracks {
            let track = tracks.first { $0.path != nil }
            guard let track, track.trackList == nil else {
                print("❌ ERROR: No path for track \(trackID)")
                continue
            }
            result[trackID] = .init(
                id: track.id,
                path: track.path,
                duration: track.duration,
                intro: nil,
                markers: track.markers,
                trackList: nil
            )
        }
        return result
    }

    var duplicateTracksGroupByTarckList: [(NewSimRadioDTO.TrackList.ID, [NewSimTrack])] {
        let repeats = Set(duplicateTrackIDs)

        let groupByTarckList = map { trackList in
            (
                trackList.id,
                trackList
                    .tracks
                    .filter { repeats.contains($0.id) && $0.path != nil }
                    .map { NewSimTrack(id: $0.id, path: $0.path) }
            )
        }.filter { $0.1.isEmpty == false }

        return groupByTarckList
    }
}
