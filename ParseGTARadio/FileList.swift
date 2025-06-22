//
//  FileList.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 08.06.2025.
//

import Foundation

struct StationFileList {
    let radioName: String
    let fileList: [FileList]
}

struct FileList {
    let speech: Bool
    let id: String
    let basePath: String
    let files: [String]
}

extension [FileList] {
    var stringRepresentation: String {
        map(\.stringRepresentation)
            .joined(separator: "\n# -----------------\n")
    }

    var paths: [String] {
        flatMap(\.paths)
    }
}

extension FileList {
    var paths: [String] {
        let paths: [String] = files.map {
            basePath + "/"
                + $0.components(separatedBy: "/").dropLast().joined(separator: "/")
        }

        return Array(Set(paths)).sorted()
    }

    var stringRepresentation: String {
        let name = "id: \(id)"
        let basePath = "basePath: \(basePath)"
        let files = "files: \(files.joined(separator: ", "))"

        let result = [name, basePath, files]
            .compactMap(\.self)
            .joined(separator: "\n")

        return result
    }
}

extension DumpsDTO.TrackList {
    func fileList(trackListID: String) -> FileList {
//        let noPath = tracks.filter { $0.path == nil }
//        if noPath.isEmpty == false {
//            print("tracklist without path", noPath)
//        }
        let files: [String] = tracks.compactMap {
            guard let path = $0.path else {
                print("❌ Track path is nil", $0.id, $0.trackList!)
                return nil
            }
            return filePath(path: path)
        }

        if dlcPath == nil {
            print("❌ dlcPath is nil")
        }

        return FileList(
            speech: false,
            id: trackListID.uppercased(),
            basePath: dlcPath ?? "",
            files: files
        )
    }
    
    func introList(trackListID: String) -> [FileList] {
        struct FileIntro {
            let path: String
            let intro: DumpsDTO.TrackIntro
        }

        let introFiles: [
            FileIntro
        ] = tracks.compactMap {
            guard
                let path = $0.path,
                let intro = $0.intro,
                let name = path.split(separator: "/").last
            else {
                return nil
            }
            return FileIntro(path: String(name), intro: intro)
        }

        var intros: [String: [String]] = [:]
        for introFile in introFiles {
            let key = introFile.intro.containerPath
            intros[key] = (intros[key] ?? []) + generateFileList(
                count: introFile.intro.variations,
                prefix: introFile.path.uppercased()
            )
        }

        let result = intros.map { key, value in
            if dlcPath == nil {
                print("❌ dlcPath is nil")
            }

            return FileList(
                speech: false,
                id: [trackListID, "INTRO"].joined(separator: "_").uppercased(),
                basePath: dlcPath ?? "",
                files: value.map { [key, $0].joined(separator: "/") }
            )
        }
        return result
    }
}

func filePath(path: String) -> String {
    let pathComonents = path.split(separator: "/")
    if pathComonents.count < 2 {
        print("❌ short path", path)
    }
    guard let last = pathComonents.last else {
        print("❌ short path", path)
        return path
    }

    let name = last.uppercased() + ".wav"

    return (pathComonents.map { String($0) } + [name]).joined(separator: "/")
}

func generateFileList(count: Int, prefix: String, exension: String = ".wav") -> [String] {
    (1 ... count).map {
        String(format: "%@_%02d%@", prefix, $0, exension)
    }
}

extension DumpsDTO.Speech {
    var fileLists: [FileList] {
        let generalList = general.map {
            FileList(
                speech: true,
                id: CodingKeys.general.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.general.rawValue)
            )
        }

        let ddGeneral = ddGeneral.map {
            FileList(
                speech: true,
                id: CodingKeys.ddGeneral.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.ddGeneral.rawValue)
            )
        }

        let plGeneral = plGeneral.map {
            FileList(
                speech: true,
                id: CodingKeys.plGeneral.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.plGeneral.rawValue)
            )
        }

        let general = [generalList, ddGeneral, plGeneral].compactMap(\.self)

        return general + (time?.fileLists ?? []) + (to?.fileLists ?? [])
    }
}

extension DumpsDTO.TimeCategory {
    var fileLists: [FileList] {
        let morning = morning.map {
            FileList(
                speech: true,
                id: CodingKeys.morning.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.morning.rawValue)
            )
        }

        let afternoom = afternoom.map {
            FileList(
                speech: true,
                id: CodingKeys.afternoom.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.afternoom.rawValue)
            )
        }

        let evening = evening.map {
            FileList(
                speech: true,
                id: CodingKeys.evening.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.evening.rawValue)
            )
        }

        let night = night.map {
            FileList(
                speech: true,
                id: CodingKeys.night.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.night.rawValue)
            )
        }

        return [morning, afternoom, evening, night].compactMap(\.self)
    }
}

extension DumpsDTO.ToCategory {
    var fileLists: [FileList] {
        let toAd = toAd.map {
            FileList(
                speech: true,
                id: CodingKeys.toAd.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.toAd.rawValue)
            )
        }

        let toNews = toNews.map {
            FileList(
                speech: true,
                id: CodingKeys.toNews.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.toNews.rawValue)
            )
        }

        let toWeather = toWeather.map {
            FileList(
                speech: true,
                id: CodingKeys.toWeather.rawValue,
                basePath: $0.containerPath,
                files: generateFileList(count: $0.variations, prefix: CodingKeys.toWeather.rawValue)
            )
        }
        return [toAd, toNews, toWeather].compactMap(\.self)
    }
}

extension DumpsDTO.RadioData {
    func fileList(radioID: String) -> StationFileList? {
        guard let station = stations[radioID] else { return nil }
        let speechFileLists = station.speech?.fileLists ?? []

        let trackFileLists: [FileList] = station.trackLists.compactMap { trackListID in
            guard let trackList = trackLists[trackListID] else {
                print("no trackList for \(trackListID) in radio \(radioID)")
                return nil
            }
            if trackListID.hasPrefix("hash_") {
                print("trackListID \(trackListID) in radio \(radioID)")
            }
            return trackList.fileList(trackListID: trackListID)
        }

        let introLists: [[FileList]] = station.trackLists.compactMap { trackListID in
            guard let trackList = trackLists[trackListID] else {
                return nil
            }
            return trackList.introList(trackListID: trackListID)
        }

        return StationFileList(
            radioName: station.radioName,
            fileList: speechFileLists + trackFileLists + introLists.flatMap(\.self)
        )
    }
}
