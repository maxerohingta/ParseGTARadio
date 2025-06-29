//
//  ParseViewModel.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 06.06.2025.
//

import Foundation
import Observation

@Observable
final class ParseViewModel {
    func onAppear() {
        Task {
            await loadAndParseLocalJSON()
        }
    }

    func fetchDumps() async throws -> DumpsDTO.RadioData {
//        let src = "https://raw.githubusercontent.com/HintSystem/GTA-V-Radio-Dumps/main/info_merged.json"
//        guard let url = URL(string: src) else {
//            throw URLError(.badURL)
//        }
//        let (data, response) = try await URLSession.shared.data(from: url)
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200
//        else {
//            throw URLError(.badServerResponse)
//        }
        guard let url = Bundle.main.url(forResource: "info_merged", withExtension: "json") else {
            throw URLError(.badURL)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DumpsDTO.RadioData.self, from: data)
    }

    func fetchSimRadio() async throws -> OldSimRadioDTO.GameSeries {
        guard let url = Bundle.main.url(forResource: "sim_radio_stations", withExtension: "json") else {
            throw URLError(.badURL)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(OldSimRadioDTO.GameSeries.self, from: data)
    }

    func convert(
        dumps: DumpsDTO.RadioData,
        oldSimRadio: OldSimRadioDTO.GameSeries
    ) -> NewSimRadioDTO.RadioData {
        let adverts = dumps.advertsTrackLists()
        let news = dumps.newsTrackLists()
        let stationsTrackLists = dumps.stationsTrackLists()
        let stationsSpeechTrackLists = dumps.stationsSpeechTrackLists()
        let stations = (stationsTrackLists + stationsSpeechTrackLists).sorted { $0.id.value < $1.id.value }
        
        let trackLists: [NewSimRadioDTO.TrackList.ID :[NewSimRadioDTO.Track]] = Dictionary(
            uniqueKeysWithValues: stations.map{ ($0.id, $0.tracks) }
        )
        return .init(
            trackLists: adverts + news + stations,
            stations: dumps.stations
                .map { .init(id: $0.key, data: $0.value, trackLists: trackLists, oldSimRadio: oldSimRadio) }
                .sorted { $0.id.value < $1.id.value }
        )
    }

    func grupped(paths: [String]) -> [String: [String]] {
        var result: [String: [String]] = [:]

        for path in paths {
            let base = path.components(separatedBy: "/").dropLast().joined(separator: "/")
            let lastPathComponent = path.components(separatedBy: "/").last

            if result[base] == nil {
                result[base] = lastPathComponent != nil ? [lastPathComponent!] : []
            } else {
                if let lastPathComponent {
                    result[base]?.append(lastPathComponent)
                }
            }
        }
        return result
    }

    func loadAndParseLocalJSON() async {
        do {
            let dumps = try await fetchDumps()
            let simRadio = try await fetchSimRadio()

            printFileLists(dumps: dumps)

            let newSimRadioDTO = convert(dumps: dumps, oldSimRadio: simRadio)
            detectAnomalies(newSimRadioDTO)
            let updatedTrackLists = extractCommonTrackLists(trackLists: newSimRadioDTO.trackLists)
            let updatedNewSimRadioDTO = NewSimRadioDTO.RadioData(
                trackLists: updatedTrackLists, stations: newSimRadioDTO.stations
            )
            saveJSON(simRadio: updatedNewSimRadioDTO, name: "new_sim_radio_stations.json")

        } catch {
            print("❌ Ошибка декодирования JSON: \(error)")
            return
        }
    }

    func saveJSON(simRadio: NewSimRadioDTO.RadioData, name: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        do {
            let jsonData = try encoder.encode(simRadio)
            let dstDir = URL.documentsDirectory
            try jsonData.write(to: dstDir.appendingPathComponent(name), options: .atomic)
            print("ℹ️ JSON successfully saved to: \(dstDir.path)")

        } catch {
            print("Error encoding or writing JSON: \(error)")
        }
    }

    func printFileLists(dumps: DumpsDTO.RadioData) {
        let radioIDs = dumps.stations.keys.sorted()
        var allPacks = Set<String>()
        for radioID in radioIDs {
            print("\n# ==[ 📻 \(radioNames[radioID] ?? radioID) ]======================")
            guard let fileList = dumps.fileList(radioID: radioID) else {
                print("❌ нет станции: \(radioID)")
                continue
            }
//            print(fileList.fileList.stringRepresentation)
//            print(fileList.fileList.paths.joined(separator: "\n"))
            let grupped = grupped(paths: fileList.fileList.paths)
            allPacks = allPacks.union(grupped.keys)
            print(
                grupped
                    .map { "\($0.key): [\($0.value.joined(separator: ", "))]" }
                    .joined(separator: "\n")
            )
        }
//        print(Array(allPacks).sorted().joined(separator: "\n"))
    }
}

extension Dictionary {
    static func + (lhs: Dictionary, rhs: Dictionary) -> Dictionary {
        lhs.merging(rhs) { _, new in new }
    }
}
