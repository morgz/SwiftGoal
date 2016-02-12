//
//  ManagePlayersViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 30/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import RxSwift
import RxCocoa

class ManagePlayersViewModel {

    typealias PlayerChangeset = Changeset<Player>

    // Inputs
    let active = MutableProperty(false)
    let playerName = MutableProperty("")
    let refreshObserver: Observer<Void, NoError>

    // Outputs
    let title: String
    let contentChangesSignal: Signal<PlayerChangeset, NoError>
    let isLoading: MutableProperty<Bool>
    let alertMessageSignal: Signal<String, NoError>
    let selectedPlayers = Variable([Player]())
    let inputIsValid = MutableProperty(false)

    // Actions
    lazy var saveAction: Action<Void, Bool, NSError> = { [unowned self] in
        return Action(enabledIf: self.inputIsValid, { _ in
            return self.store.createPlayerWithName(self.playerName.value)
        })
    }()

    private let store: StoreType
    private let contentChangesObserver: Observer<PlayerChangeset, NoError>
    private let alertMessageObserver: Observer<String, NoError>
    private let disabledPlayers = Variable([Player]())

    private var players: [Player]

    // MARK: Lifecycle

    init(store: StoreType, initialPlayers: [Player], disabledPlayers: [Player]) {
        self.title = "Players"
        self.store = store
        self.players = []
        self.selectedPlayers.value = initialPlayers
        self.disabledPlayers.value = disabledPlayers

        let (refreshSignal, refreshObserver) = SignalProducer<Void, NoError>.buffer()
        self.refreshObserver = refreshObserver

        let (contentChangesSignal, contentChangesObserver) = Signal<PlayerChangeset, NoError>.pipe()
        self.contentChangesSignal = contentChangesSignal
        self.contentChangesObserver = contentChangesObserver

        let isLoading = MutableProperty(false)
        self.isLoading = isLoading

        let (alertMessageSignal, alertMessageObserver) = Signal<String, NoError>.pipe()
        self.alertMessageSignal = alertMessageSignal
        self.alertMessageObserver = alertMessageObserver

        active.producer
            .filter { $0 }
            .map { _ in () }
            .start(refreshObserver)

        saveAction.values
            .filter { $0 }
            .map { _ in () }
            .observe(refreshObserver)

        refreshSignal
            .on(next: { _ in isLoading.value = true })
            .flatMap(.Latest, transform: { _ in
                return store.fetchPlayers()
                    .flatMapError { error in
                        alertMessageObserver.sendNext(error.localizedDescription)
                        return SignalProducer(value: [])
                    }
            })
            .on(next: { _ in isLoading.value = false })
            .combinePrevious([]) // Preserve history to calculate changeset
            .startWithNext({ [weak self] (oldPlayers, newPlayers) in
                self?.players = newPlayers
                if let observer = self?.contentChangesObserver {
                    let changeset = Changeset(
                        oldItems: oldPlayers,
                        newItems: newPlayers,
                        contentMatches: Player.contentMatches
                    )
                    observer.sendNext(changeset)
                }
            })

        // Feed saving errors into alert message signal
        saveAction.errors
            .map { $0.localizedDescription }
            .observe(alertMessageObserver)

        inputIsValid <~ playerName.producer.map { $0.characters.count > 0 }
    }

    // MARK: Data Source

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfPlayersInSection(section: Int) -> Int {
        return players.count
    }

    func playerNameAtIndexPath(indexPath: NSIndexPath) -> String {
        return playerAtIndexPath(indexPath).name
    }

    func isPlayerSelectedAtIndexPath(indexPath: NSIndexPath) -> Bool {
        let player = playerAtIndexPath(indexPath)
        return selectedPlayers.value.contains(player)
    }

    func canSelectPlayerAtIndexPath(indexPath: NSIndexPath) -> Bool {
        let player = playerAtIndexPath(indexPath)
        return !disabledPlayers.value.contains(player)
    }

    // MARK: Player Selection

    func selectPlayerAtIndexPath(indexPath: NSIndexPath) {
        let player = playerAtIndexPath(indexPath)
        selectedPlayers.value.append(player)
    }

    func deselectPlayerAtIndexPath(indexPath: NSIndexPath) {
        let player = playerAtIndexPath(indexPath)
        selectedPlayers.value.append(player)
    }

    // MARK: Internal Helpers

    private func playerAtIndexPath(indexPath: NSIndexPath) -> Player {
        return players[indexPath.row]
    }
}