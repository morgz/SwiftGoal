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
    let homePlayersString = Variable("")
    let awayPlayersString = Variable("")
    let inputIsValid = Variable(false)
    
    let disposeBag = DisposeBag()

    // Actions
    lazy var saveAction: Action<Void, Bool, NSError> = { [unowned self] in
        //return Action(enabledIf: self.inputIsValid, { _ in
        return Action({ _ in
            /*
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
            */
            return SignalProducer.empty
        })
    }()

    private let store: StoreType
    private let match: Match?
    // ReactiveCocoa:
    //private let homePlayers: MutableProperty<Set<Player>>
    private let homePlayers = Variable([Player]())
    private let awayPlayers = Variable([Player]())

    // MARK: Lifecycle

    init(store: StoreType, match: Match?) {
        self.store = store
        self.match = match

        // Set properties based on whether an existing match was passed
        self.title = (match != nil ? "Edit Match" : "New Match")
        
        // ReactiveCocoa:
        // self.homePlayers = MutableProperty(Set<Player>(match?.homePlayers ?? []))
        self.homePlayers.value = match?.homePlayers ?? []
        self.awayPlayers.value = match?.awayPlayers ?? []

        self.homeGoals.value = match?.homeGoals ?? 0
        
        // ReactiveCocoa:
        //self.awayGoals = MutableProperty(match?.awayGoals ?? 0)
        self.awayGoals.value = match?.awayGoals ?? 0
        
        //When our goals change then update our formatted text
        self.homeGoals.asObservable().subscribeNext { [unowned self] (goals) -> Void in
            self.formattedHomeGoals.value = "\(goals)"
        }.addDisposableTo(disposeBag)
        
        // ReactiveCocoa:
        //self.formattedAwayGoals <~ awayGoals.producer.map { goals in return "\(goals)" }
       
        self.awayGoals.asObservable().subscribeNext { [unowned self] (goals) -> Void in
            self.formattedAwayGoals.value = "\(goals)"
        }.addDisposableTo(disposeBag)
        
        // ReactiveCocoa:
//        self.homePlayersString <~ homePlayers.producer
//            .map { players in
//                return players.isEmpty ? "Set Home Players" : players.map({ $0.name }).joinWithSeparator(", ")
//            }
        self.homePlayers
            .asObservable()
            .map { (players) -> String in
                return players.isEmpty ? "Set Home Players" : players.map({ $0.name }).joinWithSeparator(", ")
            }
            .bindTo(homePlayersString)
            .addDisposableTo(disposeBag)
        
        self.awayPlayers
            .asObservable()
            .map { (players) -> String in
                return players.isEmpty ? "Set Away Players" : players.map({$0.name}).joinWithSeparator(", ")
            }
            .bindTo(awayPlayersString)
            .addDisposableTo(disposeBag)
        
        
//        Observable.combineLatest(homePlayers.asObservable(), awayPlayers.asObservable()) { $0.count > 0 && $1.count > 0 }
//           .shareReplay(1).bindTo(self.inputIsValid).addDisposableTo(disposeBag)
     
        Observable.combineLatest(homePlayers.asObservable(), awayPlayers.asObservable()) { $0.count > 0 && $1.count > 0 }
            .bindTo(self.inputIsValid).addDisposableTo(disposeBag)
        
        /*
        self.inputIsValid <~ combineLatest(homePlayers.producer, awayPlayers.producer)
            .map { (homePlayers, awayPlayers) in
                return !homePlayers.isEmpty && !awayPlayers.isEmpty
            }
        */
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
        // ReactiveCocoa:
//        self.homePlayers <~ homePlayersViewModel.selectedPlayers
        
        homePlayersViewModel
            .selectedPlayers
            .asObservable()
            .bindTo(homePlayers)
            .addDisposableTo(disposeBag)

        return homePlayersViewModel
    }

    func manageAwayPlayersViewModel() -> ManagePlayersViewModel {
        let awayPlayersViewModel = ManagePlayersViewModel(
            store: store,
            initialPlayers: awayPlayers.value,
            disabledPlayers: homePlayers.value
        )
        
        awayPlayersViewModel
            .selectedPlayers
            .asObservable()
            .bindTo(awayPlayers)
            .addDisposableTo(disposeBag)

        return awayPlayersViewModel
    }
}
