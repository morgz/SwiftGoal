//
//  EditMatchViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 22/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import RxSwift

class EditMatchViewModel {

    // Inputs
    
    // ReactiveCocoa:
    //let homeGoals: MutableProperty<Int>
    let homeGoals = Variable(0)
    let awayGoals = Variable(0)

    // Outputs
    let title: String
    //let formattedHomeGoals = MutableProperty<String>("")
    let formattedHomeGoals = Variable("")
    let formattedAwayGoals = Variable("")
    let homePlayersString = MutableProperty<String>("")
    let awayPlayersString = MutableProperty<String>("")
    let inputIsValid = MutableProperty<Bool>(false)
    
    let disposeBag = DisposeBag()

    // Actions
    lazy var saveAction: Action<Void, Bool, NSError> = { [unowned self] in
        return Action(enabledIf: self.inputIsValid, { _ in
            let parameters = MatchParameters(
                homePlayers: self.homePlayers.value,
                awayPlayers: self.awayPlayers.value,
                homeGoals: self.homeGoals.value,
                awayGoals: self.awayGoals.value
            )
            if let match = self.match {
                return self.store.updateMatch(match, parameters: parameters)
            } else {
                return self.store.createMatch(parameters)
            }
        })
    }()

    private let store: StoreType
    private let match: Match?
    private let homePlayers: MutableProperty<Set<Player>>
    private let awayPlayers: MutableProperty<Set<Player>>

    // MARK: Lifecycle

    init(store: StoreType, match: Match?) {
        self.store = store
        self.match = match

        // Set properties based on whether an existing match was passed
        self.title = (match != nil ? "Edit Match" : "New Match")
        self.homePlayers = MutableProperty(Set<Player>(match?.homePlayers ?? []))
        self.awayPlayers = MutableProperty(Set<Player>(match?.awayPlayers ?? []))
        self.homeGoals.value = match?.homeGoals ?? 0
        
        // ReactiveCocoa:
        //self.awayGoals = MutableProperty(match?.awayGoals ?? 0)
        self.awayGoals.value = match?.awayGoals ?? 0
        
        //When our goals change then update our formatted text
        self.homeGoals.asObservable().subscribeNext { (goals) -> Void in
            self.formattedHomeGoals.value = "\(goals)"
        }.addDisposableTo(self.disposeBag)
        
        // ReactiveCocoa:
        //self.formattedAwayGoals <~ awayGoals.producer.map { goals in return "\(goals)" }
       
        self.awayGoals.asObservable().subscribeNext { (goals) -> Void in
            self.formattedAwayGoals.value = "\(goals)"
        }.addDisposableTo(self.disposeBag)

        self.homePlayersString <~ homePlayers.producer
            .map { players in
                return players.isEmpty ? "Set Home Players" : players.map({ $0.name }).joinWithSeparator(", ")
            }
        self.awayPlayersString <~ awayPlayers.producer
            .map { players in
                return players.isEmpty ? "Set Away Players" : players.map({ $0.name }).joinWithSeparator(", ")
            }
        self.inputIsValid <~ combineLatest(homePlayers.producer, awayPlayers.producer)
            .map { (homePlayers, awayPlayers) in
                return !homePlayers.isEmpty && !awayPlayers.isEmpty
            }
    }

    convenience init(store: StoreType) {
        self.init(store: store, match: nil)
    }

    // MARK: View Models

    func manageHomePlayersViewModel() -> ManagePlayersViewModel {
        let homePlayersViewModel = ManagePlayersViewModel(
            store: store,
            initialPlayers: homePlayers.value,
            disabledPlayers: awayPlayers.value
        )
        self.homePlayers <~ homePlayersViewModel.selectedPlayers

        return homePlayersViewModel
    }

    func manageAwayPlayersViewModel() -> ManagePlayersViewModel {
        let awayPlayersViewModel = ManagePlayersViewModel(
            store: store,
            initialPlayers: awayPlayers.value,
            disabledPlayers: homePlayers.value
        )
        self.awayPlayers <~ awayPlayersViewModel.selectedPlayers

        return awayPlayersViewModel
    }
}
