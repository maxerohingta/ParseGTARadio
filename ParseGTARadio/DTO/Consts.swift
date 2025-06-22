//
//  Consts.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 07.06.2025.
//

import Foundation

let radioNames: [String: String] = [
    "radio_36_audioplayer": "Media Player",
    "radio_37_motomami": "MOTOMAMI Los Santos",
    "radio_35_dlc_hei4_mlr": "The Music Locker",
    "radio_12_reggae": "Blue Ark",
    "radio_13_jazz": "Worldwide FM",
    "radio_14_dance_02": "FlyLo FM",
    "radio_15_motown": "The Lowdown 91.1",
    "radio_20_thelab": "The Lab",
    "radio_16_silverlake": "Radio Mirror Park",
    "radio_34_dlc_hei4_kult": "Kult FM",
    "radio_17_funk": "Space 103.2",
    "radio_18_90s_rock": "Vinewood Boulevard Radio",
    "radio_21_dlc_xm17": "Blonded Los Santos 97.8 FM",
    "radio_22_dlc_battle_mix1_radio": "Los Santos Underground Radio",
    "radio_23_dlc_xm19_radio": "iFruit Radio",
    "radio_01_class_rock": "Los Santos Rock Radio",
    "radio_02_pop": "Non-Stop-Pop FM",
    "radio_03_hiphop_new": "Radio Los Santos",
    "radio_04_punk": "Channel X",
    "radio_05_talk_01": "West Coast Talk Radio",
    "radio_06_country": "Rebel Radio",
    "radio_07_dance_01": "Soulwax FM",
    "radio_08_mexican": "East Los FM",
    "radio_09_hiphop_old": "West Coast Classics",
    "radio_11_talk_02": "Blaine County Radio",
    "radio_27_dlc_prhei4": "Still Slipping Los Santos",
    "radio_19_user": "Self Radio",
    "hidden_radio_mpsum2_news": "Weazel News"
]

func printMissingStations(simRadio: OldSimRadioDTO.GameSeries, dumps: DumpsDTO.RadioData) {
    let simRadioSations = Set(simRadio.stations.map(\.tag))
    let dumpSations = Set(dumps.stations.keys)
    let diff = dumpSations.subtracting(simRadioSations)
    let missingStations = diff.map { "\($0) - (\(radioNames[$0] ?? "--- unknown ---"))" }
    print("missingStations:")
    print(missingStations.joined(separator: "\n"))
}
