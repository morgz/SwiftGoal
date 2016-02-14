//
//  StoreType.swift
//  SwiftGoal
//
//  Created by Martin Richter on 30/12/15.
//  Copyright © 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import RxSwift

struct MatchParameters {
    let homePlayers: [Player]
    let awayPlayers: [Player]
    let homeGoals: Int
    let awayGoals: Int
}

protocol StoreType {
    // Matches
    func fetchMatches() -> SignalProducer<[Match], NSError>
    func createMatch(parameters: MatchParameters) -> Observable<Bool>
    func updateMatch(match: Match, parameters: MatchParameters) -> Observable<Bool>
    func deleteMatch(match: Match) -> SignalProducer<Bool, NSError>

    // Players
    func fetchPlayers() -> SignalProducer<[Player], NSError>
    func createPlayerWithName(name: String) -> SignalProducer<Bool, NSError>

    // Rankings
    func fetchRankings() -> SignalProducer<[Ranking], NSError>
}
